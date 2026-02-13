// =============================
// ZONE MODE BITMASK
// =============================

enum ZoneEnable { disabled, enabled }

enum ZoneTestMode { normal, test }

/// Bits 3 & 4 combined (2-bit field)
enum ZoneType {
  normal, // 0
  isMtl5561, // 1
  notUsed, // 2
}

class ZoneModeConfig {
  final ZoneEnable zoneEnable;
  final ZoneTestMode zoneTestMode;

  /// Always latched (bit 2 = 1)
  /// Firmware default behaviour — not user changeable
  final bool latched;

  final ZoneType zoneType;

  const ZoneModeConfig({
    required this.zoneEnable,
    required this.zoneTestMode,
    required this.zoneType,
    this.latched = true, // Always true as per requirement
  });

  @override
  String toString() {
    return '''
Zone Enable : $zoneEnable
Zone Mode   : $zoneTestMode
Latched     : $latched
Zone Type   : $zoneType
''';
  }
}

class ZoneModeCodec {
  // ================= ENCODE =================
  static int encode(ZoneModeConfig config) {
    int value = 0;

    // Bit 0
    if (config.zoneEnable == ZoneEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1
    if (config.zoneTestMode == ZoneTestMode.test) {
      value |= 0x02;
    }

    // Bit 2 (Always latched)
    if (config.latched) {
      value |= 0x04;
    }

    // Bits 3 & 4 (2-bit field)
    value |= (config.zoneType.index & 0x03) << 3;

    return value & 0xFF;
  }

  static String encodeHex(ZoneModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODE =================
  static ZoneModeConfig decode(int value) {
    return ZoneModeConfig(
      zoneEnable:
          (value & 0x01) != 0 ? ZoneEnable.enabled : ZoneEnable.disabled,

      zoneTestMode:
          (value & 0x02) != 0 ? ZoneTestMode.test : ZoneTestMode.normal,

      latched: (value & 0x04) != 0,

      zoneType: ZoneType.values[(value >> 3) & 0x03],
    );
  }

  // ================= FROM HEX =================
  static ZoneModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
