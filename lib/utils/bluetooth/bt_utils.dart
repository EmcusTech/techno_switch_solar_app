/*
* Project      : gemini_mobile_app
* File         : bt_utils.dart
* Description  : Bluetooth functionalities including BLE support, device connection management, data reading/writing, scanning, and notifications, along with Bluetooth bonding states and error handling enums.
* Author       : SrihariharanT
* Date         : 2024-05-20
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

/// This class contains methods for Bluetooth functionality.
class BtUtils {
  /// The name of the Bluetooth device.
  // static const String BT_DEVICE_NAME = "GEMINI";

  ///characteristics and Service Uuids
  Guid primaryServiceGuid = BleUuids.primaryService;
  Guid primaryReadCharGuid = BleUuids.primaryReadChar;
  Guid primaryWriteCharGuid = BleUuids.primaryWriteChar;

  /// Returns a stream that provides updates on the state of the Bluetooth adapter.
  /// This stream can be used to listen for changes in the Bluetooth adapter's state,
  /// such as when Bluetooth is turned on or off.
  Stream<BluetoothAdapterState> getBluetoothAdapterState() {
    return FlutterBluePlus.adapterState;
  }

  /// Retrieves a list of connected Bluetooth devices.
  /// Returns a list of connected Bluetooth devices or null if no device is connected.
  Future<BluetoothDevice?> getConnectedDevices() async {
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    if (connectedDevices.isNotEmpty) {
      return connectedDevices.first;
    } else {
      return null;
    }
  }

  /// Writes data to a connected Bluetooth device.
  /// connectedDevice: The connected Bluetooth device.
  /// data: The data to be written to the device.
  Future<void> writeData(
    dynamic connectedDevice,
    List<int> data, {
    Function(bool)? dataWritten,
    bool withoutResponse = true,
  }) async {
    await writeCharacteristic(
      connectedDevice,
      BtUtils().primaryServiceGuid.toString(),
      BtUtils().primaryWriteCharGuid.toString(),
      data,
      dataWritten: dataWritten,
      withoutResponse: withoutResponse,
    );
    // if (withoutResponse) {
    //   await writeCharacteristic(
    //       connectedDevice,
    //       BtUtils().primaryServiceGuid.toString(),
    //       BtUtils().primaryWriteCharGuid.toString(),
    //       data,
    //       dataWritten: dataWritten,
    //       withoutResponse: withoutResponse);
    // } else {
    //   await writeCharacteristicWithResponse(
    //       connectedDevice,
    //       BtUtils().secondaryServiceGuid.toString(),
    //       BtUtils().secondaryWriteCharGuid.toString(),
    //       data,
    //       dataWritten: dataWritten,
    //       withoutResponse: withoutResponse);
    // }
  }

  /// Checks if the mobile device is connected to any Bluetooth device.
  /// Returns `true` if connected, otherwise `false`.
  Future<bool> isConnected() async {
    // List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    return FlutterBluePlus.connectedDevices.isNotEmpty;
  }

  /// Requests to enable Bluetooth on the mobile device if it's an Android device.
  Future<void> enableBluetooth() async {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    } else {
      // AppAlert.alertSnackBar(Get.context!, turnOnBluetooth.tr);
    }
  }

  /// Requests to Disable Bluetooth on the mobile device if it's an Android device.
  Future<void> disableBluetooth() async {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOff();
    }
  }

  /// Starts scanning for available BLE devices.
  /// When a device is found, the provided [callback] function is called with a list
  /// of [ScanResult] objects containing information about the discovered devices.
  /// This function also sets up cleanup logic to cancel the scanning subscription
  /// when scanning stops.
  /// On Android, it starts scanning with low latency mode and specifies the device
  /// name to filter the scan results. The scanning duration is set to 6 seconds.
  /// On other platforms, it starts scanning with the specified device name and a
  /// duration of 6 seconds.
  List<ScanResult> scanResults = <ScanResult>[];

  Future<void> scanDevices(void Function(List<ScanResult>) callback) async {
    Logger("SCAN::: STARTED");
    StreamSubscription<List<ScanResult>>? subscription;
    scanResults = <ScanResult>[];

    int refreshCount = 0;
    int maxRefresh = 3;

    try {
      subscription = FlutterBluePlus.scanResults.listen(
        (List<ScanResult> results) async {
          if (refreshCount == maxRefresh) {
            refreshCount = 0;
            Logger("Ble Scan Callback Received ${scanResults.length}");
            if (results.isNotEmpty) {
              // Clear previous scan results
              scanResults.clear();
              await Future<dynamic>.delayed(const Duration(milliseconds: 500));
              // Add only new results to scanResults
              for (ScanResult result in results) {
                if (!scanResults.any(
                  (ScanResult existingResult) =>
                      existingResult.device.remoteId == result.device.remoteId,
                )) {
                  scanResults.add(result);
                }
              }
              callback(scanResults);
            } else {
              scanResults.clear();
              Logger("SCAN::: No devices found");
              // Handle case when no devices are found
              callback(scanResults); // Optionally pass an empty list
            }
          } else {
            refreshCount++;
          }
        },
        onDone: () {
          Logger("Scaning DONE }}}}}}}}}}}}}}}}}}}}}");
        },
        onError: (dynamic e) => Logger('SCAN ERROR::: $e'),
      );

      // Start scanning
      if (Platform.isAndroid) {
        Logger("SCAN START SCAN:::::::::::::::::::");
        await FlutterBluePlus.startScan(
          androidScanMode: AndroidScanMode.lowLatency,
          continuousUpdates: true,
          removeIfGone: const Duration(seconds: 5),
          timeout: const Duration(seconds: 10),
          withServices: <Guid>[Guid(BleUuids.primaryServiceUuid)],
        );
      } else {
        await FlutterBluePlus.startScan(
          continuousUpdates: true,
          timeout: const Duration(seconds: 10),
          removeIfGone: const Duration(seconds: 5),
          withServices: <Guid>[Guid(BleUuids.primaryServiceUuid)],
        );
      }

      FlutterBluePlus.cancelWhenScanComplete(subscription);
      // Optional: Add a delay for stabilization
      await Future<dynamic>.delayed(const Duration(seconds: 1));
    } catch (e) {
      Logger('SCAN ERROR::: $e');
      // Handle errors appropriately
    }
  }

  /// Stops the scanning process for BLE devices.
  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
  }

  /// Disconnects from all connected BLE devices.
  Future<void> disconnect() async {
    Logger(
      "------------------------------Disconnected From App-------------------------------------",
    );
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    for (BluetoothDevice device in connectedDevices) {
      if (Platform.isAndroid) {
        await device.clearGattCache();
      }
      await device.disconnect();
    }
  }

  /// Checks if there are any connected Bluetooth devices.
  ///
  /// Returns `true` if there are connected devices, otherwise `false`.
  bool checkIfAnyConnectedDevices() {
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;

    bool connectedDevicesAvailable = connectedDevices.isNotEmpty;

    return connectedDevicesAvailable;
  }

  /// Connects to the specified BLE device and invokes the provided [callback] upon connection.
  /// This function sets up a listener to handle disconnection events and cleanup logic to cancel
  /// the subscription when disconnected. It then attempts to connect to the device and invokes
  /// the callback with a boolean value indicating the connection status. If successfully connected,
  /// it also triggers the discovery of services.
  /// device: The Bluetooth device to connect to.
  /// callback: The callback function to be invoked upon connection.
  Future<void> connectToDevice(
    BluetoothDevice device,
    void Function(bool) callback,
  ) async {
    /// listen for disconnection
    StreamSubscription<BluetoothConnectionState>
    subscription = device.connectionState.listen((
      BluetoothConnectionState state,
    ) async {
      if (state == BluetoothConnectionState.connected) {
        /// Initiates the discovery of services for the given Bluetooth device.
        discoverServices(device);
        callback(true);
      }
    });

    /// cleanup: cancel subscription when disconnected
    /// Note: `delayed:true` lets us receive the `disconnected` event in our handler
    /// Note: `next:true` means cancel on *next* disconnection. Without this, it
    ///   would cancel immediately because we're already disconnected right now.

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    // await SharedPreference().storeConnectState(false);

    /// Connect to the device
    try {
      await device.connect(timeout: const Duration(seconds: 5));
    } catch (e) {
      Logger(
        "<<<<::::::::::::::::::Connection Exception:::::::::::::::::::>>>>>>",
      );
      Logger(e.toString());
      callback(false);
    }

    await subscription.cancel();
  }

  /// Discovers services provided by the connected BLE device.
  /// device: The Bluetooth device whose services are to be discovered.
  Future<void> discoverServices(BluetoothDevice device) async {
    /// You must call discoverServices after every re-connection!
    List<BluetoothService> services = await device.discoverServices(
      subscribeToServicesChanged: false,
    );
    for (BluetoothService service in services) {
      Logger("discoverServices$service");
    }
  }

  /// Reads data from a specified characteristic of the connected BLE device.
  /// device: The Bluetooth device from which data is to be read.
  /// serviceUuid: The UUID of the service.
  /// characteristicUuid: The UUID of the characteristic.
  /// Returns the data read from the characteristic as a list of integers.
  Future<List<int>?> readCharacteristic(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    BluetoothCharacteristic? characteristics = await _getCharacteristics(
      device,
      serviceUuid,
      characteristicUuid,
    );
    if (characteristics != null && characteristics.properties.read) {
      List<int> value = await characteristics.read();
      return value;
    }
    return null;
  }

  /// Writes data to a specified characteristic of the connected BLE device.
  /// device: The Bluetooth device to write data to.
  /// serviceUuid: The UUID of the service.
  /// characteristicUuid: The UUID of the characteristic.
  /// data: The data to be written.
  Future<void> writeCharacteristic(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
    List<int> data, {
    Function(bool)? dataWritten,
    bool? withoutResponse,
  }) async {
    BluetoothCharacteristic? characteristics = await _getCharacteristics(
      device,
      serviceUuid,
      characteristicUuid,
    );

    Logger("_________________Before Writing to BLE________________");

    if (characteristics != null &&
        (characteristics.properties.write ||
            characteristics.properties.writeWithoutResponse)) {
      try {
        ///writing data packets to the BLE
        await characteristics.write(
          data,
          withoutResponse: withoutResponse ?? false,
        );
        Logger(
          "Data Written :(withoutResponse:${withoutResponse ?? false})::(${DateTime.now().second}:${DateTime.now().millisecond})::> $data",
        );
        if (dataWritten != null) {
          dataWritten(true);
        }

        /// To check what data got written to the BLE

        ///handling the Exception
      } catch (e) {
        // TODO(username): message.
        if (dataWritten != null) {
          dataWritten(false);
        }
        Logger(e.toString());
      }
    }
  }

  Future<void> writeCharacteristicWithResponse(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
    List<int> data, {
    Function(bool)? dataWritten,
    bool? withoutResponse,
  }) async {
    BluetoothCharacteristic? characteristics = await _getCharacteristics(
      device,
      serviceUuid,
      characteristicUuid,
    );

    if (characteristics != null &&
        (characteristics.properties.write ||
            characteristics.properties.writeWithoutResponse)) {
      try {
        ///writing data packets to the BLE
        await characteristics.write(data, withoutResponse: false);
        //Logger("Data Written :::::> $data");
        dataWritten!(true);

        /// To check what data got written to the BLE

        ///handling the Exception
      } catch (e) {
        // TODO(username): message.
        dataWritten!(false);
        //Logger("Data Writte Failed :::::> $data");
        // Logger(e.toString());
      }
    }
  }

  /// Retrieves the Bluetooth characteristic based on the service UUID and characteristic UUID.
  ///
  /// This function searches for the specified service UUID in the list of services provided
  /// by the Bluetooth device. Once found, it searches for the characteristic with the given
  /// characteristic UUID within that service. If found, it returns the Bluetooth characteristic,
  /// otherwise returns null.
  ///
  /// Parameters:
  ///   - device: The [BluetoothDevice] from which to retrieve characteristics.
  ///   - serviceUuid: The UUID of the service to search for.
  ///   - characteristicUuid: The UUID of the characteristic to retrieve.
  ///
  /// Returns:
  ///   - A [BluetoothCharacteristic] object if found, otherwise null.
  /// Ensure that the provided service UUID and characteristic UUID are correct
  /// and supported by the Bluetooth device.
  ///
  Future<BluetoothCharacteristic?> _getCharacteristics(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    // Logger("Checking Device Service List");

    /// Discover services
    List<BluetoothService> services = await device.discoverServices();
    // Logger(services.toString());
    BluetoothService? bluetoothService = services.firstWhere(
      (BluetoothService element) => element.uuid.toString() == serviceUuid,
    );
    Iterable<BluetoothCharacteristic> characteristics = bluetoothService
        .characteristics
        .where(
          (BluetoothCharacteristic element) =>
              element.uuid.toString() == characteristicUuid,
        );
    return characteristics.isNotEmpty ? characteristics.first : null;
  }

  /// Enables notifications for a specified characteristic of the connected BLE device.
  /// device: The Bluetooth device to enable notifications for.
  /// serviceUuid: The UUID of the service.
  /// characteristicUuid: The UUID of the characteristic.
  /// callback: The callback function to be invoked when notifications are received.
  ///
  Future<void> _enableNotifications(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
    void Function(List<int>) callback,
    Function(bool)? notifyEnabledcallback,
  ) async {
    BluetoothCharacteristic? characteristics = await _getCharacteristics(
      device,
      serviceUuid,
      characteristicUuid,
    );
    Logger(
      "..................................Got character..............................",
    );
    Logger(characteristics!.characteristicUuid.toString());
    Logger(characteristics.properties.notify.toString());
    if (characteristics.properties.notify) {
      Logger("<<<<<<<<<<<<<<<<<<<notify enabled>>>>>>>>>>>>>>>>>");
      notifyEnabledcallback!(true);
      final StreamSubscription<List<int>> subscription = characteristics
          .onValueReceived
          .listen((List<int> value) {
            Logger("::::>>>>> Notify Recived <<<<::::");
            callback(value);
          });

      device.cancelWhenDisconnected(subscription);

      await characteristics.setNotifyValue(true);
    } else {
      notifyEnabledcallback!(false);
    }
  }

  /// Enables notifications for a specified characteristic of the connected BLE device.
  ///
  /// This function internally calls `_enableNotifications` with the provided
  /// connected device, service UUID, characteristic UUID, and callback function.
  ///
  /// Parameters:
  ///   - connectedDevice: The [BluetoothDevice] to enable notifications for.
  ///   - callback: A callback function to handle received notification data.
  ///
  /// Ensure that the provided service UUID and characteristic UUID are correct
  /// and supported by the connected Bluetooth device.
  void enableNotifications(
    dynamic connectedDevice,
    void Function(List<int>) callback, {
    Function(bool)? notifyEnabledcallback,
  }) {
    _enableNotifications(
      connectedDevice,
      primaryServiceGuid.toString(),
      primaryReadCharGuid.toString(),
      callback,
      notifyEnabledcallback,
    );
  }

  /// Returns the name of the Bluetooth device.
  /// This function attempts to retrieve the device name from different sources
  /// in the following order of preference:
  /// 1. Advertising name (`advName`)
  /// 2. Platform-specific name (`platformName`)
  /// 3. Bluetooth name (`name`)
  /// 4. Remote ID (`remoteId.str`)
  ///
  /// If none of the above sources provide a non-empty name, an empty string is returned.
  /// [device]: The [BluetoothDevice] for which the name is to be retrieved.
  ///
  /// Returns the name of the Bluetooth device.
  String getBTDeviceName(BluetoothDevice device) {
    if (device.advName.isNotEmpty) {
      return device.advName;
    } else if (device.platformName.isNotEmpty) {
      return device.platformName;
    } else if (device.name.isNotEmpty) {
      return device.name;
    } else if (device.remoteId.str.isNotEmpty) {
      return device.remoteId.str;
    }
    return "";
  }

  /// Disables notifications for a specified characteristic of the connected BLE device.
  /// device: The Bluetooth device to disable notifications for.
  /// serviceUuid: The UUID of the service.
  /// characteristicUuid: The UUID of the characteristic.
  Future<void> disableNotifications(
    BluetoothDevice device,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    BluetoothCharacteristic? characteristics = await _getCharacteristics(
      device,
      serviceUuid,
      characteristicUuid,
    );
    if (characteristics != null && characteristics.properties.notify) {
      await characteristics.setNotifyValue(false);
    }
  }

  /// Reads data from a specified characteristic of the connected BLE device.
  /// connectedDevice: The connected Bluetooth device.
  /// Returns the data read from the characteristic as a list of integers.
  Future<List<int>?> readCharacteristicData(dynamic connectedDevice) {
    return readCharacteristic(
      connectedDevice,
      primaryServiceGuid.toString(),
      primaryReadCharGuid.toString(),
    );
  }

  /// Handles the change in Maximum Transmission Unit (MTU) value for the connected BLE device.
  /// device: The Bluetooth device whose MTU value is to be monitored.
  /// mtu: The MTU value to be set.
  Future<void> onMtuValueChange(BluetoothDevice device, {int? mtu}) async {
    final StreamSubscription<int> subscription = device.mtu.listen((int mtu) {
      // iOS: initial value is always 23, but iOS will quickly negotiate a higher value
      Logger("mtu--------------->> $mtu");
    });

    /// cleanup: cancel subscription when disconnected
    device.cancelWhenDisconnected(subscription);

    // if (Platform.isAndroid) {
    //   await device.requestMtu(mtu);
    // }
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
