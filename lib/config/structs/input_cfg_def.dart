import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/input_defaults.dart';

/// Mirrors firmware `st_input_1_cfg_def` (26 bytes, packed).
class InputCfgDef {
  const InputCfgDef({
    this.inputText = InputDefaults.inputText,
    this.inputGrp = InputDefaults.groupBle,
    this.inputFunc = InputDefaults.functionBle,
    this.inputEnable = InputDefaults.enabledBle ? 1 : 0,
    this.inputTest = InputDefaults.testBle ? 1 : 0,
    this.inputInvert = InputDefaults.invertedBle ? 1 : 0,
  });

  static const int byteLength = 26;

  final String inputText;
  final int inputGrp;
  final int inputFunc;
  final int inputEnable;
  final int inputTest;
  final int inputInvert;

  factory InputCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError('InputCfgDef requires $byteLength bytes at offset $offset');
    }
    return InputCfgDef(
      inputText: _readFixedText(bytes, offset),
      inputGrp: bytes[offset + 21],
      inputFunc: bytes[offset + 22],
      inputEnable: bytes[offset + 23],
      inputTest: bytes[offset + 24],
      inputInvert: bytes[offset + 25],
    );
  }

  factory InputCfgDef.fromCacheMap(Map<String, dynamic> data) {
    return InputCfgDef(
      inputText: (data['text'] as String?) ?? InputDefaults.inputText,
      inputGrp: (data['group'] as num?)?.toInt() ?? InputDefaults.groupBle,
      inputFunc: (data['function'] as num?)?.toInt() ?? InputDefaults.functionBle,
      inputEnable:
          ((data['enabled'] as bool?) ?? InputDefaults.enabledBle) ? 1 : 0,
      inputTest: ((data['test'] as bool?) ?? InputDefaults.testBle) ? 1 : 0,
      inputInvert:
          ((data['inverted'] as bool?) ?? InputDefaults.invertedBle) ? 1 : 0,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    _writeFixedText(buf, 0, inputText);
    buf[21] = inputGrp & 0xFF;
    buf[22] = inputFunc & 0xFF;
    buf[23] = inputEnable & 0xFF;
    buf[24] = inputTest & 0xFF;
    buf[25] = inputInvert & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    'text': inputText,
    'group': inputGrp,
    'function': inputFunc,
    'enabled': inputEnable != 0,
    'test': inputTest != 0,
    'inverted': inputInvert != 0,
  };

  static void _writeFixedText(Uint8List buf, int offset, String text) {
    final units = text.codeUnits;
    final len = units.length.clamp(0, SystemConfigLimits.inputTextLength);
    for (var i = 0; i < len; i++) {
      buf[offset + i] = units[i];
    }
  }

  static String _readFixedText(Uint8List bytes, int offset) {
    var len = SystemConfigLimits.inputTextLength;
    while (len > 0 && bytes[offset + len - 1] == 0) {
      len--;
    }
    if (len == 0) {
      return '';
    }
    return String.fromCharCodes(
      bytes.sublist(offset, offset + len),
    );
  }
}

/// `st_input[MAX_INPUT_SUPPORT]` as a contiguous byte blob.
class InputCfgArray {
  InputCfgArray(this.inputs)
    : assert(inputs.length == SystemConfigLimits.maxInputSupport);

  final List<InputCfgDef> inputs;

  static const int byteLength =
      InputCfgDef.byteLength * SystemConfigLimits.maxInputSupport;

  factory InputCfgArray.defaults() => InputCfgArray(
    List.generate(
      SystemConfigLimits.maxInputSupport,
      (_) => const InputCfgDef(),
    ),
  );

  factory InputCfgArray.fromBytes(Uint8List bytes, {int offset = 0}) {
    final list = <InputCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxInputSupport; i++) {
      final structOffset = offset + (i * InputCfgDef.byteLength);
      list.add(InputCfgDef.fromBytes(bytes, offset: structOffset));
    }
    return InputCfgArray(list);
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    for (var i = 0; i < SystemConfigLimits.maxInputSupport; i++) {
      buf.setRange(
        i * InputCfgDef.byteLength,
        (i + 1) * InputCfgDef.byteLength,
        inputs[i].toBytes(),
      );
    }
    return buf;
  }
}
