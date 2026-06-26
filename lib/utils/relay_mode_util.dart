// =============================
// OUTPUT MODE BITMASK DEMO
// Paste directly into DartPad
// =============================

enum OutputEnable { disabled, enabled }

enum OutputMode { normal, test }

enum SupervisionMode { normal, mtl5525 }

class OutputModeConfig {
  final OutputEnable outputEnable;
  final OutputMode outputMode;
  final SupervisionMode supervisionMode;

  const OutputModeConfig({
    required this.outputEnable,
    required this.outputMode,
    required this.supervisionMode,
  });

  @override
  String toString() {
    return '''
Output Enable  : $outputEnable
Output Mode    : $outputMode
Supervision    : $supervisionMode
(Default → Latched, Not Inverted)
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
    bool isMtl = (value & 0x30) != 0; //0x10 | 0x20

    return OutputModeConfig(
      outputEnable:
          (value & 0x01) != 0 ? OutputEnable.enabled : OutputEnable.disabled,

      outputMode: (value & 0x02) != 0 ? OutputMode.test : OutputMode.normal,

      supervisionMode: isMtl ? SupervisionMode.mtl5525 : SupervisionMode.normal,
    );
  }

  static OutputModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
