import 'dart:typed_data';

import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/ble/sndr_relay_pattern.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';
import 'package:Technoswitch/config/ui/sounder_config_options.dart';

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
    final sounderZone =
        sounderGrp == SounderCfgDef.sounderGroupZone ? functionNo : 0;
    final pattern = SndrRelayPattern.fromProcess(
      process: process,
      group: sounderGrp,
      function: SndrRelayPattern.functionLabel(
        group: sounderGrp,
        function: sounderFunc,
        groups: SounderConfigOptions.groupOptions,
        functionsByGroup: SounderConfigOptions.functionOptionsMap,
      ),
      zone: sounderZone,
    );

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
      advAction: pattern.action,
      advCountdown: pattern.countdown,
      advHold: pattern.hold,
      advRelease: pattern.release,
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
    SndrRelayPattern.applyToProcess(
      process,
      group: config.sounderGrp,
      function: SndrRelayPattern.functionLabel(
        group: config.sounderGrp,
        function: config.sounderFunc,
        groups: SounderConfigOptions.groupOptions,
        functionsByGroup: SounderConfigOptions.functionOptionsMap,
      ),
      zone: config.sounderZone,
      action: config.advAction,
      countdown: config.advCountdown,
      hold: config.advHold,
      release: config.advRelease,
    );
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

  static Uint8List packedBytes(BleProcess process) {
    final packed = Uint8List(packedByteLength);
    for (var index = 0; index < sounderCount; index++) {
      final bytes = fromBleProcess(process, index).toBytes();
      packed.setRange(index * byteLength, (index + 1) * byteLength, bytes);
    }
    return packed;
  }

  static void writeAllToPacket(Uint8List packet, BleProcess process) {
    ConfigSetupPayload.writeStruct(packet, packedBytes(process));
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
