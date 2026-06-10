import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';
import 'package:techno_switch_solar_app/services/bluetooth_connection_manager.dart';
import 'package:techno_switch_solar_app/services/technoswitch_ble_service.dart';
import 'dart:async';

class AppServices {
  AppServices._internal();

  static final AppServices _instance = AppServices._internal();

  factory AppServices() => _instance;

  static SerialCommunicationService get serialService =>
      SerialCommunicationService.instance;

  static TechnoswitchBleService get bleService =>
      TechnoswitchBleService.instance;

  static bool get isConnected =>
      serialService.isConnected || bleService.isConnected;

  static PanelConnectionState get connectionState =>
      serialService.connectionState;

  static DiscoveredDevice? get connectedDevice => serialService.connectedDevice;

  static Future<void> initialize() async {
    _setupStateListeners();
  }

  static void _setupStateListeners() {
    final service = serialService;

    service.statusStream.listen((status) {
      AppState.updateConnectionStatus(status);
      AppState.updateConnectionState(service.connectionState);

      if (service.connectedDevice != null) {
        AppState.updateConnectedDeviceName(service.connectedDevice!.name);
      } else {
        AppState.updateConnectedDeviceName(null);
      }
    });

    service.logStream.listen((log) {
      AppState.addLog(log);
    });
  }

  static Future<void> dispose() async {
    serialService.dispose();
    await bleService.disconnect();
    AppState.dispose();
  }

  static Future<bool> connectToDevice({String? deviceName}) async {
    return await BluetoothConnectionManager.ensureConnection(
      deviceName: deviceName,
    );
  }

  static Future<bool> reconnectToDevice(String deviceName) async {
    return await BluetoothConnectionManager.reconnectToDevice(deviceName);
  }

  static Future<void> disconnect() async {
    await BluetoothConnectionManager.safeDisconnect();
    await bleService.disconnect();
    AppState.reset();
  }

  static void startLogRetrieval() {
    AppState.setLogRetrievalStatus(true);
    AppState.clearLogs();
    serialService.startLogRetrieval();
  }

  static Future<List<DiscoveredDevice>> scanForDevices() async {
    return await serialService.scanForDevices();
  }

  static bool get isConnecting => BluetoothConnectionManager.isConnecting;

  static bool get isReconnecting => BluetoothConnectionManager.isReconnecting;
}
