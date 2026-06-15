import 'dart:convert';

import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';

class PeripheralConfigDiffLabels {
  PeripheralConfigDiffLabels._();

  static const List<String> _relayGroups = [
    'None',
    'General',
    'Zone',
    'Ext. Out',
  ];
  static const Map<String, List<String>> _relayFunctions = {
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

  static const List<String> _inputGroups = ['None', 'General', 'Ext. Out'];
  static const Map<String, List<String>> _inputFunctions = {
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

  static const List<String> _zoneTypes = ['Normal', 'IS (MTL 5561)'];
  static const List<String> _zoneModes = [
    'Immediate',
    'Normal',
    'Verified',
    'Confirmed',
  ];

  static const List<String> _extEnabled = ['No', 'Yes'];
  static const List<String> _extActuator = [
    'Not Defined',
    'Metron',
    'Solenoid',
    'Aerosol',
  ];
  static const List<String> _extFunction = [
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
  static const List<String> _extResetAllowed = ['Yes', 'No'];
  static const List<String> _extHold = [
    'Disabled',
    'Restart',
    'Suspend',
    'Continue',
  ];
  static const List<String> _extAction = [
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

  static const List<String> _sounderGroups = [
    'None',
    'General',
    'Zone',
    'Ext. Out',
  ];
  static const Map<String, List<String>> _sounderFunctions = {
    'None': ['None'],
    'General': ['Fire Snd'],
    'Zone': ['Fire Snd'],
    'Ext. Out': ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'],
  };
  static const List<String> _sounderZoneActions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
  ];
  static const List<String> _sounderExtActions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
    'Off',
  ];

  static Map<String, Object?>? _asMap(Object? o) =>
      o is Map ? Map<String, Object?>.from(o) : null;

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static String _pick(List<String> list, int? i) {
    if (i == null) return '—';
    if (i < 0 || i >= list.length) return '$i (out of range)';
    return list[i];
  }

  static String _yesNo(Object? v) {
    if (v is bool) return v ? 'Yes' : 'No';
    final i = _asInt(v);
    if (i == 0) return 'No';
    if (i == 1) return 'Yes';
    return _rawPreview(v);
  }

  static String _rawPreview(Object? v) {
    if (v == null) return '—';
    if (v is bool || v is num) return v.toString();
    try {
      final enc = jsonEncode(v);
      if (enc.length > 120) return '${enc.substring(0, 117)}…';
      return enc;
    } catch (_) {
      final s = v.toString();
      return s.length > 120 ? '${s.substring(0, 117)}…' : s;
    }
  }

  static String _relativePath(String path) {
    var p = path;
    while (RegExp(r'^\[(\d+)\]\.').hasMatch(p)) {
      p = p.substring(RegExp(r'^\[(\d+)\]\.').firstMatch(p)!.end);
    }
    return p;
  }

  static String? _listIndexPrefix(String sectionKey, String path) {
    final m = RegExp(r'^\[(\d+)\]\.').firstMatch(path);
    if (m == null) return null;
    final n = int.parse(m.group(1)!) + 1;
    switch (sectionKey) {
      case 'access_code':
        return 'Access code $n';
      case 'l_bus':
        return 'L-Bus device $n';
      default:
        return 'Item $n';
    }
  }

  static String _wordsFromKey(String key) {
    if (key.isEmpty) return key;
    if (key.contains('_')) {
      return key
          .split('_')
          .where((s) => s.isNotEmpty)
          .map(
            (s) =>
                '${s[0].toUpperCase()}${s.length > 1 ? s.substring(1).toLowerCase() : ''}',
          )
          .join(' ');
    }
    final buf = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final c = key.codeUnitAt(i);
      final ch = key[i];
      final isUpper = c >= 65 && c <= 90;
      if (i > 0 && isUpper) {
        buf.write(' ');
      }
      buf.write(i == 0 ? ch.toUpperCase() : ch);
    }
    return buf.toString();
  }

  static const Map<String, String> _generalModuleFieldLabels = {
    'lvlTimeout': 'Level timeout',
    'silenceBuzzerLevel': 'Silence buzzer level',
    'silenceSoundersLevel': 'Silence sounders level',
    'resetLevel': 'Reset level',
    'faultLatching': 'Fault latching',
  };

  static const Map<String, String> _moduleFieldLabels = {
    'moduleNo': 'Module No',
    'enabled': 'Enabled',
    'product': 'Product',
    'id': 'ID',
    'revision': 'Revision',
    'hardware': 'Hardware Version',
    'firmware': 'Firmware Version',
    'date': 'Manufacturing Date',
    'protocol': 'Protocol No',
  };

  static const Map<String, String> _accessCodeFieldLabels = {
    'accessCodeNo': 'Access code no',
    'accessLevel': 'Access level',
    'accessLevelName': 'Access level name',
    'accessCode': 'Access code',
  };

  static const Map<String, String> _lBusFieldLabels = {
    'enabled': 'Enabled',
    'idLed': 'ID LED',
    'product': 'Product',
    'deviceText': 'L-Bus device text',
    'id': 'ID',
    'revision': 'Revision',
    'productRev': 'Product rev.',
    'hardware': 'Hardware',
    'firmware': 'Firmware',
    'date': 'Date',
    'protocol': 'Protocol',
  };

  static String _humanizeSegment(String sectionKey, String segment) {
    switch (sectionKey) {
      case 'relay':
        final rm = RegExp(r'^r([123])$').firstMatch(segment);
        if (rm != null) return 'Relay ${rm.group(1)}';
        break;
      case 'zone':
        final zm = RegExp(r'^z([123])$').firstMatch(segment);
        if (zm != null) return 'Zone ${zm.group(1)}';
        break;
      case 'sounder':
        final sm = RegExp(r'^s([123])$').firstMatch(segment);
        if (sm != null) return 'Sounder ${sm.group(1)}';
        final zm = RegExp(r'^z([123])$').firstMatch(segment);
        if (zm != null) return 'Zone ${zm.group(1)}';
        final em = RegExp(r'^e([123])$').firstMatch(segment);
        if (em != null) return 'Ext. out ${em.group(1)}';
        if (segment == 'general') return 'General';
        break;
      default:
        break;
    }

    if (sectionKey == 'general_module') {
      final friendly = _generalModuleFieldLabels[segment];
      if (friendly != null) return friendly;
    }

    if (sectionKey == 'module') {
      final friendly = _moduleFieldLabels[segment];
      if (friendly != null) return friendly;
    }

    if (sectionKey == 'access_code') {
      final friendly = _accessCodeFieldLabels[segment];
      if (friendly != null) return friendly;
    }

    if (sectionKey == 'l_bus') {
      final friendly = _lBusFieldLabels[segment];
      if (friendly != null) return friendly;
    }

    return _wordsFromKey(segment);
  }

  static String humanizeFieldPath(String sectionKey, String path) {
    if (path.isEmpty || path == '(section root)') {
      return 'This section';
    }

    final onlyBracket = RegExp(r'^\[(\d+)\]$').firstMatch(path);
    if (onlyBracket != null) {
      final idx = int.parse(onlyBracket.group(1)!) + 1;
      return switch (sectionKey) {
        'access_code' => 'Access code $idx',
        'l_bus' => 'L-Bus device $idx',
        _ => 'Row $idx',
      };
    }

    final bracketSuffix = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(path);
    if (bracketSuffix != null) {
      final base = bracketSuffix.group(1)!;
      final idx = int.parse(bracketSuffix.group(2)!) + 1;
      if (base.isEmpty) {
        return switch (sectionKey) {
          'access_code' => 'Access code $idx',
          'l_bus' => 'L-Bus device $idx',
          _ => 'Row $idx',
        };
      }
      return '${humanizeFieldPath(sectionKey, base)} · Row $idx';
    }

    final parts = <String>[];
    var listPrefix = _listIndexPrefix(sectionKey, path);
    var rest = path;
    while (listPrefix != null) {
      parts.add(listPrefix);
      rest = rest.substring(RegExp(r'^\[(\d+)\]\.').firstMatch(rest)!.end);
      listPrefix = _listIndexPrefix(sectionKey, rest);
    }

    final dotted = rest.split('.').where((s) => s.isNotEmpty).toList();
    for (final seg in dotted) {
      parts.add(_humanizeSegment(sectionKey, seg));
    }

    return parts.join(' ');
  }

  static String formatScalar(
    String sectionKey,
    String path,
    Object? value,
    Object? sideRoot,
  ) {
    final rel = _relativePath(path);

    switch (sectionKey) {
      case 'module':
        final m = _module(rel, value);
        if (m != null) return m;
        break;
      case 'relay':
        final m = _relay(rel, value, sideRoot);
        if (m != null) return m;
        break;
      case 'input':
        final m = _input(rel, value, sideRoot);
        if (m != null) return m;
        break;
      case 'zone':
        final m = _zone(rel, value);
        if (m != null) return m;
        break;
      case 'ext_out':
        final m = _extOut(rel, value);
        if (m != null) return m;
        break;
      case 'sounder':
        final m = _sounder(rel, value, sideRoot);
        if (m != null) return m;
        break;
      case 'service_due':
        if (rel == 'reminder') {
          final i = _asInt(value);
          if (i == 0) return 'Off';
          if (i == 1) return 'On';
        }
        break;
      case 'access_code':
        final m = _accessCode(rel, value);
        if (m != null) return m;
        break;
      case 'l_bus':
        final m = _lBus(rel, value);
        if (m != null) return m;
        break;
      default:
        break;
    }

    if (value is bool) return _yesNo(value);
    return _rawPreview(value);
  }

  static String? _accessCode(String rel, Object? value) {
    switch (rel) {
      case 'accessCodeNo':
        final i = _asInt(value);
        return i?.toString() ?? _rawPreview(value);
      case 'accessLevel':
        final i = _asInt(value);
        return _pick(AccessCodeSetupData.accessLevelNames, i);
      case 'accessLevelName':
        if (value == null) return '—';
        final s = value.toString();
        return s.isEmpty ? '—' : s;
      case 'accessCode':
        if (value == null) return '—';
        final s = value.toString();
        return s.isEmpty ? '—' : s;
      default:
        return null;
    }
  }

  static String? _lBus(String rel, Object? value) {
    switch (rel) {
      case 'enabled':
      case 'idLed':
      case 'product':
        if (value == null) return '—';
        final s = value.toString();
        return s.isEmpty ? '—' : s;
      case 'deviceText':
      case 'productRev':
      case 'hardware':
      case 'firmware':
      case 'date':
        if (value == null) return '—';
        final s = value.toString();
        return s.isEmpty ? '—' : s;
      case 'id':
      case 'revision':
      case 'protocol':
        final i = _asInt(value);
        return i?.toString() ?? _rawPreview(value);
      default:
        return null;
    }
  }

  static String? _module(String rel, Object? value) {
    switch (rel) {
      case 'enabled':
        return _yesNo(value);
      case 'moduleNo':
      case 'id':
      case 'revision':
      case 'protocol':
        final i = _asInt(value);
        return i?.toString() ?? _rawPreview(value);
      case 'product':
      case 'hardware':
      case 'firmware':
      case 'date':
        if (value == null) return '—';
        final s = value.toString();
        return s.isEmpty ? '—' : s;
      default:
        return null;
    }
  }

  static String? _relay(String rel, Object? value, Object? sideRoot) {
    final m = RegExp(
      r'^r([123])\.(group|function|enabled|test|outputText|dynamicText)$',
    ).firstMatch(rel);
    if (m == null) return null;
    final rk = 'r${m.group(1)}';
    final field = m.group(2)!;
    final root = _asMap(sideRoot);
    final block = root != null ? _asMap(root[rk]) : null;
    switch (field) {
      case 'group':
        return _pick(_relayGroups, _asInt(value));
      case 'function':
        final gIdx = _asInt(block?['group']) ?? 0;
        final gName = _pick(_relayGroups, gIdx);
        final list = _relayFunctions[gName] ?? const ['None'];
        return _pick(list, _asInt(value));
      case 'enabled':
      case 'test':
        return _yesNo(value);
      case 'outputText':
      case 'dynamicText':
        return _rawPreview(value);
      default:
        return null;
    }
  }

  static String? _input(String rel, Object? value, Object? sideRoot) {
    final root = _asMap(sideRoot);
    switch (rel) {
      case 'group':
        return _pick(_inputGroups, _asInt(value));
      case 'function':
        final gIdx = _asInt(root?['group']) ?? 0;
        final gName = _pick(_inputGroups, gIdx);
        final list = _inputFunctions[gName] ?? const ['None'];
        return _pick(list, _asInt(value));
      case 'enabled':
      case 'test':
      case 'inverted':
        return _yesNo(value);
      case 'text':
        return _rawPreview(value);
      default:
        return null;
    }
  }

  static String? _zone(String rel, Object? value) {
    final zm = RegExp(
      r'^z([123])\.(enabled|test|type|detectionMode|verificationTime|text)$',
    ).firstMatch(rel);
    if (zm == null) return null;
    final field = zm.group(2)!;
    switch (field) {
      case 'type':
        return _pick(_zoneTypes, _asInt(value));
      case 'detectionMode':
        return _pick(_zoneModes, _asInt(value));
      case 'enabled':
      case 'test':
        return _yesNo(value);
      case 'verificationTime':
      case 'text':
        return _rawPreview(value);
      default:
        return null;
    }
  }

  static String? _extOut(String rel, Object? value) {
    switch (rel) {
      case 'enabled':
        return _pick(_extEnabled, _asInt(value));
      case 'actuatorType':
        return _pick(_extActuator, _asInt(value));
      case 'function':
        return _pick(_extFunction, _asInt(value));
      case 'resetAllowed':
        return _pick(_extResetAllowed, _asInt(value));
      case 'holdMode':
        return _pick(_extHold, _asInt(value));
      case 'action':
        return _pick(_extAction, _asInt(value));
      case 'countdownAuto':
      case 'countdownMan':
      case 'releaseTime':
      case 'resetDelay':
      case 'text':
        return _rawPreview(value);
      default:
        return null;
    }
  }

  static String? _sounder(String rel, Object? value, Object? sideRoot) {
    final sm = RegExp(
      r'^s([123])\.(enabled|test|normal|outputText|group|function|functionNo)$',
    ).firstMatch(rel);
    if (sm != null) {
      final sk = 's${sm.group(1)}';
      final field = sm.group(2)!;
      final root = _asMap(sideRoot);
      final block = root != null ? _asMap(root[sk]) : null;
      switch (field) {
        case 'enabled':
        case 'test':
          return _yesNo(value);
        case 'normal':
          if (value is bool) return value ? 'Normal' : 'IS (MTL5525)';
          return _yesNo(value);
        case 'group':
          return _pick(_sounderGroups, _asInt(value));
        case 'function':
          final gIdx = _asInt(block?['group']) ?? 0;
          final gName = _pick(_sounderGroups, gIdx);
          final list = _sounderFunctions[gName] ?? const ['None'];
          return _pick(list, _asInt(value));
        case 'functionNo':
        case 'outputText':
          return _rawPreview(value);
        default:
          return null;
      }
    }

    final zm = RegExp(r'^z([123])\.(enabled|test|action)$').firstMatch(rel);
    if (zm != null) {
      final field = zm.group(2)!;
      switch (field) {
        case 'enabled':
        case 'test':
          return _yesNo(value);
        case 'action':
          return _pick(_sounderZoneActions, _asInt(value));
        default:
          return null;
      }
    }

    final em = RegExp(
      r'^e([123])\.(enabled|test|countdownAction|holdAction|releaseAction)$',
    ).firstMatch(rel);
    if (em != null) {
      final field = em.group(2)!;
      switch (field) {
        case 'enabled':
        case 'test':
          return _yesNo(value);
        case 'countdownAction':
        case 'holdAction':
        case 'releaseAction':
          return _pick(_sounderExtActions, _asInt(value));
        default:
          return null;
      }
    }

    if (rel.startsWith('general.')) {
      final sub = rel.substring('general.'.length);
      switch (sub) {
        case 'enabled':
        case 'test':
          return _yesNo(value);
        case 'delayed':
          return _yesNo(value);
        case 'action':
          return _pick(_sounderZoneActions, _asInt(value));
        case 'delay':
          return _rawPreview(value);
        default:
          return null;
      }
    }

    return null;
  }
}
