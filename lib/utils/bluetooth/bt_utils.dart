library;

import 'dart:async';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;

class BtUtils {
  BtUtils._internal();

  static final BtUtils _instance = BtUtils._internal();

  factory BtUtils() => _instance;

  static BtUtils get instance => _instance;

  Uuid primaryServiceGuid = BleUuids.primaryService;
  Uuid primaryReadCharGuid = BleUuids.primaryReadChar;
  Uuid primaryWriteCharGuid = BleUuids.primaryWriteChar;

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final Map<String, DiscoveredDevice> _connectedDevices = {};
  final Map<String, QualifiedCharacteristic> _rxCharacteristics = {};
  final Map<String, QualifiedCharacteristic> _txCharacteristcis = {};
  final Map<String, StreamSubscription<ConnectionStateUpdate>>
  _connectionSubscription = {};
  final List<DiscoveredDevice> _scanResults = [];
  final StreamController<List<DiscoveredDevice>> _scanController =
      StreamController.broadcast();
  Stream<List<DiscoveredDevice>> get scanResultsStream =>
      _scanController.stream;
  StreamSubscription<DiscoveredDevice> startScan() {
    _scanResults.clear();

    return _ble
        .scanForDevices(
          withServices: [primaryServiceGuid],
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          final exits = _scanResults.any((d) => d.id == device.id);

          if (!exits) {
            _scanResults.add(device);
            _scanController.add(List.unmodifiable(_scanResults));
          }
        });
  }

  Future<void> stopScan(StreamSubscription sub) async {
    await sub.cancel();
  }

  Future<DiscoveredDevice?> getConnectedDevice() async {
    if (_connectedDevices.isNotEmpty) {
      return _connectedDevices.values.first;
    }
    return null;
  }

  Future<void> writeData(
    DiscoveredDevice device,
    List<int> data, {
    bool withoutResponse = false,
    Function(bool success)? dataWritten,
  }) async {
    final QualifiedCharacteristic? characteristic =
        _txCharacteristcis[device.id];

    if (characteristic == null) {
      logger.Logger("Write failed: TX characteristic not prepared");
      dataWritten?.call(false);
      return;
    }

    try {
      logger.Logger("Writing data (withoutResponse = $withoutResponse): $data");

      if (withoutResponse) {
        await _ble.writeCharacteristicWithoutResponse(
          characteristic,
          value: data,
        );
      } else {
        await _ble.writeCharacteristicWithResponse(characteristic, value: data);
      }

      dataWritten?.call(true);
    } catch (e) {
      logger.Logger("Write Error: $e");
      dataWritten?.call(false);
    }
  }

  Future<bool> isConnected() async {
    return _connectedDevices.isNotEmpty;
  }

  Future<void> disconnect() async {
    logger.Logger(
      "------------------------------Disconnected From App-------------------------------------",
    );

    final subscription =
        Map<String, StreamSubscription<ConnectionStateUpdate>>.from(
          _connectionSubscription,
        );

    for (final entry in subscription.entries) {
      try {
        logger.Logger("Disconnecting from ${entry.key}}");
        await entry.value.cancel();
      } catch (e) {
        logger.Logger("Disconnect error for ${entry.key}: $e");
      }
    }

    _connectedDevices.clear();
    _connectionSubscription.clear();
  }

  Stream<DeviceConnectionState> connectToDevice(DiscoveredDevice device) {
    if (_connectionSubscription.containsKey(device.id)) {
      return Stream.value(DeviceConnectionState.connected);
    }

    late final StreamController<DeviceConnectionState> controller;

    controller = StreamController<DeviceConnectionState>();

    Future.delayed(const Duration(milliseconds: 300));

    final sub = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) async {
            if (update.connectionState != DeviceConnectionState.connected) {
              controller.add(update.connectionState);
            }

            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _connectedDevices[device.id] = device;
                logger.Logger("Connected with ${device.name}");
                await prepareCharacteristics(device);
                logger.Logger(
                  "Characteristics prepared, emitting connected state",
                );
                controller.add(DeviceConnectionState.connected);
                break;
              case DeviceConnectionState.connecting:
                logger.Logger("Connecting with ${device.name}");
              case DeviceConnectionState.disconnected:
                _connectedDevices.remove(device.id);
                _connectionSubscription.remove(device.id);
                await controller.close();
                break;
              default:
                break;
            }
          },
          onError: (e) async {
            controller.addError(e);
            _connectedDevices.remove(device.id);
            _connectionSubscription.remove(device.id);
            await controller.close();
          },
        );

    _connectionSubscription[device.id] = sub;

    return controller.stream;
  }

  Future<void> prepareCharacteristics(DiscoveredDevice device) async {
    logger.Logger("Preparing characteristics for device: ${device.id}");

    final QualifiedCharacteristic readCharacteristic = QualifiedCharacteristic(
      characteristicId: primaryReadCharGuid,
      serviceId: primaryServiceGuid,
      deviceId: device.id,
    );

    final QualifiedCharacteristic writeCharacteristic = QualifiedCharacteristic(
      characteristicId: primaryWriteCharGuid,
      serviceId: primaryServiceGuid,
      deviceId: device.id,
    );

    _rxCharacteristics[device.id] = readCharacteristic;
    _txCharacteristcis[device.id] = writeCharacteristic;

    logger.Logger("Characteristics prepared");
    logger.Logger("RX: ${readCharacteristic.characteristicId}");
    logger.Logger("TX: ${writeCharacteristic.characteristicId}");
  }

  StreamSubscription<List<int>> subscribeToNotifications(
    DiscoveredDevice device, {
    required void Function(List<int>) onData,
    required void Function(Object error) onError,
  }) {
    final characteristic = _rxCharacteristics[device.id];

    if (characteristic == null) {
      throw StateError("RX characteristic not prepared for ${device.id}");
    }

    logger.Logger("Subscribing to notification for ${device.id}");

    return _ble
        .subscribeToCharacteristic(characteristic)
        .listen(onData, onError: onError);
  }

  String getBTDeviceName(DiscoveredDevice device) {
    if (device.name.isNotEmpty) {
      return device.name;
    }
    return device.id;
  }
}

enum BluetoothWriteError {
  nackUnSuccess,
  ackSuccess,
  invalidFrame,
  authenticationRequired,
  crcMissMatchError,
  busyOnProcess,
  none,
}

enum BleBondingStates { bondingDone, bondingOngoing, none }
