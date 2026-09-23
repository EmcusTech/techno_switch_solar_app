import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/zone_cfg_def.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/zone_defaults.dart';

/// SETUP_ZONE data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_zone_cfg_def` (27 bytes) at [13].
abstract final class ZoneSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = ZoneCfgDef.byteLength;

  static ZoneCfgDef fromBleProcess(BleProcess process, int zoneIndex) {
    switch (zoneIndex) {
      case 0:
        return _fromZoneState(
          zoneNum: 1,
          zoneText: process.zoneOneSetupText.value,
          zoneType: process.zoneOneSetupType.value,
          zoneEnable: process.isZoneOneSetupEnabled.value,
          zoneTest: process.isZoneOneSetupTest.value,
          zoneMode: process.zoneOneSetupDetectionMode.value,
          verificationTime: process.zoneOneSetupVerificationTime.value,
        );
      case 1:
        return _fromZoneState(
          zoneNum: 2,
          zoneText: process.zoneTwoSetupText.value,
          zoneType: process.zoneTwoSetupType.value,
          zoneEnable: process.isZoneTwoSetupEnabled.value,
          zoneTest: process.isZoneTwoSetupTest.value,
          zoneMode: process.zoneTwoSetupDetectionMode.value,
          verificationTime: process.zoneTwoSetupVerificationTime.value,
        );
      case 2:
        return _fromZoneState(
          zoneNum: 3,
          zoneText: process.zoneThreeSetupText.value,
          zoneType: process.zoneThreeSetupType.value,
          zoneEnable: process.isZoneThreeSetupEnabled.value,
          zoneTest: process.isZoneThreeSetupTest.value,
          zoneMode: process.zoneThreeSetupDetectionMode.value,
          verificationTime: process.zoneThreeSetupVerificationTime.value,
        );
      default:
        throw RangeError('zoneIndex must be 0..2, got $zoneIndex');
    }
  }

  static ZoneCfgDef _fromZoneState({
    required int zoneNum,
    required String zoneText,
    required int zoneType,
    required bool zoneEnable,
    required bool zoneTest,
    required int zoneMode,
    required String verificationTime,
  }) {
    return ZoneCfgDef(
      zoneNum: zoneNum,
      zoneText: zoneText,
      zoneType: zoneType,
      zoneEnable: zoneEnable ? 1 : 0,
      zoneTest: zoneTest ? 1 : 0,
      zoneMode: zoneMode,
      verifyTime:
          int.tryParse(verificationTime) ??
          int.tryParse(ZoneDefaults.verificationTime) ??
          0,
    );
  }

  static void applyToBleProcess(
    ZoneCfgDef config,
    BleProcess process,
    int zoneIndex,
  ) {
    switch (zoneIndex) {
      case 0:
        process.zoneOneSetupText.value = config.zoneText;
        process.zoneOneSetupType.value = config.zoneType;
        process.isZoneOneSetupEnabled.value = config.zoneEnable != 0;
        process.isZoneOneSetupTest.value = config.zoneTest != 0;
        process.zoneOneSetupDetectionMode.value = config.zoneMode;
        process.zoneOneSetupVerificationTime.value =
            config.verifyTime.toString();
        break;
      case 1:
        process.zoneTwoSetupText.value = config.zoneText;
        process.zoneTwoSetupType.value = config.zoneType;
        process.isZoneTwoSetupEnabled.value = config.zoneEnable != 0;
        process.isZoneTwoSetupTest.value = config.zoneTest != 0;
        process.zoneTwoSetupDetectionMode.value = config.zoneMode;
        process.zoneTwoSetupVerificationTime.value =
            config.verifyTime.toString();
        break;
      case 2:
        process.zoneThreeSetupText.value = config.zoneText;
        process.zoneThreeSetupType.value = config.zoneType;
        process.isZoneThreeSetupEnabled.value = config.zoneEnable != 0;
        process.isZoneThreeSetupTest.value = config.zoneTest != 0;
        process.zoneThreeSetupDetectionMode.value = config.zoneMode;
        process.zoneThreeSetupVerificationTime.value =
            config.verifyTime.toString();
        break;
      default:
        throw RangeError('zoneIndex must be 0..2, got $zoneIndex');
    }
  }

  static void writeToPacket(Uint8List packet, ZoneCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static ZoneCfgDef readFromPacket(List<int> payload) {
    return ZoneCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
