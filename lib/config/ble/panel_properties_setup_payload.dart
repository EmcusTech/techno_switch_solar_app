import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/panel_properties_cfg_def.dart';

/// SETUP_PANEL_PROPERTIES data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_panel_properties_def` (70 bytes) at [13].
abstract final class PanelPropertiesSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = PanelPropertiesCfgDef.byteLength;

  /// Truncates a full calendar year to u8 for wire (offset from 2000).
  static int serviceYearToWire(int fullYear) => (fullYear - 2000) & 0xFF;

  /// Reconstructs full calendar year from truncated u8 wire value.
  static int serviceYearFromWire(int wireYear) => 2000 + wireYear;

  static PanelPropertiesCfgDef fromBleProcess(BleProcess process) {
    return PanelPropertiesCfgDef(
      panelNum: process.panelInfoPanelNo.value,
      panelName: process.panelInfoPanelName.value,
      eventReminderDelay: process.panelInfoEventReminderDelay.value,
      remEnable: process.serviceDueReminder.value,
      lvlTimeout: process.generalModuleLvlTimeOut.value,
      silenceBuzzLvl: process.generalModuleSilenceBuzzerLvl.value,
      silenceSndrLvl: process.generalModuleSilenceSounderLvl.value,
      resetLvl: process.generalModuleResetLvl.value,
      faultLatch: process.generalModuleFaultLatching.value,
      serviceDueYear: serviceYearToWire(process.serviceDueYear.value),
      serviceDueMonth: process.serviceDueMonth.value,
      serviceDueDay: process.serviceDueDay.value,
      serviceDueHour: process.serviceDueHour.value,
      serviceDueMinute: process.serviceDueMinute.value,
      companyName: process.serviceDueCompany.value,
      serviceContact: process.serviceDueContact.value,
    );
  }

  static void applyToBleProcess(
    PanelPropertiesCfgDef config,
    BleProcess process,
  ) {
    process.panelInfoPanelNo.value = config.panelNum;
    process.panelInfoPanelName.value = config.panelName;
    process.panelInfoEventReminderDelay.value = config.eventReminderDelay;
    process.serviceDueReminder.value = config.remEnable;
    process.generalModuleLvlTimeOut.value = config.lvlTimeout;
    process.generalModuleSilenceBuzzerLvl.value = config.silenceBuzzLvl;
    process.generalModuleSilenceSounderLvl.value = config.silenceSndrLvl;
    process.generalModuleResetLvl.value = config.resetLvl;
    process.generalModuleFaultLatching.value = config.faultLatch;
    process.serviceDueYear.value = serviceYearFromWire(config.serviceDueYear);
    process.serviceDueMonth.value = config.serviceDueMonth;
    process.serviceDueDay.value = config.serviceDueDay;
    process.serviceDueHour.value = config.serviceDueHour;
    process.serviceDueMinute.value = config.serviceDueMinute;
    process.serviceDueCompany.value = config.companyName;
    process.serviceDueContact.value = config.serviceContact;
  }

  static void writeToPacket(Uint8List packet, PanelPropertiesCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static PanelPropertiesCfgDef readFromPacket(List<int> payload) {
    return PanelPropertiesCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
