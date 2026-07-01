enum ExtZoneEnable { disabled, enabled }

enum ExtZoneMode { normal, test }

enum HoldMode { notUsed, restartCount, suspendCount, continueCount }

class ExtZoneModeConfig {
  final ExtZoneEnable extZoneEnable;
  final ExtZoneMode extZoneMode;
  final HoldMode holdMode;
  final bool resetAllowed;
  final bool flowDetectionUsed;

  const ExtZoneModeConfig({
    required this.extZoneEnable,
    required this.extZoneMode,
    required this.holdMode,
    required this.resetAllowed,
    required this.flowDetectionUsed,
  });

  @override
  String toString() {
    return '''
Zone Enable        : $extZoneEnable
Zone Mode          : $extZoneMode
Hold Mode          : $holdMode
Reset Allowed      : $resetAllowed
Flow Detection     : $flowDetectionUsed
''';
  }
}

class ExtZoneModeCodec {
  static int encode(ExtZoneModeConfig config) {
    int value = 0;

    if (config.extZoneEnable == ExtZoneEnable.enabled) {
      value |= 0x01;
    }

    if (config.extZoneMode == ExtZoneMode.test) {
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

  static String encodeHex(ExtZoneModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static ExtZoneModeConfig decode(int value) {
    return ExtZoneModeConfig(
      extZoneEnable:
          (value & 0x01) != 0 ? ExtZoneEnable.enabled : ExtZoneEnable.disabled,

      extZoneMode: (value & 0x02) != 0 ? ExtZoneMode.test : ExtZoneMode.normal,

      holdMode: HoldMode.values[(value >> 2) & 0x03],

      resetAllowed: (value & 0x10) != 0,

      flowDetectionUsed: (value & 0x20) != 0,
    );
  }

  static ExtZoneModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
