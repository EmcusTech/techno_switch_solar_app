import 'dart:typed_data';

import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';

/// SETUP_SOUNDER data section inside the 216-byte BLE frame.
///
/// One command carries three `st_sounder_cfg_def` blocks (34 bytes each) at [13].
abstract final class SounderSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = SounderCfgDef.byteLength;
  static const int sounderCount = 3;
  static const int packedByteLength = byteLength * sounderCount;

  static SounderCfgDef fromBleProcess(BleProcess process, int sounderIndex) {
    switch (sounderIndex) {
      case 0:
        return _fromSounderState(
          process: process,
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
          process: process,
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
          process: process,
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
    required BleProcess process,
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
    var advAction = 0;
    var advCountdown = 0;
    var advHold = 0;
    var advRelease = 0;

    if (sounderGrp == SounderCfgDef.sounderGroupZone) {
      sounderZone = functionNo;
      advAction = _zoneAction(process, sounderZone);
    } else if (sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      advCountdown = process.extoutOneCountdownAction.value;
      advHold = process.extoutOneHoldAction.value;
      advRelease = process.extoutOneReleaseAction.value;
    } else {
      advAction = process.sounderGeneralAction.value;
    }

    return SounderCfgDef(
      sounderNum: sounderNum,
      sounderText: sounderText,
      sounderGrp: sounderGrp,
      sounderFunc: sounderFunc,
      sounderZone: sounderZone,
      sounderEnable: sounderEnable ? 1 : 0,
      sounderTest: sounderTest ? 1 : 0,
      sounderType: sounderType ? 0 : 1,
      delay: process.sounderGeneralDelay.value,
      advAction: advAction,
      advCountdown: advCountdown,
      advHold: advHold,
      advRelease: advRelease,
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
        process.isSounderOneNormal.value = config.sounderType == 0;
        break;
      case 1:
        process.sounderTwoOutputText.value = config.sounderText;
        process.sounderTwoRelayFunctionGroup.value = config.sounderGrp;
        process.sounderTwoRelayFunction.value = config.sounderFunc;
        process.sounderTwoFunctionNo.value = functionNo;
        process.isSounderTwoEnabled.value = config.sounderEnable != 0;
        process.isSounderTwoTest.value = config.sounderTest != 0;
        process.isSounderTwoNormal.value = config.sounderType == 0;
        break;
      case 2:
        process.sounderThreeOutputText.value = config.sounderText;
        process.sounderThreeRelayFunctionGroup.value = config.sounderGrp;
        process.sounderThreeRelayFunction.value = config.sounderFunc;
        process.sounderThreeFunctionNo.value = functionNo;
        process.isSounderThreeEnabled.value = config.sounderEnable != 0;
        process.isSounderThreeTest.value = config.sounderTest != 0;
        process.isSounderThreeNormal.value = config.sounderType == 0;
        break;
      default:
        throw RangeError('sounderIndex must be 0..2, got $sounderIndex');
    }

    process.sounderGeneralDelay.value = config.delay;
    _applyAdvanced(config, process);
  }

  static void _applyAdvanced(SounderCfgDef config, BleProcess process) {
    final enabled = config.sounderEnable != 0;
    final test = config.sounderTest != 0;
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      _setZone(
        process,
        config.sounderZone,
        enabled: enabled,
        test: test,
        action: config.advAction,
      );
      return;
    }
    if (config.sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      process.isExtOutOneEnabled.value = enabled;
      process.isExtOutOneTest.value = test;
      process.extoutOneCountdownAction.value = config.advCountdown;
      process.extoutOneHoldAction.value = config.advHold;
      process.extoutOneReleaseAction.value = config.advRelease;
      return;
    }
    process.isSounderGeneralEnabled.value = enabled;
    process.isSounderGeneralTest.value = test;
    process.sounderGeneralAction.value = config.advAction;
  }

  static int _zoneAction(BleProcess process, int zone) {
    return switch (zone) {
      1 => process.zoneOneAction.value,
      2 => process.zoneTwoAction.value,
      3 => process.zoneThreeAction.value,
      _ => 0,
    };
  }

  static void _setZone(
    BleProcess process,
    int zone, {
    required bool enabled,
    required bool test,
    required int action,
  }) {
    switch (zone) {
      case 1:
        process.isZoneOneEnabled.value = enabled;
        process.isZoneOneTest.value = test;
        process.zoneOneAction.value = action;
      case 2:
        process.isZoneTwoEnabled.value = enabled;
        process.isZoneTwoTest.value = test;
        process.zoneTwoAction.value = action;
      case 3:
        process.isZoneThreeEnabled.value = enabled;
        process.isZoneThreeTest.value = test;
        process.zoneThreeAction.value = action;
    }
  }

  static int _functionNoFromStruct(SounderCfgDef config) {
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      return config.sounderZone;
    }
    return 0;
  }

  static void writeToPacket(Uint8List packet, SounderCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static void writeAllToPacket(Uint8List packet, BleProcess process) {
    final packed = Uint8List(packedByteLength);
    for (var index = 0; index < sounderCount; index++) {
      final bytes = fromBleProcess(process, index).toBytes();
      packed.setRange(index * byteLength, (index + 1) * byteLength, bytes);
    }
    ConfigSetupPayload.writeStruct(packet, packed);
  }

  static SounderCfgDef readFromPacket(List<int> payload) {
    return SounderCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }

  static void readAllIntoBleProcess(List<int> payload, BleProcess process) {
    final packed = ConfigSetupPayload.readStructBytes(
      payload,
      packedByteLength,
    );
    for (var index = 0; index < sounderCount; index++) {
      final config = SounderCfgDef.fromBytes(
        packed,
        offset: index * byteLength,
      );
      applyToBleProcess(config, process, index);
    }
  }
}
