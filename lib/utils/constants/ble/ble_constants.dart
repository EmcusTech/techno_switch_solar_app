import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

abstract final class BleConstants {
  const BleConstants._();

  // UUIDs
  static const String primaryServiceUuid = StringConstants.bleServiceUuid;
  static const String primaryReadCharUuid = StringConstants.bleNotifyUuid;
  static const String primaryWriteCharUuid = StringConstants.bleWriteUuid;

  static final Uuid primaryService = Uuid.parse(primaryServiceUuid);
  static final Uuid primaryReadChar = Uuid.parse(primaryReadCharUuid);
  static final Uuid primaryWriteChar = Uuid.parse(primaryWriteCharUuid);

  // initialize
  static const int init = 0x00;

  // Frame
  static const int sot = 0xFE;
  static const int des = 0x01;
  static const int ori = 0x00;
  static const int eot = 0xFD;

  // Sequence Numbers
  static const int txPkNoInit = 0x00;
  static const int rxPkNoInit = 0x00;

  // Groups
  static const type = _BleType();
  static const network = _BleNetwork();
  static const mode = _BleMode();
  static const socket = _BleSocket();
  static const command = _BleCommand();
  static const firmware = _BleFirmware();

  // CONTROL_RES_EVENT_REPORT
  static const ctrlResEvtReport = _ControlResEventReport();

  // General Constants
  static const int base = 0xFF;
  static const int baseFF = 0xFFFF;
  static const int extZoneNo = 0x01;
  static const int extZoneTriggerArea = 0x01;
  static const int extZoneValveDelay = 0x1E;
  static const int extZoneExtractionTimeHigh = 0x00;
  static const int extZoneExtractionTimeLow = 0x3C;
  static const int extZoneExtractionDelayHigh = 0x03;
  static const int extZoneExtractionDelayLow = 0x84;
  static const int inputSetupNoHigh = 0x00;
  static const int inputSetupNoLow = 0x01;
  static const int inputSetupType = 0x02;
  static const int inputSetupTypeParams = 0x01;
  static const int firstOutputNoHigh = 0x00;
  static const int firstOutputNoLow = 0x04;
  static const int secondOutputNoHigh = 0x00;
  static const int secondtOutputNoLow = 0x05;
  static const int thirdOutputNoHigh = 0x00;
  static const int thirdtOutputNoLow = 0x06;
  static const int outputSetupType = 0x01;
  static const int firstOutputSetupTypeParams = 0x03;
  static const int secondOutputSetupTypeParams = 0x04;
  static const int thirdOutputSetupTypeParams = 0x05;
  static const int firstZoneSetupNo = 0x01;
  static const int secondZoneSetupNo = 0x02;
  static const int thirdZoneSetupNo = 0x03;
  static const int radioSetupEnabled = 0x01;
  static const int radioSetupDisabled = 0x00;
  static const int radioSetupAdvertised = 0x01;
  static const int radioSetupNotAdvertised = 0x00;
  static const int radioSetupConnected = 0x01;
  static const int radioSetupNotConnected = 0x00;
  static const int radioSetupProgrammed = 0x01;
  static const int radioSetupNotProgrammed = 0x00;
  static const int radioSetupBooted = 0x01;
  static const int radioSetupNotBooted = 0x00;
  static const int radioSetupServiced = 0x01;
  static const int radioSetupNotServiced = 0x00;
  static const int firstExtOutNoHigh = 0x00;
  static const int firstExtOutNoLow = 0x01;
  static const int sounderSetupRelayNoHigh = 0x00;
  static const int sounderSetupRelayNoLow = 0x01;
  static const int sounderSetupGeneralNoHigh = 0x00;
  static const int sounderSetupGeneralNoLow = 0x01;
  static const int sounderSetupZoneNoHigh = 0x00;
  static const int sounderSetupZoneNoLow = 0x01;
  static const int sounderSetupExtOutNoHigh = 0x00;
  static const int sounderSetupExtOutNoLow = 0x01;
  static const int adcInput = 0x04;
  static const int adcInputPage = 0x01;
  static const int buzzerState = 0x09;
  static const int sounderState = 0x0A;
  static const int resetState = 0x0C;
  static const int faultLatchingState = 0x12;
}

class _BleType {
  const _BleType();

  final int poll = 0x00;
  final int nrm = 0x01;
  final int ack = 0x02;
  final int nak = 0x03;
  final int net = 0x04;
  final int syn = 0x05;
}

class _BleNetwork {
  const _BleNetwork();

  final int modules = 0x00;
  final int panels = 0x01;
  final int repeaters = 0x02;
  final int setup = 0x03;
  final int server = 0x04;
  final int radio = 0x05;
}

class _BleMode {
  const _BleMode();

  final request = const _BleRequestMode();
  final instruction = const _BleInstructionMode();
}

class _BleRequestMode {
  const _BleRequestMode();

  final int module = 0x00;
  final int dbSetup = 0x01;
  final int dbStatus = 0x02;
  final int ctrl = 0x03;
}

class _BleInstructionMode {
  const _BleInstructionMode();

  final int module = 0x80;
  final int dbSetup = 0x81;
  final int dbStatus = 0x82;
  final int ctrl = 0x83;
}

class _BleSocket {
  const _BleSocket();

  final int panel = 0x00;
  final int solarSetup = 0x01;
  final int solarEmulation = 0x02;
  final int server = 0x03;
  final int radio = 0x04;
}

class _BleCommand {
  const _BleCommand();

  final int moduleId = 0x01;
  final int ctrlAcces = 0x04;
  final int ctrlResEventReport = 0x0B;
  final int bleJump = 0x1002;
  final int startFirmware = 0x1001;
  final int sendFirmware = 0x1002;
  final int sendFirstFirmwarePktAfterSkip = 0x1003;
  final int endFirmware = 0x1004;
  final int extOut = 0x16;
  final int dipSetting = 0x1C;
  final int inputSetup = 0x06;
  final int relaySetup = 0x07;
  final int zoneSetup = 0x04;
  final int radioSetup = 0x1D;
  final int moduleSetup = 0x01;
  final int lBusSetup = 0x10;
  final int lBusEnabledBusData = 0x01;
  final int sounderSetupGeneral = 0x14;
  final int sounderSetupRelay = 0x07;
  final int sounderSetupZone = 0x19;
  final int sounderSetupExtOut = 0x1B;
  final int serviceDue = 0x18;
  final int accessCodeSetup = 0x03;
  final int panelInfoPanelId = 0x08;
  final int panelInfoDateTime = 0x01;
  final int panelInfoEventReminderDelay = 0x09;
  final int generalModuleLvlTimeOut = 0x09;
  final int generalModuleSilenceBuzzerLvl = 0x15;
  final int generalModuleSilenceSounderLvl = 0x15;
  final int generalModuleResetLvl = 0x15;
  final int generalModuleFaultLatching = 0x15;
  final int diagnosticsSetupFetch = 0x09;
}

class _BleFirmware {
  const _BleFirmware();

  final int firmwareType = 0x02;
  final int firmwarelen = 0x01;
  final int firmwareData = 0x00;
}

class _ControlResEventReport {
  const _ControlResEventReport();

  final evtBufferMask = const _EventBufferMask();
  final evtBufferMode = const _EventBufferMode();
}

class _EventBufferMask {
  const _EventBufferMask();

  final int localEvtPrinter = 0x00;
  final int setupEvtPrinter = 0x01;
  final int serverEvtPrinter = 0x02;
  final int radioEvtPrinter = 0x03;
  final int gatewayEvtPrinter = 0x04;
}

class _EventBufferMode {
  const _EventBufferMode();

  final int start = 0x00;
  final int stop = 0x01;
}
