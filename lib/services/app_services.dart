import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';

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

  // Shared SerialCommunicationService instance
  static final SerialCommunicationService _serialService =
      SerialCommunicationService();

  /// Get the shared SerialCommunicationService instance
  static SerialCommunicationService get serialService => _serialService;

  /// Check if device is currently connected
  static bool get isConnected => _serialService.isConnected;

  /// Get current connection state
  static PanelConnectionState get connectionState =>
      _serialService.connectionState;

  /// Get connected device
  static BluetoothDevice? get connectedDevice => _serialService.connectedDevice;

  /// Dispose all services (call this when app is closing)
  static void dispose() {
    _serialService.dispose();
  }
}
