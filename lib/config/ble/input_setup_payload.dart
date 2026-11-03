import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/ble/ts_frame.dart';
import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/structs/input_cfg_def.dart';

/// SETUP_INPUT command data inside the variable-length TS frame.
///
/// One command carries a single `st_input_1_cfg_def` (prog input) at byte 15.
/// Bytes 6–7 count network through command plus this struct.
abstract final class InputSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = TsFrame.dataOffset;

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

  static InputCfgDef readFromPacket(List<int> payload) {
    final parsed = TsFrame.parse(payload);
    if (!parsed.isValid || parsed.dataLength != byteLength) {
      throw FormatException(
        'SETUP_INPUT frame invalid: size=${payload.length} '
        'dataLength=${parsed.dataLength} '
        'lengthOk=${parsed.lengthMatches} '
        'checksumOk=${parsed.checksumMatches} '
        'eotOk=${parsed.eotMatches}',
      );
    }
    return InputCfgDef.fromBytes(parsed.data);
  }
}
