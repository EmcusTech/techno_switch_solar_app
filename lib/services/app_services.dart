import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';
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

  static Future<void> disconnect() async {
    await bleService.disconnect();
    AppState.reset();
  }
}
