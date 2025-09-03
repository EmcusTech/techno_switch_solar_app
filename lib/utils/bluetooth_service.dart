import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';

class BluetoothService {
  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  final StreamController<List<fbp.ScanResult>> _resultsController =
      StreamController<List<fbp.ScanResult>>.broadcast();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _readCharacteristic;
  fbp.BluetoothCharacteristic? _writeCharacteristic;

  Stream<List<fbp.ScanResult>> get scanResultsStream =>
      _resultsController.stream;

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.location.request();
  }

  Future<bool> ensurePoweredOn() async {
    if (await fbp.FlutterBluePlus.isSupported == false) return false;
    await fbp.FlutterBluePlus.turnOn();
    return true;
  }

  Future<void> startScanning({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (Platform.isAndroid) {
      print("SCAN START SCAN:::::::::::::::::::");
      await fbp.FlutterBluePlus.startScan(
        androidScanMode: fbp.AndroidScanMode.lowLatency,
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 5),
        timeout: const Duration(seconds: 10),
        withServices: [fbp.Guid(BleUuids.primaryServiceUuid)],
      );
    } else {
      await fbp.FlutterBluePlus.startScan(
        continuousUpdates: true,
        timeout: const Duration(seconds: 10),
        removeIfGone: const Duration(seconds: 5),
        withServices: [fbp.Guid(BleUuids.primaryServiceUuid)],
      );
    }
    await _scanSub?.cancel();
    _scanSub = fbp.FlutterBluePlus.scanResults.listen((results) {
      _resultsController.add(results);
    });
  }

  Future<void> stopScanning() async {
    await fbp.FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  Future<bool> connect(
    fbp.BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _connectedDevice = device;
    await device.connect(timeout: timeout).onError((error, stackTrace) async {
      // ignore if already connected
    });

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid == BleUuids.primaryService) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == BleUuids.primaryReadChar) {
            _readCharacteristic = characteristic;
          }
          if (characteristic.uuid == BleUuids.primaryWriteChar) {
            _writeCharacteristic = characteristic;
          }
        }
        break;
      }
    }

    if (_readCharacteristic == null || _writeCharacteristic == null) {
      await disconnect();
      return false;
    }

    await _readCharacteristic!.setNotifyValue(true);
    return true;
  }

  Stream<List<int>>? get notifyStream => _readCharacteristic?.onValueReceived;

  Future<void> write(List<int> data, {bool withoutResponse = true}) async {
    if (_writeCharacteristic == null) return;
    await _writeCharacteristic!.write(data, withoutResponse: withoutResponse);
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } finally {
      _connectedDevice = null;
      _readCharacteristic = null;
      _writeCharacteristic = null;
    }
  }

  void dispose() {
    _scanSub?.cancel();
    _resultsController.close();
  }
}
