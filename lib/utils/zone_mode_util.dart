// =============================
// ZONE MODE BITMASK DEMO
// Paste directly into DartPad
// =============================

enum ZoneEnable { disabled, enabled }

enum ZoneMode { normal, test }

enum HoldMode {
  notUsed, // 0
  restartCount, // 1
  suspendCount, // 2
  continueCount, // 3
}

class ZoneModeConfig {
  final ZoneEnable zoneEnable;
  final ZoneMode zoneMode;
  final HoldMode holdMode;

  /// IMPORTANT:
  /// Firmware behaviour is reversed from documentation
  /// true  -> reset allowed
  /// false -> reset NOT allowed
  final bool resetAllowed;

  final bool flowDetectionUsed;

  const ZoneModeConfig({
    required this.zoneEnable,
    required this.zoneMode,
    required this.holdMode,
    required this.resetAllowed,
    required this.flowDetectionUsed,
  });

  @override
  String toString() {
    return '''
Zone Enable        : $zoneEnable
Zone Mode          : $zoneMode
Hold Mode          : $holdMode
Reset Allowed      : $resetAllowed
Flow Detection     : $flowDetectionUsed
''';
  }
}

class ZoneModeCodec {
  // ================= ENCODER =================
  static int encode(ZoneModeConfig config) {
    int value = 0;

    // Bit 0 → Zone Enable
    if (config.zoneEnable == ZoneEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1 → Test Mode
    if (config.zoneMode == ZoneMode.test) {
      value |= 0x02;
    }

    // Bit 2 & 3 → Hold Mode
    value |= (config.holdMode.index & 0x03) << 2;

    // Bit 4 → Reset Allowed (REVERSED LOGIC)
    if (config.resetAllowed) {
      value |= 0x10;
    }

    // Bit 5 → Flow Detection
    if (config.flowDetectionUsed) {
      value |= 0x20;
    }

    return value;
  }

  static String encodeHex(ZoneModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODER =================
  static ZoneModeConfig decode(int value) {
    return ZoneModeConfig(
      zoneEnable:
          (value & 0x01) != 0 ? ZoneEnable.enabled : ZoneEnable.disabled,

      zoneMode: (value & 0x02) != 0 ? ZoneMode.test : ZoneMode.normal,

      holdMode: HoldMode.values[(value >> 2) & 0x03],

      // reversed firmware logic
      resetAllowed: (value & 0x10) != 0,

      flowDetectionUsed: (value & 0x20) != 0,
    );
  }
}
