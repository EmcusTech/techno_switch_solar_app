import 'package:techno_switch_solar_app/services/app_services.dart';

class BluetoothConnectionManager {
  static bool _isConnecting = false;
  static bool _isReconnecting = false;

  static Future<bool> ensureConnection({String? deviceName}) async {
    if (_isConnecting) {
      return false;
    }

    if (AppServices.isConnected) {
      return true;
    }

    _isConnecting = true;
    try {
      final result = await AppServices.serialService.connectToDevice(
        deviceName: deviceName,
      );
      return result;
    } catch (e) {
      print('Connection error: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  static Future<bool> reconnectToDevice(String deviceName) async {
    if (_isReconnecting) {
      return false;
    }

    _isReconnecting = true;
    try {
      if (AppServices.isConnected) {
        AppServices.serialService.disconnect();
      }

      await Future.delayed(Duration(seconds: 1));

      return await AppServices.serialService.connectToDevice(
        deviceName: deviceName,
      );
    } catch (e) {
      print('Reconnection error: $e');
      return false;
    } finally {
      _isReconnecting = false;
    }
  }

  static Future<void> safeDisconnect() async {
    try {
      AppServices.serialService.disconnect();
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  static bool get isConnecting => _isConnecting;

  static bool get isReconnecting => _isReconnecting;
}
