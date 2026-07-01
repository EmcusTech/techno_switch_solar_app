enum EquipmentEnable { disabled, enabled }

enum EquipmentMode { normal, test }

enum SounderDelay { disabled, enabled }

enum SilenceCapability { cannotSilence, canSilence }

enum WalkTestActivation { noActivation, activate }

class GeneralEquipmentModeConfig {
  final EquipmentEnable equipmentEnable;
  final EquipmentMode equipmentMode;
  final SounderDelay sounderDelay;
  final SilenceCapability silenceCapability;
  final WalkTestActivation walkTestActivation;

  const GeneralEquipmentModeConfig({
    required this.equipmentEnable,
    required this.equipmentMode,
    required this.sounderDelay,

    this.silenceCapability = SilenceCapability.canSilence,
    this.walkTestActivation = WalkTestActivation.activate,
  });

  @override
  String toString() {
    return '''
Equipment Enable : $equipmentEnable
Equipment Mode   : $equipmentMode
Sounder Delay    : $sounderDelay
(Default → Silence Allowed, WalkTest Activated)
''';
  }
}

class GeneralEquipmentModeCodec {
  static const int _defaultSilence = 0x04;
  static const int _defaultWalkTest = 0x08;

  static int encode(GeneralEquipmentModeConfig config) {
    int value = 0;
    value |= _defaultSilence;
    value |= _defaultWalkTest;

    if (config.equipmentEnable == EquipmentEnable.enabled) {
      value |= 0x01;
    }

    if (config.equipmentMode == EquipmentMode.test) {
      value |= 0x02;
    }

    if (config.sounderDelay == SounderDelay.enabled) {
      value |= 0x20;
    }

    return value & 0xFF;
  }

  static String encodeHex(GeneralEquipmentModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  static GeneralEquipmentModeConfig decode(int value) {
    return GeneralEquipmentModeConfig(
      equipmentEnable:
          (value & 0x01) != 0
              ? EquipmentEnable.enabled
              : EquipmentEnable.disabled,

      equipmentMode:
          (value & 0x02) != 0 ? EquipmentMode.test : EquipmentMode.normal,

      sounderDelay:
          (value & 0x20) != 0 ? SounderDelay.enabled : SounderDelay.disabled,
    );
  }

  static GeneralEquipmentModeConfig fromHex(String hex) {
    final int value = int.parse(hex, radix: 16);
    return decode(value);
  }
}
