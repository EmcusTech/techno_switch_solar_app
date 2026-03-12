// ==========================================
// GENERAL EQUIPMENT MODE BITMASK
// Only 3 fields configurable
// ==========================================

enum EquipmentEnable { disabled, enabled }

enum EquipmentMode { normal, test }

enum SounderDelay { disabled, enabled }

// Defaults (not user configurable)
enum SilenceCapability { cannotSilence, canSilence }

enum WalkTestActivation { noActivation, activate }

class GeneralEquipmentModeConfig {
  final EquipmentEnable equipmentEnable;
  final EquipmentMode equipmentMode;
  final SounderDelay sounderDelay;

  // Fixed defaults
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
  // Default bits
  static const int _defaultSilence = 0x04; // Bit 2
  static const int _defaultWalkTest = 0x08; // Bit 3

  // ================= ENCODER =================
  static int encode(GeneralEquipmentModeConfig config) {
    int value = 0;

    // Apply defaults
    value |= _defaultSilence;
    value |= _defaultWalkTest;

    // Bit 0
    if (config.equipmentEnable == EquipmentEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1
    if (config.equipmentMode == EquipmentMode.test) {
      value |= 0x02;
    }

    // Bit 5
    if (config.sounderDelay == SounderDelay.enabled) {
      value |= 0x20;
    }

    return value & 0xFF;
  }

  static String encodeHex(GeneralEquipmentModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODER =================
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

// ================= DEMO =================

void main() {
  print("========= GENERAL EQUIPMENT MODE =========\n");

  final config = GeneralEquipmentModeConfig(
    equipmentEnable: EquipmentEnable.enabled,
    equipmentMode: EquipmentMode.test,
    sounderDelay: SounderDelay.enabled,
  );

  final hex = GeneralEquipmentModeCodec.encodeHex(config);

  print(config);
  print("Generated HEX → $hex\n");

  print("========= DECODE TEST =========\n");

  final decoded = GeneralEquipmentModeCodec.fromHex(hex);

  print(decoded);
}
