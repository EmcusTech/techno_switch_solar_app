enum LBusRepeaterEnable { disabled, enabled }

enum LBusIdLed { off, on }

class LBusRepeaterStatusConfig {
  final LBusRepeaterEnable enable;
  final LBusIdLed idLed;

  const LBusRepeaterStatusConfig({required this.enable, required this.idLed});

  @override
  String toString() {
    return '''
Repeater Enable : $enable
ID LED         : $idLed
''';
  }
}

class LBusRepeaterStatusCodec {
  static const int enabledBitMask = 0x01;
  static const int idLedBitMask = 0x02;

  static LBusRepeaterStatusConfig decode(int value) {
    return LBusRepeaterStatusConfig(
      enable:
          (value & enabledBitMask) != 0
              ? LBusRepeaterEnable.enabled
              : LBusRepeaterEnable.disabled,
      idLed: (value & idLedBitMask) != 0 ? LBusIdLed.on : LBusIdLed.off,
    );
  }

  static int encode(LBusRepeaterStatusConfig config) {
    int value = 0;
    if (config.enable == LBusRepeaterEnable.enabled) value |= 0x01;
    if (config.idLed == LBusIdLed.on) value |= 0x02;
    return value & 0xFF;
  }

  static String encodeHex(LBusRepeaterStatusConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static LBusRepeaterStatusConfig fromHex(String hex) {
    return decode(int.parse(hex, radix: 16));
  }
}

/// Payload indices for L-Bus Setup Fetch (command 0x10)
class LBusPayloadIndices {
  LBusPayloadIndices._();

  /// Index 17: REPEATER_STATUS byte (bitwise flags)
  static const int repeaterStatus = 17;

  /// Index 22: L-Bus device text length (in bytes)
  static const int deviceTextLength = 22;

  /// Index 23: Start of L-Bus device text bytes
  /// Text: payload[23] ... payload[23 + length - 1]
  static const int deviceTextStart = 23;
}
