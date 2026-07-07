enum InputEnable { disabled, enabled }

enum InputMode { normal, test }

enum LatchMode { nonLatched, latched }

enum InvertMode { notInverted, inverted }

class InputModeConfig {
  final InputEnable inputEnable;
  final InputMode inputMode;
  final LatchMode latchMode;
  final InvertMode invertMode;

  const InputModeConfig({
    required this.inputEnable,
    required this.inputMode,
    required this.latchMode,
    required this.invertMode,
  });

  @override
  String toString() {
    return '''
Input Enable   : $inputEnable
Input Mode     : $inputMode
Latch Mode     : $latchMode
Invert Mode    : $invertMode
''';
  }
}

class InputModeCodec {
  static int encode(InputModeConfig config) {
    int value = 0;

    if (config.inputEnable == InputEnable.enabled) {
      value |= 0x01;
    }

    if (config.inputMode == InputMode.test) {
      value |= 0x02;
    }

    if (config.latchMode == LatchMode.latched) {
      value |= 0x04;
    }

    if (config.invertMode == InvertMode.inverted) {
      value |= 0x08;
    }

    return value & 0xFF;
  }

  static String encodeHex(InputModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static InputModeConfig decode(int value) {
    return InputModeConfig(
      inputEnable:
          (value & 0x01) != 0 ? InputEnable.enabled : InputEnable.disabled,

      inputMode: (value & 0x02) != 0 ? InputMode.test : InputMode.normal,

      latchMode: (value & 0x04) != 0 ? LatchMode.latched : LatchMode.nonLatched,

      invertMode:
          (value & 0x08) != 0 ? InvertMode.inverted : InvertMode.notInverted,
    );
  }

  static InputModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
