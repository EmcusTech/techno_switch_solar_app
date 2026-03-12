// ==========================================
// ZONE EQUIPMENT MODE BITMASK
// Only 3 fields configurable
// ==========================================

enum ZoneEquipmentEnable { disabled, enabled }

enum ZoneEquipmentMode { normal, test }

enum ZoneSounderDelay { disabled, enabled }

// Defaults (not configurable)
enum ZoneSilenceCapability { cannotSilence, canSilence }

enum ZoneWalkTestActivation { noActivation, activate }

class ZoneEquipmentModeConfig {
  final ZoneEquipmentEnable zoneEnable;
  final ZoneEquipmentMode zoneMode;
  final ZoneSounderDelay sounderDelay;

  // Fixed defaults
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
  // Default bits
  static const int _defaultSilence = 0x04; // Bit 2
  static const int _defaultWalkTest = 0x08; // Bit 3

  // ================= ENCODER =================
  static int encode(ZoneEquipmentModeConfig config) {
    int value = 0;

    // Apply defaults first
    value |= _defaultSilence;
    value |= _defaultWalkTest;

    // Bit 0
    if (config.zoneEnable == ZoneEquipmentEnable.enabled) {
      value |= 0x01;
    }

    // Bit 1
    if (config.zoneMode == ZoneEquipmentMode.test) {
      value |= 0x02;
    }

    // Bit 5
    if (config.sounderDelay == ZoneSounderDelay.enabled) {
      value |= 0x20;
    }

    return value & 0xFF;
  }

  static String encodeHex(ZoneEquipmentModeConfig config) {
    return encode(config).toRadixString(16).toUpperCase().padLeft(2, '0');
  }

  // ================= DECODER =================
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

// ================= DEMO =================

void main() {
  print("========= ZONE EQUIPMENT MODE =========\n");

  final config = ZoneEquipmentModeConfig(
    zoneEnable: ZoneEquipmentEnable.enabled,
    zoneMode: ZoneEquipmentMode.test,
    sounderDelay: ZoneSounderDelay.enabled,
  );

  final hex = ZoneEquipmentModeCodec.encodeHex(config);

  print(config);
  print("Generated HEX → $hex\n");

  print("========= DECODE TEST =========\n");

  final decoded = ZoneEquipmentModeCodec.fromHex(hex);

  print(decoded);
}
