import 'dart:typed_data';

import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';

/// SETUP_SOUNDER data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_sounder_cfg_def` (37 bytes) at [13].
abstract final class SounderSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = SounderCfgDef.byteLength;

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
    var sounderExtOut = 0;
    var unionEnabled = sounderEnable ? 1 : 0;
    var unionTest = sounderTest ? 1 : 0;
    var unionAction = 0;
    var unionCountdown = 0;
    var unionHold = 0;
    var unionRelease = 0;

    if (sounderGrp == SounderCfgDef.sounderGroupZone) {
      sounderZone = functionNo;
      unionEnabled = _zoneEnabled(process, sounderZone);
      unionTest = _zoneTest(process, sounderZone);
      unionAction = _zoneAction(process, sounderZone);
    } else if (sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      sounderExtOut = functionNo;
      unionEnabled = _extEnabled(process, sounderExtOut);
      unionTest = _extTest(process, sounderExtOut);
      unionCountdown = _extCountdown(process, sounderExtOut);
      unionHold = _extHold(process, sounderExtOut);
      unionRelease = _extRelease(process, sounderExtOut);
    } else {
      unionEnabled = process.isSounderGeneralEnabled.value ? 1 : 0;
      unionTest = process.isSounderGeneralTest.value ? 1 : 0;
      unionAction = process.sounderGeneralAction.value;
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
      delay: process.sounderGeneralDelay.value,
      unionFunction: sounderFunc,
      unionZone: sounderZone,
      unionEnabled: unionEnabled,
      unionTest: unionTest,
      unionAction: unionAction,
      unionCountdown: unionCountdown,
      unionHold: unionHold,
      unionRelease: unionRelease,
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

    process.sounderGeneralDelay.value = config.delay;
    _applyUnion(config, process);
  }

  static void _applyUnion(SounderCfgDef config, BleProcess process) {
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      _setZone(
        process,
        config.unionZone,
        enabled: config.unionEnabled != 0,
        test: config.unionTest != 0,
        action: config.unionAction,
      );
      return;
    }
    if (config.sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      _setExt(
        process,
        config.sounderExtOut,
        enabled: config.unionEnabled != 0,
        test: config.unionTest != 0,
        countdown: config.unionCountdown,
        hold: config.unionHold,
        release: config.unionRelease,
      );
      return;
    }
    process.isSounderGeneralEnabled.value = config.unionEnabled != 0;
    process.isSounderGeneralTest.value = config.unionTest != 0;
    process.sounderGeneralAction.value = config.unionAction;
  }

  static int _zoneEnabled(BleProcess process, int zone) {
    return switch (zone) {
      1 => process.isZoneOneEnabled.value ? 1 : 0,
      2 => process.isZoneTwoEnabled.value ? 1 : 0,
      3 => process.isZoneThreeEnabled.value ? 1 : 0,
      _ => 0,
    };
  }

  static int _zoneTest(BleProcess process, int zone) {
    return switch (zone) {
      1 => process.isZoneOneTest.value ? 1 : 0,
      2 => process.isZoneTwoTest.value ? 1 : 0,
      3 => process.isZoneThreeTest.value ? 1 : 0,
      _ => 0,
    };
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

  static int _extEnabled(BleProcess process, int ext) {
    return switch (ext) {
      1 => process.isExtOutOneEnabled.value ? 1 : 0,
      2 => process.isExtOutTwoEnabled.value ? 1 : 0,
      3 => process.isExtOutThreeEnabled.value ? 1 : 0,
      _ => 0,
    };
  }

  static int _extTest(BleProcess process, int ext) {
    return switch (ext) {
      1 => process.isExtOutOneTest.value ? 1 : 0,
      2 => process.isExtOutTwoTest.value ? 1 : 0,
      3 => process.isExtOutThreeTest.value ? 1 : 0,
      _ => 0,
    };
  }

  static int _extCountdown(BleProcess process, int ext) {
    return switch (ext) {
      1 => process.extoutOneCountdownAction.value,
      2 => process.extoutTwoCountdownAction.value,
      3 => process.extoutThreeCountdownAction.value,
      _ => 0,
    };
  }

  static int _extHold(BleProcess process, int ext) {
    return switch (ext) {
      1 => process.extoutOneHoldAction.value,
      2 => process.extoutTwoHoldAction.value,
      3 => process.extoutThreeHoldAction.value,
      _ => 0,
    };
  }

  static int _extRelease(BleProcess process, int ext) {
    return switch (ext) {
      1 => process.extoutOneReleaseAction.value,
      2 => process.extoutTwoReleaseAction.value,
      3 => process.extoutThreeReleaseAction.value,
      _ => 0,
    };
  }

  static void _setExt(
    BleProcess process,
    int ext, {
    required bool enabled,
    required bool test,
    required int countdown,
    required int hold,
    required int release,
  }) {
    switch (ext) {
      case 1:
        process.isExtOutOneEnabled.value = enabled;
        process.isExtOutOneTest.value = test;
        process.extoutOneCountdownAction.value = countdown;
        process.extoutOneHoldAction.value = hold;
        process.extoutOneReleaseAction.value = release;
      case 2:
        process.isExtOutTwoEnabled.value = enabled;
        process.isExtOutTwoTest.value = test;
        process.extoutTwoCountdownAction.value = countdown;
        process.extoutTwoHoldAction.value = hold;
        process.extoutTwoReleaseAction.value = release;
      case 3:
        process.isExtOutThreeEnabled.value = enabled;
        process.isExtOutThreeTest.value = test;
        process.extoutThreeCountdownAction.value = countdown;
        process.extoutThreeHoldAction.value = hold;
        process.extoutThreeReleaseAction.value = release;
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
