export 'strings/db_keys.dart';
export 'strings/db_sql.dart';
export 'strings/panel_values.dart';
export 'strings/ui_strings.dart';

import 'strings/db_sql.dart';
import 'strings/panel_values.dart';
import 'strings/ui_strings.dart';

abstract final class StringConstants {
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
  static const String unableToReadServiceUuid = "Unable to read service UUID";
  static const String unableToReadCharacteristicUuid =
      "Unable to read characteristic UUID";

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
  static const String siteNameRequired = "Site Name is required";
  static const String saqccRegNumberRequired =
      "SAQCC Registration Number is required";
  static const String panelNameRequired = "Panel Name is required";
  static const String panelTypeRequired = "Panel Type is required";

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

  // Firmware
  static const String wantUpgrade = "Do you want to upgrade to";
  static const String wantDowngrade = "Do you want to downgrade to";
  static const String sameVersion = "The versions are same, continue?";

  // MISC
  static const String panelNo1 = "Panel No. 1";

  // UI & app strings (auto-migrated)
  static const String aSiteSiteSiteNameWasCreatedForPanelIDLogicalId =
      "Use site";
  static const String aZAZ09 = "[^a-zA-Z0-9]";
  static const String accessCode = "Access Code";
  static const String accessCodeNo2 = "Access Code No";
  static const String accessGranted = "Access granted";
  static const String accessLevel1 = "Access Level 1";
  static const String accessLevel2 = "Access Level 2";
  static const String accessLevel4 = "Access Level";
  static const String accessLevelName2 = "Access Level Name";
  static const String accessMode = "Access Mode";
  static const String accessOurComprehensiveUserManual =
      "Access our comprehensive user manual";
  static const String accesscode = "accessCode";
  static const String accesscodeno = "accessCodeNo";
  static const String accesslevel = "accessLevel";
  static const String accesslevelname = "accessLevelName";
  static const String action = "Action";
  static const String actuatorType = "Actuator Type";
  static const String actuatortype = "actuatorType";
  static const String additionalSupport = "Additional Support";
  static const String advancedConfiguration = "Advanced Configuration";
  static const String advertise = "Advertise";
  static const String advertisementdata = "advertisementData";
  static const String allConfigurationSectionsMatchTheSavedAppData =
      "All configuration sections match the saved app data.";
  static const String allNominal = PanelValues.diagnosticAllNominal;
  static const String alterTABLELogsADDCOLUMNIsValidINTEGER =
      "ALTER TABLE logs ADD COLUMN is_valid INTEGER";
  static const String alterTABLELogsADDCOLUMNRetrievalIdINTEGER =
      "ALTER TABLE logs ADD COLUMN retrieval_id INTEGER";
  static const String app = "App";
  static const String apply = "Apply";
  static const String applyNow = "Apply Now";
  static const String applyToPanel = "Apply to panel?";
  static const String applying = "Validated";
  static const String autoCountdown = "Auto Countdown";
  static const String autoFieldIsFocused = "Auto field is focused";
  static const String autoFieldLostFocus = "Auto field lost focus";
  static const String back = "Back";
  static const String batteryTest = "Battery Test";
  static const String bleDevice = "BLE Device";
  static const String bleDeviceIsNotConnectedTapOnConnectToConnectAgain =
      "BLE device is not connected. Tap on Connect to connect again.";
  static const String bleFirmwareVersion = UiStrings.moduleNoLabel;
  static const String bleHandshakeNotCompleteCannotStartFirmwareUpgrade =
      "BLE handshake not complete. Cannot start firmware upgrade.";
  static const String bleManagerNotFound = "BLE manager not found";
  static const String bleSolarDevice = "BLE Solar Device";
  static const String bluenrgm2sp = "BLUENRGM2SP";
  static const String bluetooth = "Bluetooth";
  static const String bluetoothBLEDevices =
      "Scan for nearby Bluetooth solar devices";
  static const String bluetoothDisconnected = "Bluetooth disconnected";
  static const String bluetoothIsNotEnabled = "Bluetooth is not enabled";
  static const String bluetoothIsOffPleaseEnableBluetoothToContinueScanning =
      "Bluetooth is off. Please enable Bluetooth to continue scanning.";
  static const String bluetoothOperationTimedOut =
      "Bluetooth operation timed out";
  static const String boot = "Boot";
  static const String bt = "BT_";
  static const String buildingName = "Building Name";
  static const String bulkApplyTimedOut = "Bulk apply timed out";
  static const String callSupport = "Call Support";
  static const String cancel = UiStrings.cancelButton;
  static const String close = UiStrings.closeButton;
  static const String continueLabel = UiStrings.continueButton;
  static const String create = UiStrings.createButton;
  static const String next = UiStrings.nextButton;
  static const String yes = UiStrings.yesButton;
  static const String update = UiStrings.updateButton;
  static const String okay = UiStrings.okayButton;
  static const String verify = UiStrings.verifyButton;
  static const String checkingDeviceStatus = "Checking device status...";
  static const String chooseScanType = "Choose Scan Type";
  static const String chooseTheSiteWhereThisPanelShouldBeAssigned =
      "Choose the site where this panel should be assigned.";
  static const String chooseWhatToTest = "Choose what to test";
  static const String clear = "Clear";
  static const String clearLogs = "Clear logs?";
  static const String commsFaultDuringDownloadNoFieldDifferencesVsApp =
      "Comms fault during download (no field differences vs app)";
  static const String communityForum = "Community Forum";
  static const String company = "Contact";
  static const String companyName = "Company Name";
  static const String compareWithSavedSetup = "Compare with saved setup";
  static const String comparing = "Comparing…";
  static const String configLog = "Config Log";
  static const String configuration = "Configuration";
  static const String confirmed = PanelValues.zoneModeConfirmed;
  static const String connect = "Connect";
  static const String connectAPanelToConfigurePeripherals =
      "Connect a panel to configure peripherals.";
  static const String connectPanel = "Connect panel";
  static const String connectToAPanelToAssociateItWithThisSite =
      "Connect to a panel to associate it with this site";
  static const String connected = "Connected";
  static const String connecting = "Connecting...";
  static const String connection = "Connection";
  static const String connectionLostNoDevice = "Connection lost - no device";
  static const String connectionNotEstablishedAfterReconnect =
      "Connection not established after reconnect";
  static const String connectionProblem = "Connection problem";
  static const String connectiontype = "connectionType";
  static const String continous = "Pulsing 1s On, 5s Off";
  static const String continuous = "Off";
  static const String control = "Control";
  static const String couldNotAssignPanelToSite =
      "Could not assign panel to site";
  static const String countDownAction = "Count Down Action";
  static const String countdown = "Countdown";
  static const String countdownAutoMustBeBetween0And60 =
      "Reset Delay must be between 0 and 1800";
  static const String countdownAutoS = "Countdown Auto (s)";
  static const String countdownManS = "Countdown Man (s)";
  static const String countdownaction = "countdownAction";
  static const String countdownauto = "isSolar";
  static const String countdownman = "ext_out";
  static const String crcMismatchBINFileMayBeCorrupted =
      "CRC mismatch. BIN file may be corrupted.";
  static const String crcMustBe4Bytes = "CRC must be 4 bytes";
  static const String createASite = "Create a site?";
  static const String createSite = "Create Site";
  static const String createSite2 = UiStrings.nextButton;
  static const String createSiteForLogs = "Create Site for Logs?";
  static const String created = "Created";
  static const String createdAtDESC = "created_at DESC";
  static const String critical = "Critical";
  static const String d10 = "^\\[(\\d+)\\]";
  static const String d11 = "^\\[\\d+\\]\\.?";
  static const String d7 = "^\\[(\\d+)\\]\\.";
  static const String dashboard = "Dashboard";
  static const String date = "Protocol";
  static const String dateTime = "Date & Time";
  static const String datetime = "dateTime";
  static const String datetimeNow =
      "----------------------setUpLogs: Setting up logs..-----------------";
  static const String day = "Day";
  static const String dayMustBeBetween1And31 = "Day must be between 1 and 31";
  static const String ddMMYyyy = "dd/MM/yyyy";
  static const String ddMMYyyyHHMmSs = "dd/MM/yyyy";
  static const String ddMMYyyyHhMmSsA = "dd/MM/yyyy - hh:mm:ss a";
  static const String ddMMYyyyNhhMmSsA2 = "dd/MM/yyyy\\nhh:mm:ss a";
  static const String delayFieldIsFocused = "Delay field is focused";
  static const String delayFieldLostFocus = "Delay field lost focus";
  static const String delayMustBeBetween0And600Seconds =
      "Delay must be between 0 and 600 seconds";
  static const String delayS = "Delay (s)";
  static const String delayed = "Delayed";
  static const String delete = "Delete";
  static const String deleteSite = "Delete site?";
  static const String detectionmode = "zone";
  static const String deviceConnected = "Connecting...";
  static const String deviceIsInBootloaderMode = "Device is in bootloader mode";
  static const String deviceNameIsEmpty = "Device name is empty";
  static const String deviceNotConnectedCannotSendJumpCommand =
      "Device not connected. Cannot send jump command.";
  static const String deviceNotResponding2 = "Device not responding";
  static const String deviceReadyContinuingUpgrade =
      "Device ready. Continuing upgrade...";
  static const String deviceReconnectedContinuingUpgrade =
      "Device reconnected. Continuing upgrade...";
  static const String deviceid = "deviceId";
  static const String devicetext = "productRev";
  static const String diagnostics = "Diagnostics";
  static const String didEachTestPassOrFail = "Did each test pass or fail?";
  static const String disabled = UiStrings.continueButton;
  static const String disconnect = "Disconnect";
  static const String disconnectDevice = "Disconnect device?";
  static const String disconnected = "Disconnected";
  static const String disconnected2 = "Disconnected.";
  static const String doubleKnock = "Double Knock";
  static const String download = "Download";
  static const String downloadCompare = "Download & compare";
  static const String downloadPanelConfiguration =
      "Download panel configuration?";
  static const String downloading = "Downloading...";
  static const String downloadingConfiguration =
      "Applying configuration to panel…";
  static const String duplicateAccessCode = "Duplicate Access Code";
  static const String dynamictext = "Ext. Out";
  static const String e1 = "e1";
  static const String e2 = "e2";
  static const String e3 = "e3";
  static const String earth = "Earth";
  static const String emailSupport = "Email Support";
  static const String emptyExtOutMode = "empty ext out mode";
  static const String emptyInputMode = "empty inputMode";
  static const String emptyRelayMode = "empty relay mode";
  static const String emptySounderGeneralMode = "empty sounder general mode";
  static const String emptyZoneMode = "empty zone mode";
  static const String enable = "Enable";
  static const String enabled = "Enabled";
  static const String enabledBusDetailMayBeIncompleteUsePerBusDownloadOnThe =
      "Enabled-bus detail may be incomplete. Use per-bus download on the "
      "L-Bus screen if needed.";
  static const String enterAValidPanelIDLettersNumbersOr =
      "Enter a valid panel ID (letters, numbers, - or _)";
  static const String enterAccessCode = "Enter Access Code";
  static const String enterBuildingName = "buildingName";
  static const String enterCompanyName = "companyName";
  static const String enterInputText = "Enter Input Text";
  static const String enterInstallerContactNumber = "installerContactNumber";
  static const String enterInstallerEmail = "installerEmail";
  static const String enterInstallerName = "installerName";
  static const String enterPanelID = 'Enter panel ID';
  static const String enterPanelName = 'Enter Panel Name';
  static const String enterRelayText = "Enter Relay Text";
  static const String enterSAQCCRegistrationNumber = "saqccRegNumber";
  static const String enterSiteDescription = "siteDescription";
  static const String enterSiteName = "siteName";
  static const String enterSounderText = "Enter Sounder Text";
  static const String enterZoneText = "Enter Zone Text";
  static const String establishingSecureConnection = "Connecting...";
  static const String evacuation = "Evacuation";
  static const String eventClass = "Event Class:";
  static const String eventDateTimeDESCRetrievedAtDESC =
      "event_date_time DESC, retrieved_at DESC";
  static const String eventLog = "Event Log";
  static const String eventLogRetrievalNFailed2 =
      "Event Log Retrieval\\nFailed!";
  static const String eventReminder = "Event Reminder";
  static const String eventType = "Event";
  static const String eventid = "eventId";
  static const String eventlogscreen = "ScannedScreen";
  static const String export = "Export";
  static const String exportAsPDF = "Export as PDF";
  static const String extOut = "Ext. Out";
  static const String extOut2 = "Ext Out";
  static const String extOutConfig = "Ext Out Config";
  static const String extOutMode = "Ext Out Mode";
  static const String extOutText001 = "EXT-Out-Text------001";
  static const String extSnd1 = "Ext. Snd 1";
  static const String extSnd2 = "Man. Release Snd";
  static const String extSound1ExtSound2ManReleaseSound =
      "Ext Sound 1/Ext Sound 2/Man Release Sound";
  static const String extinguishingOUT = "EXTINGUISHING OUT";
  static const String extinguishingOUTPUT = "EXTINGUISHING OUTPUT";
  static const String extinguishingOutput = "Extinguishing Output";
  static const String fail = "Fail";
  static const String fault = "Normal";
  static const String faultLatching = "Fault Latching";
  static const String faultlatching = "faultLatching";
  static const String fetchingFirmwareUpgradeStatus =
      "Fetching Firmware Upgrade status...";
  static const String filter = "Filter";
  static const String fireSound = "Warble";
  static const String firmwareDate = "Firmware date";
  static const String firmwareTransferFailed = "Firmware transfer failed.";
  static const String firmwareUpdate = "Firmware Update";
  static const String firmwareUpgradeFailed = "Firmware upgrade failed";
  static const String firmwareVersion = "Firmware Version";
  static const String firmwareVersion2 = "Firmware version";
  static const String fixPanelInformationFields =
      "Fix panel information fields";
  static const String fixTheFieldsOnThisStepBeforeContinuing =
      "Fix the fields on this step before continuing";
  static const String frequentlyAskedQuestions = "Frequently Asked Questions";
  static const String from = "From";
  static const String fromTheDeviceButTheyAreNotAssociatedWithAnySiteNN2 =
      " from the device, but they are not associated with any site.\\n\\n";
  static const String function = "Function";
  static const String function1A = "Function 3B";
  static const String functionA = "Function A";
  static const String functionno = "functionNo";
  static const String fwUpgrade = "FW Upgrade";
  static const String general = "Delay";
  static const String general2 = "general.";
  static const String generalEnabled = "sounder";
  static const String generalMode = "General Mode";
  static const String generalModule = "General Module";
  static const String generalSettings = "General Settings";
  static const String goingBackWillDisconnectTheDeviceAreYouSure =
      "Going back will disconnect the device. Are you sure?";
  static const String group = "Group";
  static const String groupA = "Group A";
  static const String hardware = UiStrings.lBusDateLabel;
  static const String hardwareVersion = "Hardware Version";
  static const String hardwareVersion2 = "Hardware version";
  static const String help = "Help";
  static const String helpCommunityForumUrl = "https://technoswitch.com/community";
  static const String helpSupport = "Help & Support";
  static const String helpUserManualUrl = "https://technoswitch.com/manual";
  static const String helpVideoTutorialsUrl = "https://technoswitch.com/tutorials";
  static const String high = "High";
  static const String hold = "Hold";
  static const String holdAction = "Warble";
  static const String holdCount = "Hold / Count";
  static const String holdaction = "holdAction";
  static const String holdinput = "zone3";
  static const String holdmode = "holdMode";
  static const String home = "Home";
  static const String horn = "Horn";
  static const String hour = "Hour";
  static const String hourFieldIsFocused = "Hour field is focused";
  static const String hourFieldLostFocus = "Hour field lost focus";
  static const String hourMustBeBetween0And23 = "Hour must be between 0 and 23";
  static const String howCanIRetrieveProjectLogs =
      "You can retrieve project logs by tapping the \"Retrieve Log\" quick link on the home screen. Select your project and choose the date range for the logs you need.";
  static const String howDoICreateANewProject =
      "To create a new project, tap on the \"New Project\" quick link on the home screen. Follow the step-by-step wizard to set up your project details.";
  static const String id = "ID";
  static const String id2 = "log_retrievals";
  static const String idLED = "ID LED";
  static const String identifier = "Text";
  static const String idled = "idLed";
  static const String ifYouSkipThisStepTheLogsWillBeLost =
      "If you skip this step, the logs will be lost.";
  static const String immediate = PanelValues.zoneModeImmediate;
  static const String initiating = "Verifying access";
  static const String input = "Output";
  static const String input1 = "Disable";
  static const String inputMode = "Input Mode";
  static const String inputModeConfiguration = "Input";
  static const String inputText = "Input Text";
  static const String inputs = "Inputs";
  static const String inputs2 = "INPUTS";
  static const String inputtext = "inputText";
  static const String installerContactNumber = "Installer Contact Number";
  static const String installerEmail = "Installer Email";
  static const String installerName = "Installer Name";
  static const String installeremail = "installerEmail";
  static const String invalidADCResponse = "Invalid ADC response";
  static const String invalidBINFileTooSmallNeedAtLeast =
      "Invalid BIN file (too small, need at least ";
  static const String invalidBINFileHardwareMismatch =
      "Invalid bin file, hardware versions don't match";
  static const String invalidNumber = "Invalid number";
  static const String invalidPayload = "Invalid payload";
  static const String inverted = "Inverted";
  static const String inverterTest = "Inverter Test";
  static const String isMTL5561 = "detectionMode";
  static const String issolar = "isSolar";
  static const String item = "Tested At";
  static const String joinOurCommunityDiscussions =
      "Join our community discussions";
  static const String keyboard = "Keyboard";
  static const String lBUS = "L-BUS";
  static const String lBUS1 = "L-BUS 1";
  static const String lBUS2 = "L-BUS 2";
  static const String lBus = "L-Bus";
  static const String lBusCommsFaultOnBusEsLBusCommsFaultBusNumbersJoin =
      "per-bus download if needed.";
  static const String lBusConfiguration = "L-Bus Configuration";
  static const String lBusDeviceText2 = "L-Bus Device Text";
  static const String lBusDevices = "L-Bus Devices";
  static const String lBusMode = "L-Bus Mode";
  static const String lBusNo = "L-Bus No";
  static const String lastConnectedDESCCreatedAtDESC =
      "last_connected DESC, created_at DESC";
  static const String lbusno = "lBusNo";
  static const String levelTimeout = "Timer Settings";
  static const String listLengthDiffers = "List length differs";
  static const String liveDataStreamingFromTheDeviceHasBeenStopped =
      "Live data streaming from the device has been stopped.";
  static const String liveDiagnosticsStopped = "Live Diagnostics Stopped";
  static const String liveEvents = "Live Events";
  static const String logENTRIES = "LOG ENTRIES";
  static const String logHistory = "Log History";
  static const String logRetrievalFailed = "Log Retrieval Failed";
  static const String logRetrievalHistory = "Log Retrieval History";
  static const String logRetrievalReport = "Log Retrieval Report";
  static const String logView = "Log View";
  static const String logdata = "logData";
  static const String lvlTimeOutFieldIsFocused =
      "LVL Time-out field is focused";
  static const String lvlTimeOutFieldLostFocus =
      "LVL Time-out field lost focus";
  static const String lvlTimeOutMustBeBetween30And300Seconds =
      "LVL Time-out must be between 30 and 300 seconds";
  static const String lvlTimeOutS = "LVL Time-out (s)";
  static const String lvltimeout = "faultLatching";
  static const String macaddress = "macAddress";
  static const String makeSureYourSolarDevicesAreConnectedViaUSBAndPoweredOn =
      "Make sure Bluetooth is enabled and solar devices are in pairing mode.";
  static const String manFieldIsFocused = "Man field is focused";
  static const String manFieldLostFocus = "Man field lost focus";
  static const String manualCountdown = "Manual Countdown";
  static const String manufacturerdata = "manufacturerData";
  static const String manufacturingDate = "Manufacturing Date";
  static const String maxConnectionRetriesReached =
      "Max Connection Retries Reached!";
  static const String minute = "Minute";
  static const String minuteFieldIsFocused = "Minute field is focused";
  static const String minuteFieldLostFocus = "Minute field lost focus";
  static const String minuteMustBeBetween0And59 =
      "Minute must be between 0 and 59";
  static const String mmmDY = "MMM d, y";
  static const String mode = "Mode";
  static const String module = "Module";
  static const String moduleInfo = "Module Info";
  static const String moduleno = "moduleNo";
  static const String month = "Month";
  static const String monthFieldIsFocused = "Month field is focused";
  static const String monthFieldLostFocus = "Month field lost focus";
  static const String monthMustBeBetween1And12 =
      "Month must be between 1 and 12";
  static const String mustBe0ForImmediateNormalMode =
      "Must be 0 for Immediate/Normal mode";
  static const String mustBe30ForConfirmedMode =
      "Must be 30 for Confirmed mode";
  static const String mustBeBetween10And60ForVerifiedMode =
      "Must be between 10 and 60 for Verified mode";
  static const String nA = "N/A";
  static const String name = "Name";
  static const String needImmediateHelp = "Need Immediate Help?";
  static const String newSite = "New Site";
  static const String no = "No";
  static const String noConfigurationIsSavedInTheAppForThisDevice =
      "No configuration is saved in the app for this device. "
      "Panel data was downloaded successfully. Update the app to "
      "save it locally — there is nothing in the app to send to "
      "the panel.";
  static const String noConnectedPanel = "No connected panel";
  static const String noDeviceNameStoredForReconnection =
      "No device name stored for reconnection";
  static const String noFieldLevelDetailAvailable =
      "No field-level detail available.";
  static const String noInformationAvailable = "No information available";
  static const String noLogEntriesAvailable = "No log entries available";
  static const String noLogHistory = "No Log History";
  static const String noLogsYet = "No logs yet";
  static const String noPacketsPrepared = "No packets prepared";
  static const String noPacketsToProcessPleaseReUploadTheFile =
      "No packets to process. Please re-upload the file.";
  static const String noPanelsYet = "No Panels Yet";
  static const String noRelayTestResultsRecordedForThisDevice =
      "No relay test results recorded for this device.";
  static const String noSiteSelectedPleaseSelectOrCreateASite =
      "No site selected. Please select or create a site.";
  static const String noSitesYet = "No Sites Yet";
  static const String noSounderTestResultsRecordedForThisDevice =
      "No sounder test results recorded for this device.";
  static const String noWalkTestResultsRecordedForThisDevice =
      "No walk test results recorded for this device.";
  static const String none = PanelValues.zoneModeNone;
  static const String normal = PanelValues.zoneModeNormal;
  static const String notDefined = "Aerosol";
  static const String notEnoughADCValues = "Not enough ADC values";
  static const String notUsed = "Not Used";
  static const String number = "Number";
  static const String numberCannotBeEmpty = "Number cannot be empty";
  static const String off = "Off";
  static const String offlineprovisioned = "panelId";
  static const String ok = "OK";
  static const String ok2 = "Ok";
  static const String on = "On";
  static const String onlyInApp2 = "Only in app";
  static const String onlyOnPanel2 = "Only on panel";
  static const String openSite = "Open Site";
  static const String operationTimedOutStayCloseToTheDeviceAndTryAgain =
      "Operation timed out. Stay close to the device and try again.";
  static const String oryx202 = "ORYX202";
  static const String oryx204 = "ORYX204";
  static const String oryx208 = "ORYX208";
  static const String other = "Other";
  static const String output = "Output";
  static const String outputText = "Output Text";
  static const String outputtext = "dynamicText";
  static const String p1 = "P1";
  static const String panel = "Panel";
  static const String panel2 = " · app ";
  static const String panelActions = "Panel Actions";
  static const String panelAlreadyAssigned = "Panel already assigned";
  static const String panelAlreadyOnASite = "Panel already on a site";
  static const String panelConfigurationTool = "Panel Configuration Tool";
  static const String panelDataDiffersFromAppCache =
      "Panel data differs from app cache.";
  static const String panelDateTime = "14/05/2025 - 11:32:03";
  static const String panelIDIsMissing = "Panel ID is missing";
  static const String panelINFO = "PANEL INFO";
  static const String panelId = "panel_id = ?";
  static const String panelInfo = "Panel Info";
  static const String panelInformation = "Panel Information";
  static const String panelIsAlreadyAssignedToAnotherSite =
      "Panel is already assigned to another site";
  static const String panelName = "Panel Name";
  static const String panelName2 = "panel_name = ?";
  static const String panelNo = "Panel No";
  static const String panelSelection = "Panel Selection";
  static const String panelType = "Panel Type";
  static const String panelid = "panelName";
  static const String panelname = "panelName";
  static const String panelno = "panelNo";
  static const String panels = "Panels";
  static const String panelsIdentified = "Panels Identified";
  static const String paneltype = "panelType";
  static const String pass = "Pass";
  static const String peripheralOverview = "Peripheral Overview";
  static const String peripheralid = "peripheralId";
  static const String pleaseFillInAllRequiredFields =
      "Please fill in all required fields";
  static const String pleaseFixTheSiteFormStep1 =
      "Please fix the site form (step 1)";
  static const String pleaseScanAgainAndConnectToTheDevice =
      "Please scan again and connect to the device";
  static const String pleaseScanAgainAndReconnect =
      "Please scan again and reconnect.";
  static const String pleaseTryConnectingAgain = "Please try connecting again";
  static const String pleaseWaitTillScanIdentifiesTheDevices =
      "Please wait till scan identifies the devices....";
  static const String pleaseWaitWhileWeConnectToDeviceName = "Preparing...";
  static const String power = "Power";
  static const String pragmaForeignKeysON = "PRAGMA foreign_keys = ON";
  static const String preparingDashboard = "Preparing dashboard...";
  static const String preparingFirmwareUpgrade =
      "Preparing Firmware Upgrade...";
  static const String preparingToNavigate = "Preparing to navigate...";
  static const String processing = "Fetching...";
  static const String product = "Product";
  static const String productId = "Product Id";
  static const String productName = "Product Name";
  static const String productRev2 = "Product Rev.";
  static const String productname = "connectionType";
  static const String productrev = "productRev";
  static const String progIn = "Hold In";
  static const String proginput = "progInput";
  static const String programming = "Programming";
  static const String programmingGroup = "Programming Group";
  static const String projectConfigurationReport =
      "Project Configuration Report";
  static const String projectDashboard = "Project Dashboard";
  static const String projectINFO = "PROJECT INFO";
  static const String projectSettings = "Project Settings";
  static const String protocol = "Protocol";
  static const String protocolNo = "Protocol No";
  static const String protocolVersion = "Protocol version";
  static const String pulsing1sON4sOFF = "Warble";
  static const String quickLinks = "Quick Links";
  static const String r1 = "r1";
  static const String r2 = "r2";
  static const String r3 = "r3";
  static const String radio = "Radio";
  static const String radioConfiguration = "Radio Configuration";
  static const String ready = "Ready";
  static const String recentSites = "Recent Sites";
  static const String reconnecting = "Reconnecting...";
  static const String relay = "Relay";
  static const String relay1Test = "Relay 1 Test";
  static const String relay2Test = "Relay 2 Test";
  static const String relay3Test = "Relay 3 Test";
  static const String relayMode = "Relay Mode";
  static const String relayModeConfiguration = "Relay Mode Configuration";
  static const String relayTESTRESULTS = "RELAY TEST RESULTS";
  static const String relayTest = "Relay Test";
  static const String relayText = "Relay Text";
  static const String relayfunction = "relayFunction";
  static const String relaygroup = "relayGroup";
  static const String relays = "Relays";
  static const String relays2 = "RELAYS";
  static const String relaystate = "relayState";
  static const String relaytest = "relayTest";
  static const String relaytext = "relayText";
  static const String release = "Release";
  static const String releaseAction = "Release Action";
  static const String releaseFieldIsFocused = "Release field is focused";
  static const String releaseFieldLostFocus = "Release field lost focus";
  static const String releaseTime = "Release Time";
  static const String releaseTimeS = "Release Time (s)";
  static const String releaseaction = "releaseAction";
  static const String releasetime = "ext_out";
  static const String reminder = "Reminder";
  static const String remove = "Remove";
  static const String removePanel = "Remove panel?";
  static const String removePanelPanelPanelNamePanelPanelId = "from this site?";
  static const String reportINFO = "REPORT INFO";
  static const String reset = "Reset";
  static const String resetDelayFieldIsFocused = "Reset Delay field is focused";
  static const String resetDelayFieldLostFocus = "Reset Delay field lost focus";
  static const String resetDelayS = "Reset Delay (s)";
  static const String resetInCount = "Reset in Count";
  static const String resetLevel2 = "Reset Level";
  static const String resetallowed = "resetAllowed";
  static const String resetlevel = "Access Level 3";
  static const String result = "Result";
  static const String retrievalDateDESC = "retrieval_date DESC";
  static const String retrievalId = "retrieval_id = ?";
  static const String retrievalNCompleted2 = "Retrieval\\nCompleted!";
  static const String retrieveLog = "Retrieve Log";
  static const String retrievingLogs = "Retrieving Logs...";
  static const String revision = "Revision";
  static const String rhino103 = "RHINO103";
  static const String rhino103r = "Rhino103R";
  static const String rhino2008 = "RHINO2008";
  static const String rhino203 = "RHINO203";
  static const String s09 = "[^0-9]";
  static const String s098 = "0.98";
  static const String s1 = "e3";
  static const String s10Sec = "10 Sec";
  static const String s123 = "general";
  static const String s13092025 = "13/09/2025";
  static const String s15Sec = "15 Sec";
  static const String s18001234567 = "+1 (800) 123-4567";
  static const String s1Channel = "1 channel";
  static const String s2 = "s2";
  static const String s3 = "s3";
  static const String s300Sec = "300 Sec";
  static const String s300Seconds = "300 Seconds";
  static const String s30Sec = "30 Sec";
  static const String s3Sec = "3 Sec";
  static const String s69 = "^[6-9]";
  static const String saqccRegistrationNumber = "SAQCC Registration Number";
  static const String saqccregnumber = "saqccRegNumber";
  static const String save = "Save";
  static const String scanresult = "ScanResult";
  static const String search = "Search...";
  static const String seconds = "Seconds";
  static const String sectionRoot = "(section root)";
  static const String sectionsThatDiffer = "Sections that differ";
  static const String selectASite = "Select a site";
  static const String selectAnotherLBusToViewItsDifferences =
      "Select another L-Bus to view its differences.";
  static const String selectCOUNTFROMLogRetrievalsWHERESiteId =
      "SELECT COUNT(*) FROM log_retrievals WHERE site_id = ?";
  static const String selectCOUNTFROMLogs = "SELECT COUNT(*) FROM logs";
  static const String selectCOUNTFROMLogsWHERESiteIdISNULL =
      "SELECT COUNT(*) FROM logs WHERE site_id IS NULL";
  static const String selectCOUNTFROMSites = "SELECT COUNT(*) FROM sites";
  static const String selectDate = "Select Date";
  static const String selectTheTypeOfDevicesYouWantToScanFor =
      "Select the type of devices you want to scan for";
  static const String server = "Server";
  static const String service = "Service";
  static const String serviceDue = "Service Due";
  static const String serviceDueConfiguration = "Service Due Configuration";
  static const String serviceDueMode = "Service Due Mode";
  static const String serviceDueReminder = "Service Due Reminder";
  static const String settings = "Settings";
  static const String silenceBuzzer = "Silence Buzzer";
  static const String silenceBuzzerLevel2 = "Silence Buzzer Level";
  static const String silenceSoundersLevel2 = "Silence Sounders Level";
  static const String silencebuzzerlevel = "silenceBuzzerLevel";
  static const String silencesounderslevel = "faultLatching";
  static const String siteCreatedButMissingId = "Site created but missing id";
  static const String siteCreatedSuccessfully = "Site created successfully";
  static const String siteCreation = "Site Creation";
  static const String siteDescription = "Site Description";
  static const String siteDetails = "Site Details";
  static const String siteFoundForThisPanel = "Site found for this panel";
  static const String siteId = "site_id = ?";
  static const String siteIdANDRetrievedAtANDRetrievedAt =
      "site_id = ? AND retrieved_at >= ? AND retrieved_at < ?";
  static const String siteIdISNULL = DbSql.lastConnectedThenCreatedAtDesc;
  static const String siteIdISNULLANDRetrievedAt =
      "site_id IS NULL AND retrieved_at < ?";
  static const String siteInformation = "Site Information";
  static const String siteName = UiStrings.siteNameLabel;
  static const String siteNameLIKEORInstallerNameLIKEORCompanyNameLIKE =
      DbSql.sitesOrderByCreatedAtDesc;
  static const String siteReadyOpeningDashboard =
      "Site ready - opening dashboard";
  static const String sitename = "siteName";
  static const String skip = "Skip";
  static const String skipConnectionEnterPanelIDManually =
      "Skip connection — enter panel ID manually";
  static const String snd1 = "SND 3";
  static const String solar = "SOLAR";
  static const String solarMode = "Solar Mode";
  static const String solarPanel = "Solar Panel";
  static const String solarPanelTest = "Solar Panel Test";
  static const String sounder = "Sounder";
  static const String sounder1 = "sounder1";
  static const String sounder1Test = "Sounder 1 Test";
  static const String sounder2 = "sounder2";
  static const String sounder2Test = "Sounder 2 Test";
  static const String sounder3 = "sounder3";
  static const String sounder3Test = "Sounder 3 Test";
  static const String sounder4 = "SOUNDER";
  static const String sounderDelay = "Sounder Delay";
  static const String sounderExtOut = "Sounder Ext. Out";
  static const String sounderFunction = "Sounder Function";
  static const String sounderGeneralDelay = "Sounder General Delay";
  static const String sounderGroup = "Sounder Group";
  static const String sounderMode = "Sounder Mode";
  static const String sounderModeConfiguration = "Sounder Mode Configuration";
  static const String sounderOutput = "Sounder Output";
  static const String sounderSettings = "Sounder Settings";
  static const String sounderTESTRESULTS = "SOUNDER TEST RESULTS";
  static const String sounderTest = "Sounder Test";
  static const String sounderText = "Sounder Text";
  static const String sounderTone = "Sounder Tone";
  static const String sounderType = "Sounder Type";
  static const String sounderZone = "Sounder Zone";
  static const String sounderfunction = "sounderFunction";
  static const String soundergroup = "sounderGroup";
  static const String sounders = "Sounders";
  static const String sounderstate = "sounderState";
  static const String soundertest = "sounderTest";
  static const String soundertext = "sounderText";
  static const String soundertype = "sounderType";
  static const String status = "Source";
  static const String status2 = "Status:";
  static const String status3 = "Status : ";
  static const String status4 = "status : ";
  static const String step = "Step";
  static const String stop = "Stop";
  static const String stopLogRetrieval = "Stop Log Retrieval";
  static const String stopScanning = "Stop Scanning";
  static const String str6b6dfb41 = " • ";
  static const String str99914b93 = "device_info";
  static const String strb411bc68 = " *";
  static const String strca4d661a = "••••••••";
  static const String strf910c9ffFailed = UiStrings.firmwareUpgradeSuccessTitle;
  static const String subtype = "subType";
  static const String success = "Success";
  static const String supervisory = "Supervisory";
  static const String supplyFault = "Supply Fault";
  static const String supportTechnoswitchCom = "support@technoswitch.com";
  static const String swipeOrTapATabToReviewPanelVsAppDifferences =
      "Swipe or tap a tab to review panel vs app differences.";
  static const String systemTest = "System Test";
  static const String tapOnUpdateToUpdateTheFirmware =
      "Tap on Update to update the firmware.";
  static const String tapToConnect = "Tap to connect";
  static const String tapToScanAgain = "Tap to Scan Again";
  static const String technoswitch = "TECHNOSWITCH_";
  static const String test = "Test";
  static const String testMode = "Test Mode";
  static const String testedat = "result";
  static const String text = "Text";
  static const String textinputHide = "TextInput.hide";
  static const String theBootloaderFileOnTheDeviceIsCorrupted =
      "The bootloader file on the device is corrupted. "
      "Tap on Update to update the firmware.";
  static const String thePanelDidNotRespondPleaseScanAndConnectAgain =
      "The panel did not respond. Please scan and connect again.";
  static const String thereWasAnErrorDownloading =
      "There was an error downloading";
  static const String thisWillRemoveAllEntriesFromTheListThisCannotBeUndone =
      "This will remove all entries from the list. This cannot be undone.";
  static const String timerSettings = "Timer Settings";
  static const String to = "To";
  static const String totalretrievals = "lastRetrieval";
  static const String turnOnBluetooth = "Turn on Bluetooth";
  static const String type = "Type";
  static const String typeA = "Type A";
  static const String unableToOpenThisLogSessionMissingId =
      "Unable to open this log session (missing id).";
  static const String unableToReconnectDeviceNameNotFound =
      "Unable to reconnect: Device name not found";
  static const String unassigned = "Unassigned";
  static const String unknownDevice = "Unknown Device";
  static const String updateApp = "Update App";
  static const String updatePanel = "Update Panel";
  static const String updatePanelSettings = "Update panel settings";
  static const String upload = "Upload";
  static const String uploadSuccessful = "Upload Successful";
  static const String uploadToPanel = "Upload to Panel";
  static const String usb = "USB_";
  static const String usbSerialDevices = "Scan for connected USB solar devices";
  static const String usbSolarDevice = "USB Solar Device";
  static const String useMobileDateTime = "Use Mobile Date & Time";
  static const String usemobiletime = "useMobileTime";
  static const String userManual = "User Manual";
  static const String testingVersion = "v0.0.49 -- testing version";
  static const String validating = "Validating";
  static const String validating2 = "Validating...";
  static const String verifyingAccess = "Verifying access";
  static const String vaux = "EXT";
  static const String verificationTimeS = "Verification Time (s)";
  static const String verificationtime = "verificationTime";
  static const String verified = "Verified";
  static const String vidVidPIDPid = "USB Device";
  static const String videoTutorials = "Video Tutorials";
  static const String viewAll = "View All";
  static const String viewSiteDetails = "View Site Details";
  static const String walkTESTRESULTS = "WALK TEST RESULTS";
  static const String walkTest = "Walk Test";
  static const String walkTestResults = "Sounder Test Results";
  static const String watchStepByStepVideoGuides =
      "Watch step-by-step video guides";
  static const String wrongPanelType = "Wrong panel type";
  static const String year = "Year";
  static const String yearFieldIsFocused = "Year field is focused";
  static const String yearFieldLostFocus = "Year field lost focus";
  static const String yearMustBeBetween2010And9999 =
      "Year must be between 2010 and 9999";
  static const String zone = "Zone";
  static const String yesStop = "Yes, Stop";
  static const String youRetrieved = "You retrieved ";
  static const String yourSavedSetupHasBeenAppliedToThePanel =
      "Your saved setup has been applied to the panel.";
  static const String z1 = "z1";
  static const String z1AndZ2 = "Any 1 zone";
  static const String z2 = "z2";
  static const String z3 = "z3";
  static const String zone1 = "Zone 3";
  static const String zone1Test = "Zone 1 Test";
  static const String zone2Test = "Zone 2 Test";
  static const String zone3Test = "Zone 3 Test";
  static const String zoneConfiguration = "Zone Configuration";
  static const String zoneMode = "Zone Mode";
  static const String zoneMustBeBetween1And3 = "Zone must be between 1 and 3";
  static const String zoneSettings = "Zone Settings";
  static const String zoneTest = "Zone Test";
  static const String zoneText = "Zone Text";
  static const String zoneType = "Zone Type";
  static const String zoneVerificationTime = "Zone Verification Time";
  static const String zonemode = "zoneMode";
  static const String zones = "Zones";
  static const String zones2 = "ZONES";
  static const String zonestate = "zoneState";
  static const String zonetest = "zoneTest";
  static const String zonetext = "zoneText";
  static const String zonetype = "zoneType";
  static const String zoneverificationtime = "zoneVerificationTime";
  static const String accessLevel3 = "Access Level 3";
  static const String aerosol = "Aerosol";
  static const String alert = "Alert";
  static const String any1Zone = "Any 1 zone";
  static const String any2Zones = "Any 2 zones";
  static const String app2 = " · app ";
  static const String applyingConfigurationToPanel =
      "Applying configuration to panel…";
  static const String authorisedUser = "Authorised User";
  static const String averagelogsperretrieval = "averageLogsPerRetrieval";
  static const String bell = "Bell";
  static const String bluenrgMB = "BLUENRG-MB";
  static const String bluetooth2 = "BLUETOOTH_";
  static const String buildingname = "buildingName";
  static const String chime = "Chime";
  static const String classLabel = "Class";
  static const String commissioning = "Commissioning";
  static const String companyname = "companyName";
  static const String contact = "Contact";
  static const String controlsEnabled = "Controls Enabled";
  static const String countdownManMustBeBetween0And60 =
      "Countdown Man must be between 0 and 60";
  static const String delay = "Delay";
  static const String devicename = "deviceName";
  static const String dipMode = "DIP Mode";
  static const String disable = "Disable";
  static const String disablement = "Disablement";
  static const String doYouWantToUpdateTheFirmware =
      "Do you want to update the firmware?";
  static const String encryptingAndAuthenticating =
      "Encrypting and authenticating...";
  static const String ext = "EXT";
  static const String extAgentReleased = "Ext. Agent Released";
  static const String extRelease = "Ext. Release";
  static const String extinguish = "Extinguish";
  static const String extinguishingOutSettings = "Extinguishing out Settings";
  static const String extnlControlsEnabled = "Extnl. Controls Enabled";
  static const String extnlDisableGas = "Extnl. Disable Gas";
  static const String extnlExtFault = "Extnl. Ext. Fault";
  static const String extnlFault = "Extnl. Fault";
  static const String extnlSupervisory = "Extnl. Supervisory";
  static const String extnlSupplyFault = "Extnl. Supply Fault";
  static const String faultLatching2 = "Fault latching";
  static const String fetching = "Fetching...";
  static const String finish = "Finish";
  static const String fire = "Fire";
  static const String fireSnd = "Fire Snd";
  static const String firmware = "Firmware";
  static const String firmwareUpgrade = "Firmware Upgrade";
  static const String firstretrieval = "firstRetrieval";
  static const String formatDateTimeNowPdf = ").format(DateTime.now())}.pdf";
  static const String formatLastLogDate = ").format(lastLogDate)}";
  static const String function1B = "Function 1B";
  static const String function2A = "Function 2A";
  static const String function2B = "Function 2B";
  static const String function3A = "Function 3A";
  static const String function3B = "Function 3B";
  static const String functionB = "Function B";
  static const String functionC = "Function C";
  static const String functionD = "Function D";
  static const String groupB = "Group B";
  static const String groupC = "Group C";
  static const String groupD = "Group D";
  static const String holdIn = "Hold In";
  static const String inputSettings = "Input Settings";
  static const String installercontactnumber = "installerContactNumber";
  static const String installername = "installerName";
  static const String isMTL5525 = "IS (MTL5525)";
  static const String lBusDeviceIdx = "access_code";
  static const String lBusScreenIfNeeded = "L-Bus screen if needed.";
  static const String lBusSettings = "L-Bus Settings";
  static const String lastretrieval = "lastRetrieval";
  static const String levelTimeout2 = "Level timeout";
  static const String liveDataIsBeingStreamedFromTheDeviceInRealTime =
      "Diagnostics";
  static const String logretrievalloadingscreen = "LogRetrievalLoadingScreen";
  static const String manReleaseSnd = "Man. Release Snd";
  static const String manual = "Manual";
  static const String manualMode = "Manual Mode";
  static const String manualRelease = "Manual Release";
  static const String manualTrigger = "Manual Trigger";
  static const String metron = "Metron";
  static const String moduleNo = "Module No";
  static const String mute = "Mute";
  static const String onyx202 = "ONYX202";
  static const String onyx204 = "ONYX204";
  static const String onyx205 = "ONYX205";
  static const String onyx206 = "ONYX206";
  static const String p2 = "P2";
  static const String p3 = "P3";
  static const String p4 = "P4";
  static const String panelDataWasDownloadedSuccessfullyUpdateTheAppTo =
      "Panel data was downloaded successfully. Update the app to ";
  static const String panelID = "Panel ID";
  static const String panelSerialNumber = "Panel Serial Number";
  static const String panelSettings = "Panel Settings";
  static const String pleaseEnterAValidEmailAddress =
      "Please enter a valid email address";
  static const String preparing = "Preparing...";
  static const String progIN1 = "PROG IN 1";
  static const String projectdashboardscreen = "ProjectDashboardScreen";
  static const String pulse100msOn = "Pulse 100ms On";
  static const String pulse1sOn = "Pulse 1s On";
  static const String pulse300msOn = "Pulse 300ms On";
  static const String pulse5sOn = "Pulse 5s On";
  static const String pulse600msOn = "Pulse 600ms On";
  static const String pulsing100msOn500msOff = "Pulsing 100ms On, 500ms Off";
  static const String pulsing1sOn1sOff = "Pulsing 1s on, 1s off";
  static const String pulsing1sOn4sOff = "Pulsing 1s on, 4s off";
  static const String pulsing1sOn5sOff = "Pulsing 1s On, 5s Off";
  static const String pulsing2sON2sOFF = "Pulsing 2s ON, 2s OFF";
  static const String pulsing2sOn500msOff = "Pulsing 2s on, 500ms off";
  static const String pulsing300msOn15sOff = "Pulsing 300ms On, 1.5s Off";
  static const String pulsing600msOn3sOff = "Pulsing 600ms On, 3s Off";
  static const String relaySettings = "Relay Settings";
  static const String relayTestResults = "Relay Test Results";
  static const String releaseHold = "Release Hold";
  static const String releaseInitiated = "Release Initiated";
  static const String releaseTimeMustBeBetween10And300 =
      "Release Time must be between 10 and 300";
  static const String replace = "Replace";
  static const String resetDelayMustBeBetween0And1800 =
      "Reset Delay must be between 0 and 1800";
  static const String resetLevel = "Reset level";
  static const String resetdelay = "resetDelay";
  static const String restart = "Restart";
  static const String retrievedAtDESC = "retrieved_at DESC";
  static const String rowIdx = "l_bus";
  static const String s1000Sec = "1000 Sec";
  static const String s1000Seconds = "1000 Seconds";
  static const String s1200Sec = "1200 Sec";
  static const String s13052025103102 = "13/05/2025 - 10:31:02";
  static const String s14052025113203 = "14/05/2025 - 11:32:03";
  static const String s14092025 = "14/09/2025";
  static const String s15092025 = "15/09/2025";
  static const String s20Sec = "20 Sec";
  static const String s45Sec = "45 Sec";
  static const String s500Sec = "500 Sec";
  static const String s500Seconds = "500 Seconds";
  static const String s5Sec = "5 Sec";
  static const String s600Sec = "600 Sec";
  static const String s60Sec = "60 Sec";
  static const String s900Sec = "900 Sec";
  static const String s90Sec = "90 Sec";
  static const String saqccNo = "SAQCC No";
  static const String saqccRegistrationNumberIsRequired =
      "SAQCC registration number is required";
  static const String saveItLocallyThereIsNothingInTheAppToSendTo =
      "save it locally — there is nothing in the app to send to ";
  static const String savedInThisAppForThisDevice =
      "saved in this app for this device.";
  static const String scanForConnectedUSBSolarDevices =
      "Scan for connected USB solar devices";
  static const String scanForNearbyBluetoothSolarDevices =
      "Scan for nearby Bluetooth solar devices";
  static const String scannedscreen = "ScannedScreen";
  static const String second = "Second";
  static const String serviceDate = "Service Date";
  static const String silenceAlarm = "Silence Alarm";
  static const String silenceBuzzerLevel = "Silence buzzer level";
  static const String silenceSoundersLevel = "Silence sounders level";
  static const String singleKnock = "Single Knock";
  static const String siren = "Siren";
  static const String siteNameIsRequired = "Site name is required";
  static const String sitedescription = "siteDescription";
  static const String snd2 = "SND 2";
  static const String snd3 = "SND 3";
  static const String solenoid = "Solenoid";
  static const String soundAlarm = "Sound Alarm";
  static const String sounderActivated = "Sounder Activated";
  static const String sounderDisabled = "Sounder Disabled";
  static const String sounderFault = "Sounder Fault";
  static const String sounderSilenced = "Sounder Silenced";
  static const String sounderTestResults = "Sounder Test Results";
  static const String source = "Source";
  static const String start = "Start";
  static const String stra106c817 = ")}";
  static const String subType = "Sub Type";
  static const String suspend = "Suspend";
  static const String testedAt = "Tested At";
  static const String testmodescreen = "TestModeScreen";
  static const String theMessageHasBeenSuccessfullyDownloadedFromTheDevice =
      "Live data is being streamed from the device in real time.";
  static const String thePanel = "the panel.";
  static const String thisSection = "This section";
  static const String totallogs = "totalLogs";
  static const String typeB = "Type B";
  static const String typeC = "Type C";
  static const String unableToDeletePanel = "Unable to delete panel";
  static const String unableToDeleteSite = "Unable to delete site";
  static const String untrainedUser = "Untrained User";
  static const String validated = "Validated";
  static const String vin = "Vin";
  static const String warble = "Warble";
  static const String z12 = "Z1";
  static const String z1AndZ2AndZ3 = "Z1 and Z2 and Z3";
  static const String z1AndZ3 = "Z1 and Z3";
  static const String z22 = "Z2";
  static const String z2AndZ3 = "Z2 and Z3";
  static const String z32 = "Z3";
  static const String zone12 = "zone1";
  static const String zone2 = "zone2";
  static const String zone22 = "Zone 2";
  static const String zone3 = "zone3";
  static const String zone32 = "Zone 3";

  static const String deviceConnectedTitle = "Device Connected!";
  static const String pleaseWaitWhileWeConnectToPrefix =
      "Please wait while we connect to ";
  static const String essentialStepConnectViaBluetooth =
      "Ensure the device is connected via Bluetooth";
  static const String essentialStepKeepPoweredOn =
      "Keep the device powered on throughout the upgrade";
  static const String essentialStepDoNotDisconnect =
      "Do not disconnect or turn off the device during upgrade";
  static const String essentialStepCloseOtherApps =
      "Close other apps that might interfere with Bluetooth";
  static const String essentialStepsBeforeFirmwareUpgrade =
      "Essential Steps Before Firmware Upgrade";
  static const String chooseFirmwareType = "Choose Firmware Type";
  static const String mainPanelFirmware = "Main Panel Firmware";
  static const String bleChipFirmware = "BLE Chip Firmware";
  static const String upgradeMainPanelFirmwareDescription =
      "Upgrade the main panel firmware";
  static const String upgradeBleChipFirmwareDescription =
      "Upgrade the Bluetooth chip firmware";
  static const String uploadFirmwareFile = "Upload Firmware File";
  static const String tapToSelectFirmwareFile = "Tap to select firmware file";
  static const String fileDetails = "File Details";
  static const String fileName = "File Name";
  static const String fileSize = "File Size";
  static const String firmwareTypeLabel = "Firmware Type";
  static const String buildDate = "Build date";
  static const String expectedCrc = "Expected CRC";
  static const String calculatedCrc = "Calculated CRC";
  static const String statusLabel = "Status";
  static const String validLabel = "Valid";
  static const String invalidLabel = "Invalid";
  static const String fileCrcValidationFailedSelectValidFile =
      "File CRC validation failed. Please select a valid firmware file.";
  static const String pleaseWaitWhileFirmwareUpgraded =
      "Please wait while the firmware is being upgraded. Do not disconnect the device.";
  static const String processingLabel = "Processing...";
  static const String failedLabel = "Failed";
  static const String doneLabel = "Done";
  static const String validatingFirmwareUpgradeSuccess =
      "Validating firmware upgrade success...";
  static const String firmwareUpgradeCompletedSuccessfully =
      "Firmware upgrade completed successfully!";
  static const String failedToReconnectToDevicePrefix =
      "Failed to reconnect to device: ";
  static const String unableToDetermineUpgradeStatus =
      "Unable to determine upgrade status";
  static const String reconnectionErrorPrefix = "Reconnection error: ";
  static const String errorSelectingFilePrefix = "Error selecting file: ";
  static const String noFileSelectedPleaseUploadAgain =
      "No file selected. Please upload again.";
  static const String crcValidationFailed = "CRC validation failed.";
  static const String deviceHardwareFirmwareCouldNotBeRead =
      "Device hardware and firmware versions could not be read from "
      "Bluetooth. Do you still want to update?";
  static const String firmwareAlreadyUpToDate =
      "The firmware is already up to date with the current firmware version";
  static const String binFileHardwareVersionLabel =
      "Bin File Hardware Version: ";
  static const String bleHardwareVersionLabel = "BLE Hardware Version: ";
  static const String errorSendingPacketsPrefix = "Error sending packets: ";
  static const String bootloaderFileCorruptedDoYouWantToUpdate =
      "The bootloader file on the device is corrupted. "
      "Do you want to update the firmware?";

  // Site / panel actions
  static const String errorDeletingSitePrefix = "Error deleting site: ";
  static const String errorDeletingPanelPrefix = "Error deleting panel: ";
  static const String thisWillRemoveSitePrefix = 'This will remove "';
  static const String fromThisSite = "from this site?";

  // Scanning / errors
  static const String usbSerialDevicesTitle = "USB/Serial Devices";
  static const String bluetoothBleDevicesTitle = "Bluetooth (BLE) Devices";
  static const String failedToConnectPrefix = "Failed to connect: ";
  static const String couldNotCreatePdfPrefix = "Could not create PDF: ";
  static const String failedToLoadLogsPrefix = "Failed to load logs: ";

  // FAQ questions
  static const String faqHowDoICreateNewProject =
      "How do I create a new project?";
  static const String faqHowCanIRetrieveProjectLogs =
      "How can I retrieve project logs?";
  static const String faqWhatMaintenanceTasksAvailable =
      "What maintenance tasks are available?";

  // Config log (dynamic fragments)
  static const String lBusCommsFaultOnBusesPrefix =
      "L-Bus comms fault on bus(es): ";
  static const String selectLBus = "Select L-Bus";
  static const String entriesSuffix = " entries";
  static const String commsFaultOnSomeBusesPrefix =
      "Comms fault on some buses; ";
  static const String changesOnLBusPrefix = " change(s) on L-Bus ";
  static const String noDifferencesOnLBusPrefix = "No differences on L-Bus ";
  static const String changesVsSavedAppDataSuffix =
      " change(s) vs saved app data";

  static String siteDeletedMessage(String siteName) =>
      'Site "$siteName" deleted';

  static String panelDeletedMessage(String panelName) =>
      'Panel "$panelName" deleted';

  static String deleteSiteConfirmationMessage(String siteName) =>
      UiStrings.deleteSiteConfirmMessage(siteName);

  static String removePanelConfirmationMessage(
    String panelName,
    String panelId,
  ) => 'Remove panel "$panelName" ($panelId) $fromThisSite';

  static String binFileHardwareVersionDetail(
    String? binHardware,
    String bleHardware,
  ) =>
      '$binFileHardwareVersionLabel$binHardware\n'
      '$bleHardwareVersionLabel$bleHardware';
}
