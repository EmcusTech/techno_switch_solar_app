// lib/services/bluetooth_service.dart
//
// Windows + Mobile compatible Bluetooth service using `universal_ble`.
// Author: ChatGPT (helped by Manoranjan's original flutter_blue_plus code)
// Usage: add `universal_ble: ^0.21.1` to pubspec.yaml
//

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  // Scanning
  StreamSubscription<BleDevice>? _scanSub;
  final StreamController<List<BleDevice>> _resultsController =
      StreamController<List<BleDevice>>.broadcast();

  // Connected device and characteristics
  BleDevice? _connectedDevice;
  BleCharacteristic? _readCharacteristic;
  BleCharacteristic? _writeCharacteristic;

  // Internal map for deduping scan results
  final Map<String, BleDevice> _scanResultsMap = {};

  // Exposed streams
  Stream<List<BleDevice>> get scanResultsStream => _resultsController.stream;

  // You can tweak these UUIDs as required (strings, lowercase or uppercase ok)
  final String
  primaryServiceUuid; // e.g. "0000xxxx-0000-1000-8000-00805f9b34fb"
  final String primaryReadCharUuid;
  final String primaryWriteCharUuid;

  BluetoothService({
    required this.primaryServiceUuid,
    required this.primaryReadCharUuid,
    required this.primaryWriteCharUuid,
  });

  /// Request permissions for Android. On Windows desktop these generally aren't needed,
  /// but this function is safe to call cross-platform.
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      // Location may be required on older Android versions for scanning:
      await Permission.location.request();
    }
  }

  /// Check availability/power on state. Returns true if BLE is available & powered on.
  Future<bool> ensurePoweredOn() async {
    // UniversalBle provides availability state checks
    try {
      final state = await UniversalBle.getBluetoothAvailabilityState();
      return state == AvailabilityState.poweredOn;
    } catch (e) {
      // On some platforms the call might fail; return false to indicate not ready.
      return false;
    }
  }

  /// Start scanning. Filters by service UUID if provided (on Windows & other platforms it is supported).
  Future<void> startScanning({
    Duration timeout = const Duration(seconds: 10),
    bool filterByService = true,
  }) async {
    // clear previous results
    _scanResultsMap.clear();
    _resultsController.add([]);

    // Setup scan listener
    await _scanSub?.cancel();
    _scanSub = UniversalBle.scanStream.listen((bleDevice) {
      // maintain map to dedupe and collect RSSI/name changes
      _scanResultsMap[bleDevice.deviceId] = bleDevice;
      _resultsController.add(_scanResultsMap.values.toList(growable: false));
    });

    // Build optional filter
    ScanFilter? filter;
    if (filterByService && primaryServiceUuid.isNotEmpty) {
      filter = ScanFilter(withServices: [primaryServiceUuid]);
    }

    // Start scan
    try {
      UniversalBle.startScan(scanFilter: filter);
    } catch (e) {
      // Some platforms may throw if Bluetooth unavailable; surface empty results but keep app alive
      debugPrint('startScan error: $e');
    }
  }

  Future<void> stopScanning() async {
    try {
      UniversalBle.stopScan();
    } catch (e) {
      // ignore
    }
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /// Connects to a device (BleDevice). Returns true if connection + characteristic discovery + notify setup succeeded.
  Future<bool> connect(
    BleDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _connectedDevice = device;

    // Ensure we stop scanning to avoid conflicts
    await stopScanning();

    try {
      // Connect
      await device.connect();

      // Discover services (cached automatically if needed)
      final services = await device.discoverServices();

      // Find the service & characteristics (UUIDs compared case-insensitive)
      final svc = services.firstWhere(
        (s) => s.uuid.toLowerCase() == primaryServiceUuid.toLowerCase(),
        orElse: () => throw Exception('Primary service not found'),
      );

      // find read/write characteristics
      for (final c in svc.characteristics) {
        final cu = c.uuid.toLowerCase();
        if (cu == primaryReadCharUuid.toLowerCase()) {
          _readCharacteristic = c;
        } else if (cu == primaryWriteCharUuid.toLowerCase()) {
          _writeCharacteristic = c;
        }
      }

      if (_readCharacteristic == null || _writeCharacteristic == null) {
        await disconnect();
        return false;
      }

      // Subscribe to notifications on read characteristic
      await _readCharacteristic!.notifications.subscribe();

      return true;
    } catch (e) {
      debugPrint('connect error: $e');
      await disconnect();
      return false;
    }
  }

  /// Stream of incoming bytes from read characteristic (Uint8List -> convert to List<int> if needed)
  Stream<List<int>>? get notifyStream =>
      _readCharacteristic?.onValueReceived.map((u8) => u8.toList());

  /// Write bytes to write characteristic. `withoutResponse` maps to `withResponse: false`.
  Future<void> write(List<int> data, {bool withoutResponse = true}) async {
    if (_writeCharacteristic == null) return;
    try {
      await _writeCharacteristic!.write(
        Uint8List.fromList(data),
        withResponse: !withoutResponse,
      );
    } catch (e) {
      debugPrint('write error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint('disconnect error: $e');
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
