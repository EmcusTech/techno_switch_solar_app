import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';

/// Scan snapshot (ADV data is scan-time only!)
class ScannedBleDevice {
  final BluetoothDevice device;
  final AdvertisementData advData;
  final int rssi;

  ScannedBleDevice({
    required this.device,
    required this.advData,
    required this.rssi,
  });
}

class BluetoothService {
  final FlutterBluePlus _ble = FlutterBluePlus();
  final BleManager bleManager = Get.find<BleManager>();

  /* -------------------------------------------------------------------------- */
  /*                                   STATE                                    */
  /* -------------------------------------------------------------------------- */

  final Map<DeviceIdentifier, ScannedBleDevice> _scanResults = {};
  final StreamController<List<ScannedBleDevice>> _resultsController =
      StreamController.broadcast();

  Stream<List<ScannedBleDevice>> get scanResultsStream =>
      _resultsController.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _writeChar;

  bool get isConnected => _connectedDevice != null;

  /* -------------------------------------------------------------------------- */
  /*                                PERMISSIONS                                 */
  /* -------------------------------------------------------------------------- */

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  /* -------------------------------------------------------------------------- */
  /*                               BLUETOOTH STATE                               */
  /* -------------------------------------------------------------------------- */

  Future<bool> ensurePoweredOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    print("Bluetooth adapter state: $state");
    return state == BluetoothAdapterState.on;
  }

  /* -------------------------------------------------------------------------- */
  /*                                    SCAN                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> startScanning() async {
    print("Starting BLE scan");

    if (isConnected) {
      await disconnect();
      await Future.delayed(const Duration(milliseconds: 800));
    }

    _scanResults.clear();
    _resultsController.add([]);

    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final device = result.device;

        // Manual service filtering (reliable)
        final advertisedServices = result.advertisementData.serviceUuids.map(
          (e) => e.toString().toUpperCase(),
        );

        if (!advertisedServices.contains(
          BleUuids.primaryService.toString().toUpperCase(),
        )) {
          continue;
        }

        if (_scanResults.containsKey(device.remoteId)) continue;

        _scanResults[device.remoteId] = ScannedBleDevice(
          device: device,
          advData: result.advertisementData,
          rssi: result.rssi,
        );

        _resultsController.add(_scanResults.values.toList());

        // Cache manufacturer data for later use
        final mfg = result.advertisementData.manufacturerData;
        if (mfg.isNotEmpty) {
          final entry = mfg.entries.first;
          print(
            "ADV MFG → Company: 0x${entry.key.toRadixString(16)}, Data: ${entry.value}",
          );
        }
      }
    }, onError: (e) => print("Scan error: $e"));

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  Future<void> stopScanning() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();
  }

  /* -------------------------------------------------------------------------- */
  /*                                  CONNECT                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> connect(
    ScannedBleDevice scanned, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await disconnect();

    final device = scanned.device;
    _connectedDevice = device;

    print("Connecting to ${device.remoteId}");

    await device.connect(autoConnect: false, timeout: timeout);

    _connSub = device.connectionState.listen((state) async {
      print("Connection state: $state");

      if (state == BluetoothConnectionState.connected) {
        await device.requestMtu(247);
        await _discoverCharacteristics(device);
      }

      if (state == BluetoothConnectionState.disconnected) {
        await disconnect();
      }
    });
  }

  Future<void> _discoverCharacteristics(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toUpperCase() ==
          BleUuids.primaryService.toString().toUpperCase()) {
        for (final c in service.characteristics) {
          if (c.uuid == BleUuids.primaryReadChar) {
            _notifyChar = c;
          }
          if (c.uuid == BleUuids.primaryWriteChar) {
            _writeChar = c;
          }
        }
      }
    }

    if (_notifyChar == null || _writeChar == null) {
      throw Exception("Required characteristics not found");
    }

    await _registerNotify();
  }

  /* -------------------------------------------------------------------------- */
  /*                                   NOTIFY                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> _registerNotify() async {
    if (_notifyChar == null) return;

    await _notifySub?.cancel();

    await _notifyChar!.setNotifyValue(true);

    _notifySub = _notifyChar!.value.listen((data) async {
      await bleManager.notificationHandler(Uint8List.fromList(data));
    }, onError: (e) => print("Notify error: $e"));

    print("Notify handler registered");
  }

  /* -------------------------------------------------------------------------- */
  /*                                    WRITE                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> write(List<int> data, {bool withoutResponse = false}) async {
    if (_writeChar == null) return;

    await _writeChar!.write(data, withoutResponse: withoutResponse);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 DISCONNECT                                 */
  /* -------------------------------------------------------------------------- */

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
    }

    _notifySub = null;
    _connSub = null;
    _connectedDevice = null;
    _notifyChar = null;
    _writeChar = null;

    print("BLE disconnected");
  }

  /* -------------------------------------------------------------------------- */
  /*                                   CLEANUP                                  */
  /* -------------------------------------------------------------------------- */

  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    _resultsController.close();
  }
}
