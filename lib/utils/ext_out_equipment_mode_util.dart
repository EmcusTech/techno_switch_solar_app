enum ExtZoneEquipmentEnable { disabled, enabled }

enum ExtZoneEquipmentMode { normal, test }

class ExtZoneEquipmentModeConfig {
  final ExtZoneEquipmentEnable zoneEnable;
  final ExtZoneEquipmentMode zoneMode;

  const ExtZoneEquipmentModeConfig({
    required this.zoneEnable,
    required this.zoneMode,
  });

  @override
  String toString() {
    return '''
Ext Zone Enable : $zoneEnable
Ext Zone Mode   : $zoneMode
(Default → SounderDelay Enabled)
(Bits 2,3,4 N/A)
''';
  }
}

class ExtZoneEquipmentModeCodec {
  static const int _defaultSounderDelay = 0x20;
  static int encode(ExtZoneEquipmentModeConfig config) {
    int value = 0;
    value |= _defaultSounderDelay;

    if (config.zoneEnable == ExtZoneEquipmentEnable.enabled) {
      value |= 0x01;
    }

    if (config.zoneMode == ExtZoneEquipmentMode.test) {
      value |= 0x02;
    }

    return value & 0xFF;
  }

  static String encodeHex(ExtZoneEquipmentModeConfig config) {
    return (encode(config) + 4).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static ExtZoneEquipmentModeConfig decode(int value) {
    return ExtZoneEquipmentModeConfig(
      zoneEnable:
          (value & 0x01) != 0
              ? ExtZoneEquipmentEnable.enabled
              : ExtZoneEquipmentEnable.disabled,

      zoneMode:
          (value & 0x02) != 0
              ? ExtZoneEquipmentMode.test
              : ExtZoneEquipmentMode.normal,
    );
  }

  static ExtZoneEquipmentModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}

void main() {
  print("========= EXT ZONE EQUIPMENT MODE =========\n");

  final config = ExtZoneEquipmentModeConfig(
    zoneEnable: ExtZoneEquipmentEnable.enabled,
    zoneMode: ExtZoneEquipmentMode.normal,
  );

  final hex = ExtZoneEquipmentModeCodec.encodeHex(config);

  print(config);
  print("Generated HEX → $hex\n");

  print("========= DECODE TEST =========\n");

  final decoded = ExtZoneEquipmentModeCodec.fromHex(hex);
  print(decoded);
}
