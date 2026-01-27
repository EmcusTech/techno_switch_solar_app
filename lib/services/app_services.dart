// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';
import 'package:techno_switch_solar_app/services/bluetooth_connection_manager.dart';
import 'package:techno_switch_solar_app/services/technoswitch_ble_service.dart';
import 'dart:async';

/// Singleton class to manage shared services across the app
/// This ensures that the same SerialCommunicationService instance
/// is used throughout the app, maintaining device connections
class AppServices {
  // Private constructor for singleton pattern
  AppServices._internal();

  // Single instance of AppServices
  static final AppServices _instance = AppServices._internal();

  // Factory constructor returns the same instance
  factory AppServices() => _instance;

  /// Get the singleton SerialCommunicationService
  static SerialCommunicationService get serialService =>
      SerialCommunicationService.instance;

  /// Technoswitch Gas Panel BLE service (new frame protocol).
  static TechnoswitchBleService get bleService =>
      TechnoswitchBleService.instance;

  /// Check if device is currently connected
  static bool get isConnected =>
      serialService.isConnected || bleService.isConnected;

  /// Get current connection state
  static PanelConnectionState get connectionState =>
      serialService.connectionState;

  /// Get connected device
  static DiscoveredDevice? get connectedDevice => serialService.connectedDevice;

  /// Initialize services (call once at app startup)
  static Future<void> initialize() async {
    // Initialize state listeners
    _setupStateListeners();
  }

  /// Setup listeners to sync service state with global app state
  static void _setupStateListeners() {
    // Listen to connection state changes
    final service = serialService;

    // Listen to status stream
    service.statusStream.listen((status) {
      AppState.updateConnectionStatus(status);
      AppState.updateConnectionState(service.connectionState);

      // Update device name when connected
      if (service.connectedDevice != null) {
        AppState.updateConnectedDeviceName(service.connectedDevice!.name);
      } else {
        AppState.updateConnectedDeviceName(null);
      }
    });

    // Listen to log stream
    service.logStream.listen((log) {
      AppState.addLog(log);
    });
  }

  /// Dispose all services (call when app closes)
  static Future<void> dispose() async {
    serialService.dispose();
    await bleService.disconnect();
    AppState.dispose();
  }

  /// Connect to a device using the connection manager
  static Future<bool> connectToDevice({String? deviceName}) async {
    return await BluetoothConnectionManager.ensureConnection(
      deviceName: deviceName,
    );
  }

  /// Reconnect to a specific device
  static Future<bool> reconnectToDevice(String deviceName) async {
    return await BluetoothConnectionManager.reconnectToDevice(deviceName);
  }

  /// Safely disconnect from the current device
  static Future<void> disconnect() async {
    await BluetoothConnectionManager.safeDisconnect();
    await bleService.disconnect();
    AppState.reset();
  }

  /// Start log retrieval with state management
  static void startLogRetrieval() {
    AppState.setLogRetrievalStatus(true);
    AppState.clearLogs();
    serialService.startLogRetrieval();
  }

  /// Get available devices
  static Future<List<DiscoveredDevice>> scanForDevices() async {
    return await serialService.scanForDevices();
  }

  /// Check if currently connecting
  static bool get isConnecting => BluetoothConnectionManager.isConnecting;

  /// Check if currently reconnecting
  static bool get isReconnecting => BluetoothConnectionManager.isReconnecting;
}
