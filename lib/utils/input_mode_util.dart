// =============================
// INPUT MODE BITMASK DEMO
// Paste directly into DartPad
// =============================

enum InputEnable { disabled, enabled }

enum InputMode { normal, test }

enum LatchMode {
  nonLatched, // 0
  latched, // 1
}

enum InvertMode {
  notInverted, // 0
  inverted, // 1
}

class InputModeConfig {
  final InputEnable inputEnable;
  final InputMode inputMode;

  /// Only valid for Logic Table group
  final LatchMode latchMode;

  /// Only valid for Logic Table group
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
  // ================= ENCODER =================
  static int encode(InputModeConfig config) {
    int value = 0;

    // Bit 0 → Input Enable
    if (config.inputEnable == InputEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1 → Test Mode
    if (config.inputMode == InputMode.test) {
      value |= 0x02;
    }

    // Bit 2 → Latch Mode (Logic Table only)
    if (config.latchMode == LatchMode.latched) {
      value |= 0x04;
    }

    // Bit 3 → Invert Mode (Logic Table only)
    if (config.invertMode == InvertMode.inverted) {
      value |= 0x08;
    }

    return value & 0xFF;
  }

  static String encodeHex(InputModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODER =================
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

  // ================= NEW HELPER =================
  /// Create InputModeConfig directly from HEX string (e.g. "0A")
  static InputModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}

// ================= DEMO / TEST =================

void main() {
  print("========= INPUT MODE ENCODE TEST =========\n");

  final config = InputModeConfig(
    inputEnable: InputEnable.enabled,
    inputMode: InputMode.test,
    latchMode: LatchMode.nonLatched,
    invertMode: InvertMode.inverted,
  );

  final String hexValue = InputModeCodec.encodeHex(config);

  print(config);
  print("Generated HEX → $hexValue\n");

  print("========= DECODE TEST =========\n");

  final decoded = InputModeCodec.fromHex(hexValue);
  print(decoded);
}
