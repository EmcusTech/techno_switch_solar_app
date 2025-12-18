library;

import 'dart:async';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;

/// This class contains methods for Bluetooth functionality.
class BtUtils {
  // Private constructor for singleton pattern
  BtUtils._internal();

  // Single instance
  static final BtUtils _instance = BtUtils._internal();

  // Factory constructor returns the same instance
  factory BtUtils() => _instance;

  // Static getter for convenience
  static BtUtils get instance => _instance;

  /// The name of the Bluetooth device.
  // static const String BT_DEVICE_NAME = "GEMINI";

  ///characteristics and Service Uuids
  Uuid primaryServiceGuid = BleUuids.primaryService;
  Uuid primaryReadCharGuid = BleUuids.primaryReadChar;
  Uuid primaryWriteCharGuid = BleUuids.primaryWriteChar;

  ///(flutter_reactive_ble): ble initializations
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  ///(flutter_reactive_ble): ble variables
  final Map<String, DiscoveredDevice> _connectedDevices = {};
  final Map<String, QualifiedCharacteristic> _rxCharacteristics = {};
  final Map<String, QualifiedCharacteristic> _txCharacteristcis = {};

  ///(flutter_reactive_ble): connectionStateUpdate is an observable instance over the ble connection
  final Map<String, StreamSubscription<ConnectionStateUpdate>>
  _connectionSubscription = {};

  ///(flutter_reactive_ble): Scan Variables
  final List<DiscoveredDevice> _scanResults = [];
  final StreamController<List<DiscoveredDevice>> _scanController =
      StreamController.broadcast();

  ///(flutter_reactive_ble): to allow only listening as no instance of the Scan Controller is shared openly across the app
  Stream<List<DiscoveredDevice>> get scanResultsStream =>
      _scanController.stream;

  ///(flutter_reactive_ble): Starts the Scan process
  ///(flutter_reactive_ble): Using StreamSubscription for constant listening
  StreamSubscription<DiscoveredDevice> startScan() {
    ///clears the previous scanResults for better truths
    _scanResults.clear();

    return _ble
        .scanForDevices(
          withServices: [primaryServiceGuid],

          ///low latency mode for faster and as often scans, at the cost of battery
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          ///Checks for already added devices in the scanResult
          ///If not done, we will get the same devices in our scanResult
          ///as the ble emits ads every 7 to 10 secs and if not checked we will add them again and again.
          final exits = _scanResults.any((d) => d.id == device.id);

          if (!exits) {
            _scanResults.add(device);

            ///This exposes the data from the ble utils across the app
            _scanController.add(List.unmodifiable(_scanResults));
          }
        });
  }

  ///(flutter_reactive_ble): This is Stop Scan
  Future<void> stopScan(StreamSubscription sub) async {
    ///On cancelling the subscription, there is no active listeners for the ble on android level.
    ///Then Android auto cancels the scan process as the process is attached to active listeners.
    await sub.cancel();
  }

  ///(flutter_reactive_ble): Returns the first connected ble device tracked by this app
  Future<DiscoveredDevice?> getConnectedDevice() async {
    if (_connectedDevices.isNotEmpty) {
      return _connectedDevices.values.first;
    }
    return null;
  }

  ///Writes data to the primary write characteristic using flutter_reactive_ble
  ///
  /// [withoutResponse] controls Write with Response vs Write without response
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

  ///(flutter_reactive_ble): checks if any ble device is connected already
  Future<bool> isConnected() async {
    return _connectedDevices.isNotEmpty;
  }

  ///(flutter_reactive_ble): Disconnects from all connected BLE devices.
  Future<void> disconnect() async {
    logger.Logger(
      "------------------------------Disconnected From App-------------------------------------",
    );

    //creating a copy to avoid concurrent modification as the list may be updated while in process
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

  ///(flutter_reactive_ble):  Connects to specific device
  Stream<DeviceConnectionState> connectToDevice(DiscoveredDevice device) {
    //if already connected, emit connected immediately
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
            // Emit connecting/disconnected states immediately
            if (update.connectionState != DeviceConnectionState.connected) {
              controller.add(update.connectionState);
            }

            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _connectedDevices[device.id] = device;
                logger.Logger("Connected with ${device.name}");
                // Prepare characteristics BEFORE emitting connected state
                await prepareCharacteristics(device);
                logger.Logger(
                  "Characteristics prepared, emitting connected state",
                );
                // Now emit connected state after characteristics are ready
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

  ///Prepares the BLE characteristics used by the app for a connected device
  ///In flutter_reactive_ble, services are not discovered dynamically
  ///we explicitly declare the characteristics we intent to use.
  ///
  ///Must be called after a successful connection
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

  ///Subscribes to notification
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

  /// Returns the name of the Bluetooth device.
  String getBTDeviceName(DiscoveredDevice device) {
    if (device.name.isNotEmpty) {
      return device.name;
    }
    return device.id;
  }
}

/// An enum representing different errors that may occur during Bluetooth write operations.
enum BluetoothWriteError {
  nackUnSuccess,
  ackSuccess,
  invalidFrame,
  authenticationRequired,

  /// Indicates a CRC mismatch error occurred during the write operation.
  crcMissMatchError,
  busyOnProcess,

  /// Represents no error condition.
  none,
}

enum BleBondingStates { bondingDone, bondingOngoing, none }
