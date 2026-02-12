// =============================
// OUTPUT MODE BITMASK DEMO
// Paste directly into DartPad
// =============================

enum OutputEnable { disabled, enabled }

enum OutputMode { normal, test }

class OutputModeConfig {
  final OutputEnable outputEnable;
  final OutputMode outputMode;

  const OutputModeConfig({
    required this.outputEnable,
    required this.outputMode,
  });

  @override
  String toString() {
    return '''
Output Enable  : $outputEnable
Output Mode    : $outputMode
(Default → Latched, Not Inverted, Normal Supervision)
''';
  }
}

class OutputModeCodec {
  // Fixed defaults
  static const int _defaultLatched = 0x04; // Bit 2 = 1
  static const int _defaultInvert = 0x00; // Bit 3 = 0
  static const int _defaultSupervision = 0x00; // Bit 4 & 5 = 0

  // ================= ENCODER =================
  static int encode(OutputModeConfig config) {
    int value = 0;

    // Apply fixed defaults first
    value |= _defaultLatched;
    value |= _defaultInvert;
    value |= _defaultSupervision;

    // Bit 0 → Enable
    if (config.outputEnable == OutputEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1 → Test Mode
    if (config.outputMode == OutputMode.test) {
      value |= 0x02;
    }

    return value & 0xFF;
  }

  static String encodeHex(OutputModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODER =================
  static OutputModeConfig decode(int value) {
    return OutputModeConfig(
      outputEnable:
          (value & 0x01) != 0 ? OutputEnable.enabled : OutputEnable.disabled,

      outputMode: (value & 0x02) != 0 ? OutputMode.test : OutputMode.normal,
    );
  }

  static OutputModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}

// ================= DEMO =================

void main() {
  print("========= OUTPUT MODE ENCODE TEST =========\n");

  final config = OutputModeConfig(
    outputEnable: OutputEnable.enabled,
    outputMode: OutputMode.test,
  );

  final String hexValue = OutputModeCodec.encodeHex(config);

  print(config);
  print("Generated HEX → $hexValue\n");

  print("========= DECODE TEST =========\n");

  final decoded = OutputModeCodec.fromHex(hexValue);
  print(decoded);
}
