import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/sounder_cfg_def.dart';

/// SETUP_SOUNDER data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_sounder_cfg_def` (29 bytes) at [13].
abstract final class SounderSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = SounderCfgDef.byteLength;

  static SounderCfgDef fromBleProcess(BleProcess process, int sounderIndex) {
    switch (sounderIndex) {
      case 0:
        return _fromSounderState(
          sounderNum: 1,
          sounderText: process.sounderOneOutputText.value,
          sounderGrp: process.sounderOneRelayFunctionGroup.value,
          sounderFunc: process.sounderOneRelayFunction.value,
          functionNo: process.sounderOneFunctionNo.value,
          sounderEnable: process.isSounderOneEnabled.value,
          sounderTest: process.isSounderOneTest.value,
          sounderType: process.isSounderOneNormal.value,
        );
      case 1:
        return _fromSounderState(
          sounderNum: 2,
          sounderText: process.sounderTwoOutputText.value,
          sounderGrp: process.sounderTwoRelayFunctionGroup.value,
          sounderFunc: process.sounderTwoRelayFunction.value,
          functionNo: process.sounderTwoFunctionNo.value,
          sounderEnable: process.isSounderTwoEnabled.value,
          sounderTest: process.isSounderTwoTest.value,
          sounderType: process.isSounderTwoNormal.value,
        );
      case 2:
        return _fromSounderState(
          sounderNum: 3,
          sounderText: process.sounderThreeOutputText.value,
          sounderGrp: process.sounderThreeRelayFunctionGroup.value,
          sounderFunc: process.sounderThreeRelayFunction.value,
          functionNo: process.sounderThreeFunctionNo.value,
          sounderEnable: process.isSounderThreeEnabled.value,
          sounderTest: process.isSounderThreeTest.value,
          sounderType: process.isSounderThreeNormal.value,
        );
      default:
        throw RangeError('sounderIndex must be 0..2, got $sounderIndex');
    }
  }

  static SounderCfgDef _fromSounderState({
    required int sounderNum,
    required String sounderText,
    required int sounderGrp,
    required int sounderFunc,
    required int functionNo,
    required bool sounderEnable,
    required bool sounderTest,
    required bool sounderType,
  }) {
    var sounderZone = 0;
    var sounderExtOut = 0;
    if (sounderGrp == SounderCfgDef.sounderGroupZone) {
      sounderZone = functionNo;
    } else if (sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      sounderExtOut = functionNo;
    }

    return SounderCfgDef(
      sounderNum: sounderNum,
      sounderText: sounderText,
      sounderGrp: sounderGrp,
      sounderFunc: sounderFunc,
      sounderZone: sounderZone,
      sounderExtOut: sounderExtOut,
      sounderEnable: sounderEnable ? 1 : 0,
      sounderTest: sounderTest ? 1 : 0,
      sounderType: sounderType ? 1 : 0,
    );
  }

  static void applyToBleProcess(
    SounderCfgDef config,
    BleProcess process,
    int sounderIndex,
  ) {
    final functionNo = _functionNoFromStruct(config);

    switch (sounderIndex) {
      case 0:
        process.sounderOneOutputText.value = config.sounderText;
        process.sounderOneRelayFunctionGroup.value = config.sounderGrp;
        process.sounderOneRelayFunction.value = config.sounderFunc;
        process.sounderOneFunctionNo.value = functionNo;
        process.isSounderOneEnabled.value = config.sounderEnable != 0;
        process.isSounderOneTest.value = config.sounderTest != 0;
        process.isSounderOneNormal.value = config.sounderType != 0;
        break;
      case 1:
        process.sounderTwoOutputText.value = config.sounderText;
        process.sounderTwoRelayFunctionGroup.value = config.sounderGrp;
        process.sounderTwoRelayFunction.value = config.sounderFunc;
        process.sounderTwoFunctionNo.value = functionNo;
        process.isSounderTwoEnabled.value = config.sounderEnable != 0;
        process.isSounderTwoTest.value = config.sounderTest != 0;
        process.isSounderTwoNormal.value = config.sounderType != 0;
        break;
      case 2:
        process.sounderThreeOutputText.value = config.sounderText;
        process.sounderThreeRelayFunctionGroup.value = config.sounderGrp;
        process.sounderThreeRelayFunction.value = config.sounderFunc;
        process.sounderThreeFunctionNo.value = functionNo;
        process.isSounderThreeEnabled.value = config.sounderEnable != 0;
        process.isSounderThreeTest.value = config.sounderTest != 0;
        process.isSounderThreeNormal.value = config.sounderType != 0;
        break;
      default:
        throw RangeError('sounderIndex must be 0..2, got $sounderIndex');
    }
  }

  static int _functionNoFromStruct(SounderCfgDef config) {
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      return config.sounderZone;
    }
    if (config.sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      return config.sounderExtOut;
    }
    return 0;
  }

  static void writeToPacket(Uint8List packet, SounderCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static SounderCfgDef readFromPacket(List<int> payload) {
    return SounderCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
