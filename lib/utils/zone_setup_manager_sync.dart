import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/zone_mode_util.dart';

/// Writes [z1]/[z2]/[z3] `test` booleans from cached zone setup into [manager].
void applyZoneTestFlagsFromCacheMap(
  BleManager manager,
  Map<String, dynamic> data,
) {
  for (int i = 0; i < 3; i++) {
    final z = data['z${i + 1}'] as Map<String, dynamic>?;
    if (z == null) continue;
    final test = (z['test'] as bool?) == true;
    switch (i) {
      case 0:
        manager.isZoneOneSetupTest.value = test;
        break;
      case 1:
        manager.isZoneTwoSetupTest.value = test;
        break;
      case 2:
        manager.isZoneThreeSetupTest.value = test;
        break;
    }
  }
}

/// Recomputes each zone mode hex from current enable / test / type on [manager].
void syncZoneModeHexFromBleManager(BleManager manager) {
  for (int i = 0; i < 3; i++) {
    final bool enabled;
    final bool test;
    final int typeIndex;
    switch (i) {
      case 0:
        enabled = manager.isZoneOneSetupEnabled.value;
        test = manager.isZoneOneSetupTest.value;
        typeIndex = manager.zoneOneSetupType.value;
        manager.zoneOneSetupMode.value = _encodeZoneModeHex(
          enabled,
          test,
          typeIndex,
        );
        break;
      case 1:
        enabled = manager.isZoneTwoSetupEnabled.value;
        test = manager.isZoneTwoSetupTest.value;
        typeIndex = manager.zoneTwoSetupType.value;
        manager.zoneTwoSetupMode.value = _encodeZoneModeHex(
          enabled,
          test,
          typeIndex,
        );
        break;
      case 2:
        enabled = manager.isZoneThreeSetupEnabled.value;
        test = manager.isZoneThreeSetupTest.value;
        typeIndex = manager.zoneThreeSetupType.value;
        manager.zoneThreeSetupMode.value = _encodeZoneModeHex(
          enabled,
          test,
          typeIndex,
        );
        break;
    }
  }
}

String _encodeZoneModeHex(bool enabled, bool test, int typeIndex) {
  final config = ZoneModeConfig(
    zoneEnable: enabled ? ZoneEnable.enabled : ZoneEnable.disabled,
    zoneTestMode: test ? ZoneTestMode.test : ZoneTestMode.normal,
    zoneType: typeIndex == 0 ? ZoneType.normal : ZoneType.isMtl5561,
  );
  return ZoneModeCodec.encodeHex(config);
}

void clearZoneTestOnManager(BleManager manager, int zoneIndex) {
  switch (zoneIndex) {
    case 0:
      manager.isZoneOneSetupTest.value = false;
      break;
    case 1:
      manager.isZoneTwoSetupTest.value = false;
      break;
    case 2:
      manager.isZoneThreeSetupTest.value = false;
      break;
  }
}

void setZoneTestOnManager(BleManager manager, int zoneIndex, bool test) {
  switch (zoneIndex) {
    case 0:
      manager.isZoneOneSetupTest.value = test;
      break;
    case 1:
      manager.isZoneTwoSetupTest.value = test;
      break;
    case 2:
      manager.isZoneThreeSetupTest.value = test;
      break;
  }
}

void setZoneEnabledOnManager(BleManager manager, int zoneIndex, bool enabled) {
  switch (zoneIndex) {
    case 0:
      manager.isZoneOneSetupEnabled.value = enabled;
      break;
    case 1:
      manager.isZoneTwoSetupEnabled.value = enabled;
      break;
    case 2:
      manager.isZoneThreeSetupEnabled.value = enabled;
      break;
  }
}
