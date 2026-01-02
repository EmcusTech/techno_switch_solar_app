import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';

class BluetoothService {
  /// flutter_reactive_ble instance
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  /// Scan handling
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final List<DiscoveredDevice> _scanResults = [];
  final StreamController<List<DiscoveredDevice>> _resultsController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  /// Connection handling
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  DiscoveredDevice? _connectedDevice;

  /// Characteristics
  QualifiedCharacteristic? _readCharacteristic;
  QualifiedCharacteristic? _writeCharacteristic;

  /// Public scan stream
  Stream<List<DiscoveredDevice>> get scanResultsStream =>
      _resultsController.stream;

  final BleManager ble = Get.find<BleManager>();

  /* -------------------------------------------------------------------------- */
  /*                               PERMISSIONS                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.location.request();
  }

  /* -------------------------------------------------------------------------- */
  /*                         BLUETOOTH STATE (IMPORTANT)                         */
  /* -------------------------------------------------------------------------- */

  /// flutter_reactive_ble CANNOT turn Bluetooth ON/OFF
  /// This only checks whether Bluetooth is usable
  Future<bool> ensurePoweredOn() async {
    final status = await _ble.statusStream.first;
    return status == BleStatus.ready;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   SCAN                                     */
  /* -------------------------------------------------------------------------- */

  Future<void> startScanning() async {
    print("The scanning initial status is: ${ble.isConnected}");
    if (ble.isConnected) {
      ble.shutdown();
    }

    await Future.delayed(const Duration(seconds: 2));
    // Clear stale devices
    _scanResults.clear();

    await _scanSub?.cancel();

    _scanSub = _ble
        .scanForDevices(
          withServices: [BleUuids.primaryService],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            final exists = _scanResults.any((d) => d.id == device.id);

            if (!exists) {
              _scanResults.add(device);
              _resultsController.add(List.unmodifiable(_scanResults));
            }
          },
          onError: (e) {
            // Scan errors are non-fatal but should be logged
            print('Scan error: $e');
          },
        );
  }

  Future<void> stopScanning() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 CONNECT                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> connect(
    DiscoveredDevice device, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Defensive cleanup
    await disconnect();

    final connectionStream = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 8),
    );

    final Completer<void> connectedCompleter = Completer();
    _connectedDevice = device;

    // _connectionSub = _ble
    //     .connectToDevice(id: device.id, connectionTimeout: timeout)
    //     .listen(
    //       (update) async {
    //         switch (update.connectionState) {
    //           case DeviceConnectionState.connected:
    //             await _prepareCharacteristics(device);
    //             completer.complete(true);
    //             break;

    //           case DeviceConnectionState.disconnected:
    //             if (!completer.isCompleted) {
    //               completer.complete(false);
    //             }
    //             await disconnect();
    //             break;

    //           case DeviceConnectionState.connecting:
    //             // no-op
    //             break;
    //           default:
    //             break;
    //         }
    //       },
    //       onError: (e) {
    //         if (!completer.isCompleted) {
    //           completer.complete(false);
    //         }
    //       },
    //     );

    connectionStream.listen((update) {
      print("Connection state: ${update.connectionState}");

      if (update.connectionState == DeviceConnectionState.connected) {
        print("Connected!");

        _readCharacteristic = QualifiedCharacteristic(
          serviceId: BleUuids.primaryService,
          characteristicId: BleUuids.primaryReadChar,
          deviceId: device.id,
        );

        _writeCharacteristic = QualifiedCharacteristic(
          serviceId: BleUuids.primaryService,
          characteristicId: BleUuids.primaryWriteChar,
          deviceId: device.id,
        );

        connectedCompleter.complete();
      }

      if (update.connectionState == DeviceConnectionState.disconnected) {
        print("Disconnected.");
      }
    });
    await _ble.requestMtu(
      deviceId: device.id,
      mtu: 247, // safe value
    );
    await Future.delayed(const Duration(milliseconds: 200));
    await connectedCompleter.future;
  }

  /* -------------------------------------------------------------------------- */
  /*                          CHARACTERISTIC SETUP                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _prepareCharacteristics(DiscoveredDevice device) async {
    _readCharacteristic = QualifiedCharacteristic(
      serviceId: BleUuids.primaryService,
      characteristicId: BleUuids.primaryReadChar,
      deviceId: device.id,
    );

    _writeCharacteristic = QualifiedCharacteristic(
      serviceId: BleUuids.primaryService,
      characteristicId: BleUuids.primaryWriteChar,
      deviceId: device.id,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                NOTIFY                                      */
  /* -------------------------------------------------------------------------- */

  Stream<List<int>>? get notifyStream {
    if (_readCharacteristic == null) return null;

    return _ble.subscribeToCharacteristic(_readCharacteristic!);
  }

  /* -------------------------------------------------------------------------- */
  /*                                  WRITE                                     */
  /* -------------------------------------------------------------------------- */

  Future<void> write(List<int> data, {bool withoutResponse = true}) async {
    if (_writeCharacteristic == null) return;

    if (withoutResponse) {
      await _ble.writeCharacteristicWithoutResponse(
        _writeCharacteristic!,
        value: data,
      );
    } else {
      await _ble.writeCharacteristicWithResponse(
        _writeCharacteristic!,
        value: data,
      );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                DISCONNECT                                  */
  /* -------------------------------------------------------------------------- */

  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    _connectionSub = null;

    _connectedDevice = null;
    _readCharacteristic = null;
    _writeCharacteristic = null;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  CLEANUP                                   */
  /* -------------------------------------------------------------------------- */

  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _resultsController.close();
  }
}
