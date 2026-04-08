import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/utils/config_map_diff.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_bundle.dart';

/// Option lists aligned with peripheral bottom sheets (relay / input / zone / sounder / ext out).
class _RelayOpts {
  static const List<String> group = ['None', 'General', 'Zone', 'Ext. Out'];
  static const Map<String, List<String>> functions = {
    'None': ['None'],
    'General': [
      'Fault',
      'Extnl. Fault',
      'Supply Fault',
      'Extnl. Supply Fault',
      'Sounder Fault',
      'Sounder Silenced',
      'Sounder Activated',
      'Sounder Disabled',
      'Disablement',
      'Test',
      'Fire',
      'Reset',
      'Controls Enabled',
      'Supervisory',
      'Fire Snd',
    ],
    'Zone': ['Fault', 'Fire', 'Disablement', 'Fire Snd'],
    'Ext. Out': [
      'Release Initiated',
      'Ext. Agent Released',
      'Release Hold',
      'Manual Mode',
      'Manual Release',
      'Extnl. Ext. Fault',
      'Ext. Snd 1',
      'Ext. Snd 2',
      'Man. Release Snd',
    ],
  };
}

class _InputOpts {
  static const List<String> group = ['None', 'General', 'Ext. Out'];
  static const Map<String, List<String>> functions = {
    'None': ['None'],
    'General': [
      'Extnl. Fault',
      'Reset',
      'Extnl. Controls Enabled',
      'Silence Alarm',
      'Sound Alarm',
      'Silence Buzzer',
      'Mute',
      'Extnl. Supervisory',
      'Extnl. Supply Fault',
    ],
    'Ext. Out': [
      'Manual Trigger',
      'Manual Mode',
      'Hold',
      'Extnl. Disable Gas',
      'Extnl. Ext. Fault',
    ],
  };
}

class _SounderOpts {
  static const List<String> group = ['None', 'General', 'Zone', 'Ext. Out'];
  static const Map<String, List<String>> functions = {
    'None': ['None'],
    'General': ['Fire Snd'],
    'Zone': ['Fire Snd'],
    'Ext. Out': ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'],
  };
  static const List<String> zoneActions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
  ];
  static const List<String> extOutActions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
    'Off',
  ];
}

class _ZoneOpts {
  static const List<String> types = ['Normal', 'IS (MTL 5561)'];
  static const List<String> modes = [
    'Immediate',
    'Normal',
    'Verified',
    'Confirmed',
  ];
}

class _ExtOutOpts {
  static const List<String> enabled = ['No', 'Yes'];
  static const List<String> resetInCount = ['Yes', 'No'];
  static const List<String> actuator = [
    'Not Defined',
    'Metron',
    'Solenoid',
    'Aerosol',
  ];
  static const List<String> function = [
    'Z1 and Z2',
    'Z2 and Z3',
    'Z1 and Z3',
    'Z1 and Z2 and Z3',
    'Z1',
    'Z2',
    'Z3',
    'Any 2 zones',
    'Any 1 zone',
  ];
  static const List<String> hold = [
    'Disabled',
    'Restart',
    'Suspend',
    'Continue',
  ];
  static const List<String> action = [
    'Continous',
    'Pulse 100ms On',
    'Pulse 300ms On',
    'Pulse 600ms On',
    'Pulse 1s On',
    'Pulse 5s On',
    'Pulsing 100ms On, 500ms Off',
    'Pulsing 300ms On, 1.5s Off',
    'Pulsing 600ms On, 3s Off',
    'Pulsing 1s On, 5s Off',
  ];
}

num? _parseNum(Object? v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

bool? _parseBool(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}

String _idx(List<String> options, num? i, {String fallback = '?'}) {
  if (i == null) return fallback;
  final n = i.round();
  if (n < 0 || n >= options.length) return '$fallback (index $n)';
  return options[n];
}

String _relayFunctionLabel(num groupIdx, num? funcIdx) {
  final g = _idx(_RelayOpts.group, groupIdx);
  final list = _RelayOpts.functions[g] ?? const ['?'];
  return _idx(list, funcIdx);
}

String _inputFunctionLabel(num groupIdx, num? funcIdx) {
  final g = _idx(_InputOpts.group, groupIdx);
  final list = _InputOpts.functions[g] ?? const ['?'];
  return _idx(list, funcIdx);
}

String _sounderFunctionLabel(num groupIdx, num? funcIdx) {
  final g = _idx(_SounderOpts.group, groupIdx);
  final list = _SounderOpts.functions[g] ?? const ['?'];
  return _idx(list, funcIdx);
}

/// Rewrites [diff] local/remote strings to labels where paths map to dropdowns.
ConfigMapDiff applyDisplayLabelsForSection(
  ConfigMapDiff diff,
  String sectionTitle,
  PeripheralConfigBundle baseline,
  PeripheralConfigBundle panel,
) {
  switch (sectionTitle) {
    case 'Relays':
      return _labelRelay(diff, baseline.relays, panel.relays);
    case 'Inputs':
      return _labelInput(diff, baseline.inputs, panel.inputs);
    case 'Zones':
      return _labelZones(diff, baseline.zones, panel.zones);
    case 'Sounders':
      return _labelSounders(diff, baseline.sounders, panel.sounders);
    case 'Ext Out':
      return _labelExtOut(diff);
    case 'Service Due':
      return _labelServiceDue(diff);
    case 'Access Code':
      return _labelAccessCodes(diff);
    case 'Walk Test':
      return _labelWalkTest(diff);
    default:
      return _labelBools(diff);
  }
}

ConfigMapDiff _labelRelay(
  ConfigMapDiff diff,
  Map<String, dynamic> br,
  Map<String, dynamic> pr,
) {
  final parts = diff.path.split('.');
  if (parts.length != 2) return _labelBools(diff);
  final rowKey = parts[0];
  final field = parts[1];
  final bRow = Map<String, dynamic>.from(br[rowKey] as Map? ?? {});
  final pRow = Map<String, dynamic>.from(pr[rowKey] as Map? ?? {});

  if (field == 'group') {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_RelayOpts.group, _parseNum(diff.local)),
      remote: _idx(_RelayOpts.group, _parseNum(diff.remote)),
    );
  }
  if (field == 'function') {
    return ConfigMapDiff(
      path: diff.path,
      local: _relayFunctionLabel(
        _parseNum(bRow['group']) ?? 0,
        _parseNum(diff.local),
      ),
      remote: _relayFunctionLabel(
        _parseNum(pRow['group']) ?? 0,
        _parseNum(diff.remote),
      ),
    );
  }
  if (field == 'enabled' || field == 'test') {
    return ConfigMapDiff(
      path: diff.path,
      local: _yesNo(_parseBool(diff.local)),
      remote: _yesNo(_parseBool(diff.remote)),
    );
  }
  return diff;
}

String _yesNo(bool? v) {
  if (v == null) return 'null';
  return v ? 'Yes' : 'No';
}

ConfigMapDiff _labelInput(
  ConfigMapDiff diff,
  Map<String, dynamic> b,
  Map<String, dynamic> p,
) {
  final field = diff.path;
  if (field == 'group') {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_InputOpts.group, _parseNum(diff.local)),
      remote: _idx(_InputOpts.group, _parseNum(diff.remote)),
    );
  }
  if (field == 'function') {
    return ConfigMapDiff(
      path: diff.path,
      local: _inputFunctionLabel(
        _parseNum(b['group']) ?? 0,
        _parseNum(diff.local),
      ),
      remote: _inputFunctionLabel(
        _parseNum(p['group']) ?? 0,
        _parseNum(diff.remote),
      ),
    );
  }
  if (field == 'enabled' || field == 'test' || field == 'inverted') {
    return ConfigMapDiff(
      path: diff.path,
      local: _yesNo(_parseBool(diff.local)),
      remote: _yesNo(_parseBool(diff.remote)),
    );
  }
  return diff;
}

ConfigMapDiff _labelZones(
  ConfigMapDiff diff,
  Map<String, dynamic> bz,
  Map<String, dynamic> pz,
) {
  final parts = diff.path.split('.');
  if (parts.length != 2) return _labelBools(diff);
  final zk = parts[0];
  final field = parts[1];
  if (field == 'type') {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_ZoneOpts.types, _parseNum(diff.local)),
      remote: _idx(_ZoneOpts.types, _parseNum(diff.remote)),
    );
  }
  if (field == 'detectionMode') {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_ZoneOpts.modes, _parseNum(diff.local)),
      remote: _idx(_ZoneOpts.modes, _parseNum(diff.remote)),
    );
  }
  if (field == 'enabled' || field == 'test') {
    final bRow = Map<String, dynamic>.from(bz[zk] as Map? ?? {});
    final pRow = Map<String, dynamic>.from(pz[zk] as Map? ?? {});
    return ConfigMapDiff(
      path: diff.path,
      local: _yesNo(_parseBool(bRow[field]) ?? _parseBool(diff.local)),
      remote: _yesNo(_parseBool(pRow[field]) ?? _parseBool(diff.remote)),
    );
  }
  return _labelBools(diff);
}

ConfigMapDiff _labelSounders(
  ConfigMapDiff diff,
  Map<String, dynamic> bs,
  Map<String, dynamic> ps,
) {
  final parts = diff.path.split('.');
  if (parts.length != 2) return _labelBools(diff);
  final key = parts[0];
  final field = parts[1];
  final bRow = Map<String, dynamic>.from(bs[key] as Map? ?? {});
  final pRow = Map<String, dynamic>.from(ps[key] as Map? ?? {});

  if (key.startsWith('s')) {
    if (field == 'group') {
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_SounderOpts.group, _parseNum(diff.local)),
        remote: _idx(_SounderOpts.group, _parseNum(diff.remote)),
      );
    }
    if (field == 'function') {
      return ConfigMapDiff(
        path: diff.path,
        local: _sounderFunctionLabel(
          _parseNum(bRow['group']) ?? 0,
          _parseNum(diff.local),
        ),
        remote: _sounderFunctionLabel(
          _parseNum(pRow['group']) ?? 0,
          _parseNum(diff.remote),
        ),
      );
    }
    if (field == 'enabled' || field == 'test' || field == 'normal') {
      return ConfigMapDiff(
        path: diff.path,
        local: _yesNo(_parseBool(diff.local)),
        remote: _yesNo(_parseBool(diff.remote)),
      );
    }
  }
  if (key.startsWith('z') && field == 'action') {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_SounderOpts.zoneActions, _parseNum(diff.local)),
      remote: _idx(_SounderOpts.zoneActions, _parseNum(diff.remote)),
    );
  }
  if (key.startsWith('e') && (field == 'countdownAction' || field == 'holdAction' || field == 'releaseAction')) {
    return ConfigMapDiff(
      path: diff.path,
      local: _idx(_SounderOpts.extOutActions, _parseNum(diff.local)),
      remote: _idx(_SounderOpts.extOutActions, _parseNum(diff.remote)),
    );
  }
  if (key == 'general') {
    if (field == 'action') {
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_SounderOpts.zoneActions, _parseNum(diff.local)),
        remote: _idx(_SounderOpts.zoneActions, _parseNum(diff.remote)),
      );
    }
    if (field == 'enabled' || field == 'test' || field == 'delayed') {
      return ConfigMapDiff(
        path: diff.path,
        local: _yesNo(_parseBool(diff.local)),
        remote: _yesNo(_parseBool(diff.remote)),
      );
    }
  }
  return _labelBools(diff);
}

ConfigMapDiff _labelExtOut(ConfigMapDiff diff) {
  final f = diff.path;
  switch (f) {
    case 'enabled':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.enabled, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.enabled, _parseNum(diff.remote)),
      );
    case 'actuatorType':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.actuator, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.actuator, _parseNum(diff.remote)),
      );
    case 'function':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.function, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.function, _parseNum(diff.remote)),
      );
    case 'resetAllowed':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.resetInCount, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.resetInCount, _parseNum(diff.remote)),
      );
    case 'holdMode':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.hold, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.hold, _parseNum(diff.remote)),
      );
    case 'action':
      return ConfigMapDiff(
        path: diff.path,
        local: _idx(_ExtOutOpts.action, _parseNum(diff.local)),
        remote: _idx(_ExtOutOpts.action, _parseNum(diff.remote)),
      );
    case 'isSolar':
      return ConfigMapDiff(
        path: diff.path,
        local: _yesNo(_parseBool(diff.local)),
        remote: _yesNo(_parseBool(diff.remote)),
      );
    default:
      return diff;
  }
}

ConfigMapDiff _labelServiceDue(ConfigMapDiff diff) {
  if (diff.path == 'reminder') {
    return ConfigMapDiff(
      path: diff.path,
      local: (_parseNum(diff.local) == 1) ? 'On' : 'Off',
      remote: (_parseNum(diff.remote) == 1) ? 'On' : 'Off',
    );
  }
  return diff;
}

ConfigMapDiff _labelAccessCodes(ConfigMapDiff diff) {
  if (!diff.path.contains('accessLevel')) return diff;
  final names = AccessCodeSetupData.accessLevelNames;
  String label(String s) {
    final i = int.tryParse(s);
    if (i != null && i >= 0 && i < names.length) return names[i];
    return s;
  }

  return ConfigMapDiff(path: diff.path, local: label(diff.local), remote: label(diff.remote));
}

ConfigMapDiff _labelWalkTest(ConfigMapDiff diff) {
  return ConfigMapDiff(
    path: diff.path,
    local: _yesNo(_parseBool(diff.local)),
    remote: _yesNo(_parseBool(diff.remote)),
  );
}

/// Formats obvious booleans in [diff] as Yes/No when values parse as bool.
ConfigMapDiff _labelBools(ConfigMapDiff diff) {
  final lb = _parseBool(diff.local);
  final rb = _parseBool(diff.remote);
  if (lb != null && rb != null) {
    return ConfigMapDiff(
      path: diff.path,
      local: _yesNo(lb),
      remote: _yesNo(rb),
    );
  }
  return diff;
}

/// Applies [applyDisplayLabelsForSection] to every diff in a section.
List<ConfigMapDiff> labelSectionDiffs(
  String sectionTitle,
  List<ConfigMapDiff> diffs,
  PeripheralConfigBundle baseline,
  PeripheralConfigBundle panel,
) {
  return diffs
      .map(
        (d) => applyDisplayLabelsForSection(
          d,
          sectionTitle,
          baseline,
          panel,
        ),
      )
      .toList();
}
