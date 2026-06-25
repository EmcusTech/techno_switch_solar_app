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
  static const String nackPacket = "The received packet is a nack packet";
  static const String wrongPassword = "Wrong password. Try again.";
  static const String adcSetupFetchCompleted = "Adc Setup Fetch Completed";
  static const String downloadingGeneralModuleSilenceBuzzerLvl =
      "Downloading General Module Silence Buzzer LVL";
  static const String downloadingGeneralModuleSilenceSounderLvl =
      "Downloading General Module Silence Sounder LVL";
  static const String downloadingGeneralModuleResetLvl =
      "Downloading General Module Reset LVL";
  static const String downloadingGeneralModuleFaultLatching =
      "Downloading General Module Fault Latching";
  static const String generalModuleSetupFetchCompleted =
      "General Module Setup Fetch Completed";
  static const String applyingGeneralModuleSilenceBuzzerLvl =
      "Applying General Module Silence Buzzer LVL";
  static const String applyingGeneralModuleSilenceSounderLvl =
      "Applying General Module Silence Sounder LVL";
  static const String applyingGeneralModuleResetLvl =
      "Applying General Module Reset LVL";
  static const String applyingGeneralModuleFaultLatching =
      "Applying General Module Fault Latching";
  static const String generalModuleSetupApplyCompleted =
      "General Module Setup Apply Completed";
  static const String panelInfoSetupFetchCompleted =
      "Panel Info Setup Fetch Completed";
  static const String panelInfoSetupApplyCompleted =
      "Panel Info Setup Apply Completed";
  static const String accessCodeSetupFetchCompleted =
      "Access Code Setup Fetch Completed";
  static const String accessCodeSetupApplyCompleted =
      "Access Code Setup Apply Completed";

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
  static const String downloadInputSetup = "Downloading Input Setup";
  static const String downloadExtOutSetup = "Downloading Ext Out Setup";
  static const String applyingExtOutSetup = "Applying Ext Out Setup";
  static const String applyingInputSetup = "Applying Input Setup";
  static const String downloadingRelay = "Downloading Relay";
  static const String applyingRelay = "Applying Relay";
  static const String downloadingZone = "Downloading Zone";
  static const String applyingZone = "Applying Zone";
  static const String downloadingRadio = "Downloading Radio";
  static const String applyingRadio = "Applying Radio";
  static const String downloadingModule = "Downloading Module";
  static const String downloadingLBus = "Downloading L-Bus";
  static const String applyingLBus = "Applying L-Bus";
  static const String downloadingSounderRelays = "Downloading Sounder (Relays)";
  static const String applyingSounderRelays = "Applying Sounder (Relays)";
  static const String downloadingServiceDue = "Downloading Service Due";
  static const String applyingServiceDue = "Applying Service Due";
  static const String downloadingAccessCodeOne = "Downloading Access Code";
  static const String applyingAccessCodeOne = "Applying Access Code";
  static const String downloadingPanelInfo = "Downloading Panel Info";
  static const String applyingPanelInfo = "Applying Panel Info";
  static const String downloadingGeneralModule = "Downloading General Module";
  static const String applyingGeneralModuleTimeOut =
      "Applying General Module Level Time-out";
  static const String downloadingAdcSetup = "Downloading Adc Setup";
  static const String serviceDueFetchCompleted = "Service Due Fetch Completed";
  static const String serviceDueApplyCompleted = "Service Due Apply Completed";
  static const String downloadingSounderGeneral =
      "Downloading Sounder (General)";
  static const String downloadingSounderZones = "Downloading Sounder (Zones)";
  static const String downloadingSounderExtOut =
      "Downloading Sounder (Ext Out)";
  static const String sounderSetupFetchCompleted =
      "Sounder Setup Fetch Completed";
  static const String applyingSounderGeneral = "Applying Sounder (General)";
  static const String applyingSounderZones = "Applying Sounder (Zones)";
  static const String applyingSounderExtOut = "Applying Sounder (Ext Out)";
  static const String downloadingEnabledLBus = "Downloading Enabled L-Bus";
  static const String sendingExtOutPacket = "Sending Ext Out Packet";
  static const String operationTimedOut = "Operation timed out.";
  static const String somethingWentWrong =
      "Something went wrong, please try again.";
  static const String noResponseFromDevice = "No response from device";
  static const String deviceNotResponding = "Device not responding.";
  static const String sendingNetworkPacket = "Sending Network Packet";

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

  // MISC
  static const String panelNo1 = "Panel No. 1";
}
