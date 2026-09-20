import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/input_cfg_def.dart';

/// SETUP_INPUT data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_input_1_cfg_def` (prog input) at [13].
abstract final class InputSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = InputCfgDef.byteLength;

  static InputCfgDef fromBleProcess(BleProcess process) {
    return InputCfgDef(
      inputText: process.inputSetupText.value,
      inputGrp: process.inputSetupGroup.value,
      inputFunc: process.inputSetupFunction.value,
      inputEnable: process.isInputSetupEnabled.value ? 1 : 0,
      inputTest: process.isInputSetupTest.value ? 1 : 0,
      inputInvert: process.isInputSetupInverted.value ? 1 : 0,
    );
  }

  static void applyToBleProcess(InputCfgDef config, BleProcess process) {
    process.inputSetupText.value = config.inputText;
    process.inputSetupGroup.value = config.inputGrp;
    process.inputSetupFunction.value = config.inputFunc;
    process.isInputSetupEnabled.value = config.inputEnable != 0;
    process.isInputSetupTest.value = config.inputTest != 0;
    process.isInputSetupInverted.value = config.inputInvert != 0;
  }

  static void writeToPacket(Uint8List packet, InputCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static InputCfgDef readFromPacket(List<int> payload) {
    return InputCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
