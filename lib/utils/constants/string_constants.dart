abstract final class StringConstants {
  //App Title
  static const String appTitle = "Techno Switch Solar";

  //Errors and Validation
  static const String convError =
      "Unsupported data type for conversion to bytes";
  static const String isHexRegExp = r'^[0-9A-Fa-f]+$';
  static const String invalidFrameLen = "Invalid frame length";
  static const String mismatchFrameLen =
      "Frame length does not match payload length";
  static const String sofValidationFail = "SOF validation failed";
  static const String cmdValidationFail = "CMD validation failed";
  static const String tofValidationFail = "TOF validation failed";
  static const String payloadLenValidationFail =
      "Payload length validation failed";
  static const String crcValidationFail = "CRC validation failed";
  static const String eofValidationFail = "EOF validation failed";
  static const String disconnectHandshake = "Disconnected during handshake";
  static const String disconnectConn = "Disconnected during connection";

  //Process
  static const String regNotifyHand = "Register notify handler";
  static const String cancelNotifySub =
      "Cancelling existing notify subscription before re-registering";
  static const String devDisconnectBeforeNot =
      "Device disconnected before notification start";
  static const String notifyCharNotInit =
      "Notify characteristic not initialized";
  static const String listenNotifications = "Listening for notifications...";
  static const String notifyHandReg = "---Notification handler registered----";
  static const String devNotConnRet = "Device not connected, returning";
  static const String devNotFoundRet = "Device not found, returning";
  static const String rxIgnored = "RX ignored after OTA completion";
  static const String invalidDataByteConv =
      "Unsupported data type for conversion to bytes";

  //BLE
  static const String bleAuthMsg = "TECHNOSWITCH-AUTH-APP";
  static const String bleServiceUuid = "D973F2F0-B19E-11E2-9E96-0800200C9A66";
  static const String bleNotifyUuid = "D973F2F1-B19E-11E2-9E96-0800200C9A66";
  static const String bleWriteUuid = "D973F2F2-B19E-11E2-9E96-0800200C9A66";
  static const String deviceNotConnected = "Device not connected";
  static const String bleCharNotInit = "BLE characteristics not initialized";
  static const String bleHandshakeIncomplete = "BLE handshake not complete";
  static const String bleSessionReset = "BLE session reset";
  static const String bleConnAbort = "Connection attempt aborted";
  static const String bleConnSuccess = "BLE connected successfully";
  static const String bleMaxRetryReached =
      "Max BLE retry attempts reached, please scan again and connect.";
  static const String bleClearingGattCache = "Clearing GATT cache...";
  static const String bleClearedGattCache = "GATT cache cleared";
  static const String blePermissionNotGranted =
      "Bluetooth permissions not granted";
  static const String bleDeviceDisconnect = "Disconnecting device...";
  static const String bleShutdown = "Shutdown BLE";
  static const String bleAeskey = "AES_KEY";
}
