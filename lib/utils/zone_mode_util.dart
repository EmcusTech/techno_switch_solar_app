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

    if (config.zoneEnable == ZoneEnable.enabled) {
      value |= 0x01;
    }

    if (config.zoneMode == ZoneMode.test) {
      value |= 0x02;
    }

    value |= (config.holdMode.index & 0x03) << 2;

    if (config.resetAllowed) {
      value |= 0x10;
    }

    if (config.flowDetectionUsed) {
      value |= 0x20;
    }

    return value & 0xFF;
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

      resetAllowed: (value & 0x10) != 0,

      flowDetectionUsed: (value & 0x20) != 0,
    );
  }

  // ================= NEW HELPER =================
  /// Create ZoneModeConfig directly from HEX string (e.g. "12")
  static ZoneModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
