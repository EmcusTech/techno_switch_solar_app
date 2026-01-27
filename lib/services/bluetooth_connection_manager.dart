import 'package:techno_switch_solar_app/services/app_services.dart';

/// Manages Bluetooth connection state and prevents multiple concurrent connections
class BluetoothConnectionManager {
  static bool _isConnecting = false;
  static bool _isReconnecting = false;

  // /// Ensures a connection is established, preventing duplicate connection attempts
  // static Future<bool> ensureConnection({String? deviceName}) async {
  //   if (_isConnecting) {
  //     // Already attempting to connect, wait for it to complete
  //     return false;
  //   }

  //   if (AppServices.isConnected) {
  //     // Already connected
  //     return true;
  //   }

  //   _isConnecting = true;
  //   try {
  //     final result = await AppServices.serialService.connectToDevice(
  //       deviceName: deviceName,
  //     );
  //     return result;
  //   } catch (e) {
  //     print('Connection error: $e');
  //     return false;
  //   } finally {
  //     _isConnecting = false;
  //   }
  // }

  /// Attempts to reconnect to a specific device
  // static Future<bool> reconnectToDevice(String deviceName) async {
  //   if (_isReconnecting) {
  //     return false;
  //   }

  //   _isReconnecting = true;
  //   try {
  //     // First disconnect if connected
  //     if (AppServices.isConnected) {
  //       // AppServices.serialService.disconnect();
  //     }

  //     // Wait a bit before reconnecting
  //     await Future.delayed(Duration(seconds: 1));

  //     // Attempt to reconnect
  //     // return await AppServices.serialService.connectToDevice(
  //     //   deviceName: deviceName,
  //     // );
  //   } catch (e) {
  //     print('Reconnection error: $e');
  //     return false;
  //   } finally {
  //     _isReconnecting = false;
  //   }
  // }

  /// Safely disconnects from the device
  // static Future<void> safeDisconnect() async {
  //   try {
  //     AppServices.serialService.disconnect();
  //   } catch (e) {
  //     print('Disconnect error: $e');
  //   }
  // }

  /// Checks if currently attempting to connect
  static bool get isConnecting => _isConnecting;

  /// Checks if currently attempting to reconnect
  static bool get isReconnecting => _isReconnecting;
}
