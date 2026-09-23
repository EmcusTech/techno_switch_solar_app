import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/relay_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/relay_config_ui_bridge.dart';

/// SETUP_RELAY data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_relay_cfg_def` (28 bytes) at [13].
abstract final class RelaySetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = RelayCfgDef.byteLength;

  static RelayCfgDef fromBleProcess(BleProcess process, int relayIndex) {
    switch (relayIndex) {
      case 0:
        return _fromRelayState(
          relayNum: 1,
          relayText: process.relayOneSetupOutputText.value,
          relayGrp: process.relayOneSetupGroup.value,
          relayFunc: process.relayOneSetupFunction.value,
          dynamicText: process.relayOneSetupDynamicText.value,
          relayEnable: process.isRelayOneSetupEnabled.value,
          relayTest: process.isRelayOneSetupTest.value,
        );
      case 1:
        return _fromRelayState(
          relayNum: 2,
          relayText: process.relayTwoSetupOutputText.value,
          relayGrp: process.relayTwoSetupGroup.value,
          relayFunc: process.relayTwoSetupFunction.value,
          dynamicText: process.relayTwoSetupDynamicText.value,
          relayEnable: process.isRelayTwoSetupEnabled.value,
          relayTest: process.isRelayTwoSetupTest.value,
        );
      case 2:
        return _fromRelayState(
          relayNum: 3,
          relayText: process.relayThreeSetupOutputText.value,
          relayGrp: process.relayThreeSetupGroup.value,
          relayFunc: process.relayThreeSetupFunction.value,
          dynamicText: process.relayThreeSetupDynamicText.value,
          relayEnable: process.isRelayThreeSetupEnabled.value,
          relayTest: process.isRelayThreeSetupTest.value,
        );
      default:
        throw RangeError('relayIndex must be 0..2, got $relayIndex');
    }
  }

  static RelayCfgDef _fromRelayState({
    required int relayNum,
    required String relayText,
    required int relayGrp,
    required int relayFunc,
    required String dynamicText,
    required bool relayEnable,
    required bool relayTest,
  }) {
    final dynamicValue =
        int.tryParse(dynamicText.trim()) ??
        int.tryParse(dynamicText.trim(), radix: 16) ??
        0;

    var relayZone = 0;
    var relayExtOut = 0;
    if (relayGrp == RelayCfgDef.relayGroupZone) {
      relayZone = dynamicValue;
    } else if (relayGrp == RelayCfgDef.relayGroupExtOut) {
      relayExtOut = dynamicValue;
    }

    return RelayCfgDef(
      relayNum: relayNum,
      relayText: relayText,
      relayGrp: relayGrp,
      relayFunc: relayFunc,
      relayZone: relayZone,
      relayExtOut: relayExtOut,
      relayEnable: relayEnable ? 1 : 0,
      relayTest: relayTest ? 1 : 0,
    );
  }

  static void applyToBleProcess(
    RelayCfgDef config,
    BleProcess process,
    int relayIndex,
  ) {
    final dynamicText = RelayConfigUiBridge.dynamicValueFromStruct(config);

    switch (relayIndex) {
      case 0:
        process.relayOneSetupOutputText.value = config.relayText;
        process.relayOneSetupGroup.value = config.relayGrp;
        process.relayOneSetupFunction.value = config.relayFunc;
        process.relayOneSetupDynamicText.value = dynamicText;
        process.isRelayOneSetupEnabled.value = config.relayEnable != 0;
        process.isRelayOneSetupTest.value = config.relayTest != 0;
        break;
      case 1:
        process.relayTwoSetupOutputText.value = config.relayText;
        process.relayTwoSetupGroup.value = config.relayGrp;
        process.relayTwoSetupFunction.value = config.relayFunc;
        process.relayTwoSetupDynamicText.value = dynamicText;
        process.isRelayTwoSetupEnabled.value = config.relayEnable != 0;
        process.isRelayTwoSetupTest.value = config.relayTest != 0;
        break;
      case 2:
        process.relayThreeSetupOutputText.value = config.relayText;
        process.relayThreeSetupGroup.value = config.relayGrp;
        process.relayThreeSetupFunction.value = config.relayFunc;
        process.relayThreeSetupDynamicText.value = dynamicText;
        process.isRelayThreeSetupEnabled.value = config.relayEnable != 0;
        process.isRelayThreeSetupTest.value = config.relayTest != 0;
        break;
      default:
        throw RangeError('relayIndex must be 0..2, got $relayIndex');
    }
  }

  static void writeToPacket(Uint8List packet, RelayCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static RelayCfgDef readFromPacket(List<int> payload) {
    return RelayCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
