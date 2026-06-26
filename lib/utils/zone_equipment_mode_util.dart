enum ZoneEquipmentEnable { disabled, enabled }

enum ZoneEquipmentMode { normal, test }

enum ZoneSounderDelay { disabled, enabled }

enum ZoneSilenceCapability { cannotSilence, canSilence }

enum ZoneWalkTestActivation { noActivation, activate }

class ZoneEquipmentModeConfig {
  final ZoneEquipmentEnable zoneEnable;
  final ZoneEquipmentMode zoneMode;
  final ZoneSounderDelay sounderDelay;
  final ZoneSilenceCapability silenceCapability;
  final ZoneWalkTestActivation walkTestActivation;

  const ZoneEquipmentModeConfig({
    required this.zoneEnable,
    required this.zoneMode,
    required this.sounderDelay,
    this.silenceCapability = ZoneSilenceCapability.canSilence,
    this.walkTestActivation = ZoneWalkTestActivation.activate,
  });

  @override
  String toString() {
    return '''
Zone Enable     : $zoneEnable
Zone Mode       : $zoneMode
Sounder Delay   : $sounderDelay
(Default → Silence Allowed, WalkTest Activated)
''';
  }
}

class ZoneEquipmentModeCodec {
  static const int _defaultSilence = 0x04;
  static const int _defaultWalkTest = 0x08;
  static int encode(ZoneEquipmentModeConfig config) {
    int value = 0;

    value |= _defaultSilence;
    value |= _defaultWalkTest;

    if (config.zoneEnable == ZoneEquipmentEnable.enabled) {
      value |= 0x01;
    }

    if (config.zoneMode == ZoneEquipmentMode.test) {
      value |= 0x02;
    }

    if (config.sounderDelay == ZoneSounderDelay.enabled) {
      value |= 0x20;
    }

    return value & 0xFF;
  }

  static String encodeHex(ZoneEquipmentModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static ZoneEquipmentModeConfig decode(int value) {
    return ZoneEquipmentModeConfig(
      zoneEnable:
          (value & 0x01) != 0
              ? ZoneEquipmentEnable.enabled
              : ZoneEquipmentEnable.disabled,

      zoneMode:
          (value & 0x02) != 0
              ? ZoneEquipmentMode.test
              : ZoneEquipmentMode.normal,

      sounderDelay:
          (value & 0x20) != 0
              ? ZoneSounderDelay.enabled
              : ZoneSounderDelay.disabled,
    );
  }

  static ZoneEquipmentModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
