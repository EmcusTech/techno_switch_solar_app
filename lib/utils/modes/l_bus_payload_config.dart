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

class LBusPayloadIndices {
  LBusPayloadIndices._();

  static const int repeaterStatus = 17;
  static const int deviceTextLength = 22;
  static const int deviceTextStart = 23;
  static const int enabledBusDataId = 15;
  static const int enabledBusDataRevision = 16;
  static const int enabledBusDataProductRevStart = 17;
  static const int enabledBusDataHardwareStart = 30;
  static const int enabledBusDataFirmwareStart = 34;
  static const int enabledBusDataDateYearHi = 38;
  static const int enabledBusDataDateYearLo = 39;
  static const int enabledBusDataDateMonth = 40;
  static const int enabledBusDataDateDay = 41;
  static const int enabledBusDataProtocol = 43;
}
