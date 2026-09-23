import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/ext_out_cfg_def.dart';

/// SETUP_EXT_OUT data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_ext_out_cfg_def` (11 bytes) at [13].
abstract final class ExtOutSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = ExtOutCfgDef.byteLength;

  static ExtOutCfgDef fromBleProcess(BleProcess process) {
    return ExtOutCfgDef(
      extOutEnable: process.isExtZoneEnabled.value,
      extOutType: process.extZoneActuatorType.value,
      extOutFunc: process.extZoneFunction.value,
      countdownAuto: process.extZoneCountdownAuto.value,
      countdownMan: process.extZoneCountdownMan.value,
      releaseTime: process.extZoneReleaseTime.value,
      resetDelay: process.extZoneResetDelay.value,
      resetInCount: process.isResetAllowed.value,
      holdCount: process.extZoneHoldMode.value,
      action: process.extZoneAction.value,
    );
  }

  static void applyToBleProcess(ExtOutCfgDef config, BleProcess process) {
    process.isExtZoneEnabled.value = config.extOutEnable;
    process.extZoneActuatorType.value = config.extOutType;
    process.extZoneFunction.value = config.extOutFunc;
    process.extZoneCountdownAuto.value = config.countdownAuto;
    process.extZoneCountdownMan.value = config.countdownMan;
    process.extZoneReleaseTime.value = config.releaseTime;
    process.extZoneResetDelay.value = config.resetDelay;
    process.isResetAllowed.value = config.resetInCount;
    process.extZoneHoldMode.value = config.holdCount;
    process.extZoneAction.value = config.action;
  }

  static void writeToPacket(Uint8List packet, ExtOutCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static ExtOutCfgDef readFromPacket(List<int> payload) {
    return ExtOutCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
