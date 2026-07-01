import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/modes/relay_mode_util.dart';

OutputModeConfig _relaySupervisionFromExistingHex(String hex) {
  try {
    if (hex.isEmpty) {
      return const OutputModeConfig(
        outputEnable: OutputEnable.disabled,
        outputMode: OutputMode.normal,
        supervisionMode: SupervisionMode.normal,
      );
    }
    return OutputModeCodec.fromHex(hex);
  } catch (_) {
    return const OutputModeConfig(
      outputEnable: OutputEnable.disabled,
      outputMode: OutputMode.normal,
      supervisionMode: SupervisionMode.normal,
    );
  }
}

// ─── Relay (setup) ───

void applyRelayTestFlagsFromCacheMap(
  BleManager manager,
  Map<String, dynamic> data,
) {
  for (int i = 0; i < 3; i++) {
    final r = data['r${i + 1}'] as Map<String, dynamic>?;
    if (r == null) continue;
    final test = (r['test'] as bool?) == true;
    switch (i) {
      case 0:
        manager.isRelayOneSetupTest.value = test;
        break;
      case 1:
        manager.isRelayTwoSetupTest.value = test;
        break;
      case 2:
        manager.isRelayThreeSetupTest.value = test;
        break;
    }
  }
}

void syncRelayOutputModeHexFromBleManager(BleManager m) {
  for (int i = 0; i < 3; i++) {
    final String hexIn = switch (i) {
      0 => m.relayOneMode.value,
      1 => m.relayTwoMode.value,
      2 => m.relayThreeMode.value,
      _ => '',
    };
    final decoded = _relaySupervisionFromExistingHex(hexIn);
    final bool isEnabled = switch (i) {
      0 => m.isRelayOneSetupEnabled.value,
      1 => m.isRelayTwoSetupEnabled.value,
      2 => m.isRelayThreeSetupEnabled.value,
      _ => false,
    };
    final bool isTest = switch (i) {
      0 => m.isRelayOneSetupTest.value,
      1 => m.isRelayTwoSetupTest.value,
      2 => m.isRelayThreeSetupTest.value,
      _ => false,
    };
    final config = OutputModeConfig(
      outputEnable: isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
      outputMode: isTest ? OutputMode.test : OutputMode.normal,
      supervisionMode: decoded.supervisionMode,
    );
    final out = OutputModeCodec.encodeHex(config);
    switch (i) {
      case 0:
        m.relayOneMode.value = out;
        break;
      case 1:
        m.relayTwoMode.value = out;
        break;
      case 2:
        m.relayThreeMode.value = out;
        break;
    }
  }
}

void clearRelayTestOnManager(BleManager manager, int relayIndex) {
  switch (relayIndex) {
    case 0:
      manager.isRelayOneSetupTest.value = false;
      break;
    case 1:
      manager.isRelayTwoSetupTest.value = false;
      break;
    case 2:
      manager.isRelayThreeSetupTest.value = false;
      break;
  }
}

void setRelayTestOnManager(BleManager manager, int relayIndex, bool test) {
  switch (relayIndex) {
    case 0:
      manager.isRelayOneSetupTest.value = test;
      break;
    case 1:
      manager.isRelayTwoSetupTest.value = test;
      break;
    case 2:
      manager.isRelayThreeSetupTest.value = test;
      break;
  }
}

void setRelayEnabledOnManager(
  BleManager manager,
  int relayIndex,
  bool enabled,
) {
  switch (relayIndex) {
    case 0:
      manager.isRelayOneSetupEnabled.value = enabled;
      break;
    case 1:
      manager.isRelayTwoSetupEnabled.value = enabled;
      break;
    case 2:
      manager.isRelayThreeSetupEnabled.value = enabled;
      break;
  }
}

// ─── Sounder (main outputs SNDR 1–3) ───

void applySounderMainTestFlagsFromCacheMap(
  BleManager manager,
  Map<String, dynamic> data,
) {
  for (int i = 0; i < 3; i++) {
    final s = data['s${i + 1}'] as Map<String, dynamic>?;
    if (s == null) continue;
    final test = (s['test'] as bool?) ?? false;
    switch (i) {
      case 0:
        manager.isSounderOneTest.value = test;
        break;
      case 1:
        manager.isSounderTwoTest.value = test;
        break;
      case 2:
        manager.isSounderThreeTest.value = test;
        break;
    }
  }
}

void syncSounderMainOutputModeHexFromBleManager(BleManager m) {
  for (int i = 0; i < 3; i++) {
    final bool isEnabled = switch (i) {
      0 => m.isSounderOneEnabled.value,
      1 => m.isSounderTwoEnabled.value,
      2 => m.isSounderThreeEnabled.value,
      _ => false,
    };
    final bool isTest = switch (i) {
      0 => m.isSounderOneTest.value,
      1 => m.isSounderTwoTest.value,
      2 => m.isSounderThreeTest.value,
      _ => false,
    };
    final bool isNormal = switch (i) {
      0 => m.isSounderOneNormal.value,
      1 => m.isSounderTwoNormal.value,
      2 => m.isSounderThreeNormal.value,
      _ => true,
    };
    final config = OutputModeConfig(
      outputEnable: isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
      outputMode: isTest ? OutputMode.test : OutputMode.normal,
      supervisionMode:
          isNormal ? SupervisionMode.normal : SupervisionMode.mtl5525,
    );
    final out = OutputModeCodec.encodeHex(config);
    switch (i) {
      case 0:
        m.sounderOneRelayOutputMode.value = out;
        break;
      case 1:
        m.sounderTwoRelayOutputMode.value = out;
        break;
      case 2:
        m.sounderThreeRelayOutputMode.value = out;
        break;
    }
  }
}

void clearSounderMainTestOnManager(BleManager manager, int sounderIndex) {
  switch (sounderIndex) {
    case 0:
      manager.isSounderOneTest.value = false;
      break;
    case 1:
      manager.isSounderTwoTest.value = false;
      break;
    case 2:
      manager.isSounderThreeTest.value = false;
      break;
  }
}

void setSounderMainTestOnManager(
  BleManager manager,
  int sounderIndex,
  bool test,
) {
  switch (sounderIndex) {
    case 0:
      manager.isSounderOneTest.value = test;
      break;
    case 1:
      manager.isSounderTwoTest.value = test;
      break;
    case 2:
      manager.isSounderThreeTest.value = test;
      break;
  }
}

void setSounderMainEnabledOnManager(
  BleManager manager,
  int sounderIndex,
  bool enabled,
) {
  switch (sounderIndex) {
    case 0:
      manager.isSounderOneEnabled.value = enabled;
      break;
    case 1:
      manager.isSounderTwoEnabled.value = enabled;
      break;
    case 2:
      manager.isSounderThreeEnabled.value = enabled;
      break;
  }
}
