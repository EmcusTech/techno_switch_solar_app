enum ZoneEnable { disabled, enabled }

enum ZoneTestMode { normal, test }

enum ZoneType { normal, isMtl5561, notUsed }

class ZoneModeConfig {
  final ZoneEnable zoneEnable;
  final ZoneTestMode zoneTestMode;
  final bool latched;

  final ZoneType zoneType;

  const ZoneModeConfig({
    required this.zoneEnable,
    required this.zoneTestMode,
    required this.zoneType,
    this.latched = true,
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
  static int encode(ZoneModeConfig config) {
    int value = 0;

    if (config.zoneEnable == ZoneEnable.enabled) {
      value |= 0x01;
    }

    if (config.zoneTestMode == ZoneTestMode.test) {
      value |= 0x02;
    }

    if (config.latched) {
      value |= 0x04;
    }

    value |= (config.zoneType.index & 0x03) << 3;

    return value & 0xFF;
  }

  static String encodeHex(ZoneModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

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

  static ZoneModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
