import 'dart:convert';

import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_diff_labels.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Ordered BLE fetch sequence for full config sync (tune order against captures if needed).
const List<PeripheralConfigSection> kPeripheralConfigFetchOrder = [
  PeripheralConfigSection.module,
  PeripheralConfigSection.panelInfo,
  PeripheralConfigSection.generalModule,
  PeripheralConfigSection.accessCode,
  PeripheralConfigSection.serviceDue,
  PeripheralConfigSection.input,
  PeripheralConfigSection.relay,
  PeripheralConfigSection.zone,
  PeripheralConfigSection.sounder,
  PeripheralConfigSection.extOut,
  PeripheralConfigSection.lBus,
];

/// Apply order excludes [module] (no panel apply API in app).
const List<PeripheralConfigSection> kPeripheralConfigApplyOrder = [
  PeripheralConfigSection.panelInfo,
  PeripheralConfigSection.generalModule,
  PeripheralConfigSection.accessCode,
  PeripheralConfigSection.serviceDue,
  PeripheralConfigSection.input,
  PeripheralConfigSection.relay,
  PeripheralConfigSection.zone,
  PeripheralConfigSection.sounder,
  PeripheralConfigSection.extOut,
  PeripheralConfigSection.lBus,
];

enum PeripheralConfigSection {
  module,
  panelInfo,
  generalModule,
  accessCode,
  serviceDue,
  input,
  relay,
  zone,
  sounder,
  radio,
  lBus,
  extOut,
}

extension PeripheralConfigSectionX on PeripheralConfigSection {
  String get key {
    switch (this) {
      case PeripheralConfigSection.module:
        return 'module';
      case PeripheralConfigSection.panelInfo:
        return 'panel_info';
      case PeripheralConfigSection.generalModule:
        return 'general_module';
      case PeripheralConfigSection.accessCode:
        return 'access_code';
      case PeripheralConfigSection.serviceDue:
        return 'service_due';
      case PeripheralConfigSection.input:
        return 'input';
      case PeripheralConfigSection.relay:
        return 'relay';
      case PeripheralConfigSection.zone:
        return 'zone';
      case PeripheralConfigSection.sounder:
        return 'sounder';
      case PeripheralConfigSection.radio:
        return 'radio';
      case PeripheralConfigSection.lBus:
        return 'l_bus';
      case PeripheralConfigSection.extOut:
        return 'ext_out';
    }
  }

  String get displayLabel {
    switch (this) {
      case PeripheralConfigSection.module:
        return 'Module Info';
      case PeripheralConfigSection.panelInfo:
        return 'Panel Info';
      case PeripheralConfigSection.generalModule:
        return 'General';
      case PeripheralConfigSection.accessCode:
        return 'Access Code';
      case PeripheralConfigSection.serviceDue:
        return 'Service Due';
      case PeripheralConfigSection.input:
        return 'Inputs';
      case PeripheralConfigSection.relay:
        return 'Relays';
      case PeripheralConfigSection.zone:
        return 'Zones';
      case PeripheralConfigSection.sounder:
        return 'Sounders';
      case PeripheralConfigSection.radio:
        return 'Radio';
      case PeripheralConfigSection.lBus:
        return 'L-Bus';
      case PeripheralConfigSection.extOut:
        return 'Extinguishing Output';
    }
  }
}

class ConfigCompareResult {
  ConfigCompareResult({
    required this.sectionMatch,
    required this.panelBySection,
    required this.localBySection,
    this.errorMessage,
    this.sectionDiffLines = const {},
    this.lBusCommsFaultBusNumbers = const [],
    this.isAppCacheEmpty = false,
  });

  factory ConfigCompareResult.withError(String message) {
    return ConfigCompareResult(
      sectionMatch: {for (final s in kPeripheralConfigFetchOrder) s.key: false},
      panelBySection: {},
      localBySection: {},
      errorMessage: message,
      sectionDiffLines: const {},
    );
  }

  final Map<String, bool> sectionMatch;
  final Map<String, Object?> panelBySection;
  final Map<String, Object?> localBySection;
  final String? errorMessage;

  /// Human-readable lines per section key (`PeripheralConfigSection.key`), only for mismatches.
  final Map<String, List<String>> sectionDiffLines;

  /// Enabled L-Bus bus numbers that returned comms fault during panel download.
  final List<String> lBusCommsFaultBusNumbers;

  /// True when no peripheral setup is saved in app storage for this device.
  final bool isAppCacheEmpty;

  bool get hasMismatch =>
      errorMessage != null || sectionMatch.values.any((m) => !m);

  List<PeripheralConfigSection> get mismatchedSections => [
    for (final s in kPeripheralConfigFetchOrder)
      if (sectionMatch[s.key] == false) s,
  ];

  List<PeripheralConfigSection> get matchedSections => [
    for (final s in kPeripheralConfigFetchOrder)
      if (sectionMatch[s.key] == true) s,
  ];

  List<String> diffLinesFor(PeripheralConfigSection section) =>
      sectionDiffLines[section.key] ?? const [];
}

class PeripheralConfigSnapshot {
  PeripheralConfigSnapshot._();

  static String _generalModuleLevelToLabel(int index, List<String> options) {
    if (index >= 0 && index < options.length) return options[index];
    return options.first;
  }

  static Map<String, dynamic> relayMap(BleManager m) => {
    'r1': {
      'enabled': m.isRelayOneSetupEnabled.value,
      'test': m.isRelayOneSetupTest.value,
      'group': m.relayOneSetupGroup.value,
      'function': m.relayOneSetupFunction.value,
      'outputText': m.relayOneSetupOutputText.value,
      'dynamicText': m.relayOneSetupDynamicText.value,
    },
    'r2': {
      'enabled': m.isRelayTwoSetupEnabled.value,
      'test': m.isRelayTwoSetupTest.value,
      'group': m.relayTwoSetupGroup.value,
      'function': m.relayTwoSetupFunction.value,
      'outputText': m.relayTwoSetupOutputText.value,
      'dynamicText': m.relayTwoSetupDynamicText.value,
    },
    'r3': {
      'enabled': m.isRelayThreeSetupEnabled.value,
      'test': m.isRelayThreeSetupTest.value,
      'group': m.relayThreeSetupGroup.value,
      'function': m.relayThreeSetupFunction.value,
      'outputText': m.relayThreeSetupOutputText.value,
      'dynamicText': m.relayThreeSetupDynamicText.value,
    },
  };

  static Map<String, dynamic> inputMap(BleManager m) => {
    'group': m.inputSetupGroup.value,
    'function': m.inputSetupFunction.value,
    'enabled': m.isInputSetupEnabled.value,
    'test': m.isInputSetupTest.value,
    'inverted': m.isInputSetupInverted.value,
    'text': m.inputSetupText.value,
  };

  static Map<String, dynamic> zoneMap(BleManager m) => {
    'z1': {
      'enabled': m.isZoneOneSetupEnabled.value,
      'test': m.isZoneOneSetupTest.value,
      'type': m.zoneOneSetupType.value,
      'detectionMode': m.zoneOneSetupDetectionMode.value,
      'verificationTime': m.zoneOneSetupVerificationTime.value,
      'text': m.zoneOneSetupText.value,
    },
    'z2': {
      'enabled': m.isZoneTwoSetupEnabled.value,
      'test': m.isZoneTwoSetupTest.value,
      'type': m.zoneTwoSetupType.value,
      'detectionMode': m.zoneTwoSetupDetectionMode.value,
      'verificationTime': m.zoneTwoSetupVerificationTime.value,
      'text': m.zoneTwoSetupText.value,
    },
    'z3': {
      'enabled': m.isZoneThreeSetupEnabled.value,
      'test': m.isZoneThreeSetupTest.value,
      'type': m.zoneThreeSetupType.value,
      'detectionMode': m.zoneThreeSetupDetectionMode.value,
      'verificationTime': m.zoneThreeSetupVerificationTime.value,
      'text': m.zoneThreeSetupText.value,
    },
  };

  static Map<String, dynamic> extOutMap(BleManager m) => {
    'enabled': m.isExtZoneEnabled.value,
    'actuatorType': m.extZoneActuatorType.value,
    'function': m.extZoneFunction.value,
    'resetAllowed': m.isResetAllowed.value,
    'holdMode': m.extZoneHoldMode.value,
    'action': m.extZoneAction.value,
    'countdownAuto': m.extZoneCountdownAuto.value,
    'countdownMan': m.extZoneCountdownMan.value,
    'releaseTime': m.extZoneReleaseTime.value,
    'resetDelay': m.extZoneResetDelay.value,
    'text': m.extZoneText.value,
    'isSolar': m.bleProcess.isExtOutApplyButtonActive.value,
  };

  static Map<String, dynamic> sounderMap(BleManager m) => {
    's1': {
      'enabled': m.isSounderOneEnabled.value,
      'test': m.isSounderOneTest.value,
      'normal': m.isSounderOneNormal.value,
      'outputText': m.sounderOneOutputText.value,
      'group': m.sounderOneRelayFunctionGroup.value,
      'function': m.sounderOneRelayFunction.value,
      'functionNo': m.sounderOneFunctionNo.value,
    },
    's2': {
      'enabled': m.isSounderTwoEnabled.value,
      'test': m.isSounderTwoTest.value,
      'normal': m.isSounderTwoNormal.value,
      'outputText': m.sounderTwoOutputText.value,
      'group': m.sounderTwoRelayFunctionGroup.value,
      'function': m.sounderTwoRelayFunction.value,
      'functionNo': m.sounderTwoFunctionNo.value,
    },
    's3': {
      'enabled': m.isSounderThreeEnabled.value,
      'test': m.isSounderThreeTest.value,
      'normal': m.isSounderThreeNormal.value,
      'outputText': m.sounderThreeOutputText.value,
      'group': m.sounderThreeRelayFunctionGroup.value,
      'function': m.sounderThreeRelayFunction.value,
      'functionNo': m.sounderThreeFunctionNo.value,
    },
    'z1': {
      'enabled': m.isZoneOneEnabled.value,
      'test': m.isZoneOneTest.value,
      'action': m.zoneOneAction.value,
    },
    'z2': {
      'enabled': m.isZoneTwoEnabled.value,
      'test': m.isZoneTwoTest.value,
      'action': m.zoneTwoAction.value,
    },
    'z3': {
      'enabled': m.isZoneThreeEnabled.value,
      'test': m.isZoneThreeTest.value,
      'action': m.zoneThreeAction.value,
    },
    'e1': {
      'enabled': m.isExtOutOneEnabled.value,
      'test': m.isExtOutOneTest.value,
      'countdownAction': m.extoutOneCountdownAction.value,
      'holdAction': m.extoutOneHoldAction.value,
      'releaseAction': m.extoutOneReleaseAction.value,
    },
    'e2': {
      'enabled': m.isExtOutTwoEnabled.value,
      'test': m.isExtOutTwoTest.value,
      'countdownAction': m.extoutTwoCountdownAction.value,
      'holdAction': m.extoutTwoHoldAction.value,
      'releaseAction': m.extoutTwoReleaseAction.value,
    },
    'e3': {
      'enabled': m.isExtOutThreeEnabled.value,
      'test': m.isExtOutThreeTest.value,
      'countdownAction': m.extoutThreeCountdownAction.value,
      'holdAction': m.extoutThreeHoldAction.value,
      'releaseAction': m.extoutThreeReleaseAction.value,
    },
    'general': {
      'enabled': m.isSounderGeneralEnabled.value,
      'test': m.isSounderGeneralTest.value,
      'action': m.sounderGeneralAction.value,
      'delay': m.sounderGeneralDelay.value,
      'delayed': m.isSounderGeneralDelay.value,
    },
  };

  static Map<String, dynamic> serviceDueMap(BleManager m) => {
    'year': m.serviceDueYear.value,
    'month': m.serviceDueMonth.value,
    'day': m.serviceDueDay.value,
    'hour': m.serviceDueHour.value,
    'minute': m.serviceDueMinute.value,
    'company': m.serviceDueCompany.value,
    'contact': m.serviceDueContact.value,
    'reminder': m.serviceDueReminder.value,
  };

  static Map<String, dynamic> radioMap(BleManager m) => {
    'enabled': m.isRadioSetupEnabled.value,
    'module': m.radioSetupModule.value,
    'name': m.radioSetupName.value,
    'number': m.radioSetupNo.value,
    'advertise': m.isRadioSetupAdvertised.value,
    'connection': m.isRadioSetupConnected.value,
    'service': m.isRadioSetupServiced.value,
    'programming': m.isRadioSetupProgrammed.value,
    'boot': m.isRadioSetupBooted.value,
  };

  static Map<String, dynamic> moduleMap(BleManager m) => {
    'moduleNo': m.moduleNo.value,
    'enabled': m.moduleEnabled.value,
    'product': m.moduleProduct.value,
    'id': m.moduleId.value,
    'revision': m.moduleRevision.value,
    'hardware': m.moduleHardware.value,
    'firmware': m.moduleFirmware.value,
    'date': m.moduleDate.value,
    'protocol': m.moduleProtocol.value,
  };

  static List<Map<String, dynamic>> lBusList(BleManager m) =>
      m.lBusSetupDataList.value.map((e) => e.toJson()).toList();

  static List<Map<String, dynamic>> accessCodeList(BleManager m) =>
      m.accessCodeSetupDataList.value.map((e) => e.toJson()).toList();

  static Map<String, dynamic> panelInfoMap(BleManager m) => {
    'panelId': m.panelInfoPanelNo.value,
    'panelName': m.panelInfoPanelName.value,
    'year': m.panelInfoYear.value,
    'month': m.panelInfoMonth.value,
    'day': m.panelInfoDay.value,
    'hour': m.panelInfoHour.value,
    'minute': m.panelInfoMinute.value,
    'second': m.panelInfoSecond.value,
    'delay': m.panelInfoEventReminderDelay.value,
  };

  static Map<String, dynamic> generalModuleMap(BleManager m) {
    final bp = m.bleProcess;
    return {
      'lvlTimeout': bp.generalModuleLvlTimeOut.value,
      'silenceBuzzerLevel': _generalModuleLevelToLabel(
        bp.generalModuleSilenceBuzzerLvl.value,
        ['Access Level 1', 'Access Level 2'],
      ),
      'silenceSoundersLevel': _generalModuleLevelToLabel(
        bp.generalModuleSilenceSounderLvl.value,
        ['Access Level 2', 'Access Level 3'],
      ),
      'resetLevel': _generalModuleLevelToLabel(bp.generalModuleResetLvl.value, [
        'Access Level 2',
        'Access Level 3',
      ]),
      'faultLatching': bp.generalModuleFaultLatching.value == 0 ? 'No' : 'Yes',
    };
  }

  /// Snapshot keyed by [PeripheralConfigSection.key]. Lists (L-Bus, access code) are stored as List<Map>.
  static Map<String, Object?> fromBleManager(BleManager m) {
    return {
      PeripheralConfigSection.module.key: moduleMap(m),
      PeripheralConfigSection.panelInfo.key: panelInfoMap(m),
      PeripheralConfigSection.generalModule.key: generalModuleMap(m),
      PeripheralConfigSection.accessCode.key: accessCodeList(m),
      PeripheralConfigSection.serviceDue.key: serviceDueMap(m),
      PeripheralConfigSection.input.key: inputMap(m),
      PeripheralConfigSection.relay.key: relayMap(m),
      PeripheralConfigSection.zone.key: zoneMap(m),
      PeripheralConfigSection.sounder.key: sounderMap(m),
      PeripheralConfigSection.lBus.key: lBusList(m),
      PeripheralConfigSection.extOut.key: extOutMap(m),
    };
  }

  static bool _isEmptyCacheSlice(Object? value) {
    if (value == null) return true;
    if (value is Map && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    return false;
  }

  /// True when every config section has no saved app data for this device.
  static bool isAppCacheEmpty(Map<String, Object?> localBySection) {
    return kPeripheralConfigFetchOrder.every(
      (s) => _isEmptyCacheSlice(localBySection[s.key]),
    );
  }

  static Future<Map<String, Object?>> fromCache(String deviceId) async {
    final relay = await PeripheralSetupCache.loadRelaySetup(deviceId);
    final input = await PeripheralSetupCache.loadInputSetup(deviceId);
    final zone = await PeripheralSetupCache.loadZoneSetup(deviceId);
    final extOut = await PeripheralSetupCache.loadExtOutSetup(deviceId);
    final module = await PeripheralSetupCache.loadModuleSetup(deviceId);
    final lBus = await PeripheralSetupCache.loadLBusSetup(deviceId);
    final sounder = await PeripheralSetupCache.loadSounderSetup(deviceId);
    final serviceDue = await PeripheralSetupCache.loadServiceDueSetup(deviceId);
    final access = await PeripheralSetupCache.loadAccessCodeSetup(deviceId);
    final panelInfo = await PeripheralSetupCache.loadPanelInfoSetup(deviceId);
    final general = await PeripheralSetupCache.loadGeneralModuleSetup(deviceId);

    return {
      PeripheralConfigSection.module.key: module,
      PeripheralConfigSection.panelInfo.key: panelInfo,
      PeripheralConfigSection.generalModule.key: general,
      PeripheralConfigSection.accessCode.key: access,
      PeripheralConfigSection.serviceDue.key: serviceDue,
      PeripheralConfigSection.input.key: input,
      PeripheralConfigSection.relay.key: relay,
      PeripheralConfigSection.zone.key: zone,
      PeripheralConfigSection.sounder.key: sounder,
      PeripheralConfigSection.lBus.key: lBus,
      PeripheralConfigSection.extOut.key: extOut,
    };
  }

  static bool _sectionDataEqual(Object? panel, Object? local) {
    if (panel == null && local == null) return true;
    try {
      return jsonEncode(panel) == jsonEncode(local);
    } catch (_) {
      return panel == local;
    }
  }

  static String _formatDiffValue(Object? v) {
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

  static String _formatDiffScalar(
    PeripheralConfigSection section,
    String path,
    Object? value,
    Object? sideRoot,
  ) {
    return PeripheralConfigDiffLabels.formatScalar(
      section.key,
      path,
      value,
      sideRoot,
    );
  }

  /// Recursive field-level diff for JSON-like structures (maps / lists / scalars).
  static List<String> describeConfigDataDiff(
    Object? panel,
    Object? local, [
    String path = '',
    PeripheralConfigSection? diffSection,
    Object? panelSectionRoot,
    Object? localSectionRoot,
  ]) {
    if (_sectionDataEqual(panel, local)) return [];

    // Null vs map/list → empty counterpart so we emit per-field rows instead of
    // one JSON blob at "(section root)".
    if (panel is Map && local == null) {
      local = <String, Object?>{};
    } else if (local is Map && panel == null) {
      panel = <String, Object?>{};
    } else if (panel is List && local == null) {
      local = <Object?>[];
    } else if (local is List && panel == null) {
      panel = <Object?>[];
    }

    if (panel is Map && local is Map) {
      final p = Map<String, Object?>.from(panel);
      final l = Map<String, Object?>.from(local);
      final lines = <String>[];
      final keys = {...p.keys, ...l.keys}.toList()..sort();
      for (final key in keys) {
        final childPath = path.isEmpty ? key : '$path.$key';
        lines.addAll(
          describeConfigDataDiff(
            p[key],
            l[key],
            childPath,
            diffSection,
            panelSectionRoot,
            localSectionRoot,
          ),
        );
      }
      return lines;
    }

    if (panel is List && local is List) {
      final lines = <String>[];
      if (panel.length != local.length) {
        lines.add(
          '$path: list length ${panel.length} (panel) vs ${local.length} (app)',
        );
      }
      final n = panel.length < local.length ? panel.length : local.length;
      for (var i = 0; i < n; i++) {
        lines.addAll(
          describeConfigDataDiff(
            panel[i],
            local[i],
            '$path[$i]',
            diffSection,
            panelSectionRoot,
            localSectionRoot,
          ),
        );
      }
      for (var i = n; i < panel.length; i++) {
        lines.addAll(
          describeConfigDataDiff(
            panel[i],
            null,
            '$path[$i]',
            diffSection,
            panelSectionRoot,
            localSectionRoot,
          ),
        );
      }
      for (var i = n; i < local.length; i++) {
        lines.addAll(
          describeConfigDataDiff(
            null,
            local[i],
            '$path[$i]',
            diffSection,
            panelSectionRoot,
            localSectionRoot,
          ),
        );
      }
      return lines;
    }

    final label = path.isEmpty ? '(section root)' : path;
    if (diffSection != null) {
      final pv = _formatDiffScalar(diffSection, path, panel, panelSectionRoot);
      final lv = _formatDiffScalar(diffSection, path, local, localSectionRoot);
      return ['$label: panel $pv · app $lv'];
    }
    return [
      '$label: panel ${_formatDiffValue(panel)} · app ${_formatDiffValue(local)}',
    ];
  }

  static const Set<String> _panelInfoDateTimeKeys = {
    'year',
    'month',
    'day',
    'hour',
    'minute',
    'second',
  };

  /// Strips clock fields so Config Log compare ignores drifting panel time.
  static Object? _forPanelInfoCompare(Object? v) {
    if (v is! Map) return v;
    final m = Map<String, Object?>.from(v);
    for (final key in _panelInfoDateTimeKeys) {
      m.remove(key);
    }
    return m;
  }

  /// Config Log omits Solar/DIP flag so it does not drive mismatch UI.
  static Object? _forExtOutCompare(Object? v) {
    if (v is! Map) return v;
    final m = Map<String, Object?>.from(v);
    m.remove('isSolar');
    return m;
  }

  static ConfigCompareResult compare({
    required Map<String, Object?> panelBySection,
    required Map<String, Object?> localBySection,
    List<String> lBusCommsFaultBusNumbers = const [],
  }) {
    final appCacheEmpty = isAppCacheEmpty(localBySection);
    final match = <String, bool>{};
    final diffs = <String, List<String>>{};
    for (final s in kPeripheralConfigFetchOrder) {
      final k = s.key;
      Object? panelSlice = panelBySection[k];
      Object? localSlice = localBySection[k];
      if (s == PeripheralConfigSection.panelInfo) {
        panelSlice = _forPanelInfoCompare(panelSlice);
        localSlice = _forPanelInfoCompare(localSlice);
      }
      if (s == PeripheralConfigSection.extOut) {
        panelSlice = _forExtOutCompare(panelSlice);
        localSlice = _forExtOutCompare(localSlice);
      }
      final ok = _sectionDataEqual(panelSlice, localSlice);
      match[k] = ok;
      if (!ok) {
        var lines = describeConfigDataDiff(
          panelSlice,
          localSlice,
          '',
          s,
          panelSlice,
          localSlice,
        );
        diffs[k] = lines;
      }
    }

    if (lBusCommsFaultBusNumbers.isNotEmpty) {
      final k = PeripheralConfigSection.lBus.key;
      match[k] = false;
      final faultLines = <String>[
        'L-Bus comms fault on bus(es): ${lBusCommsFaultBusNumbers.join(", ")}',
        'Enabled-bus detail may be incomplete; compare panel vs app using '
            'per-bus download if needed.',
      ];
      final existing = diffs[k];
      if (existing == null || existing.isEmpty) {
        diffs[k] = faultLines;
      } else {
        diffs[k] = [...faultLines, ...existing];
      }
    }

    return ConfigCompareResult(
      sectionMatch: match,
      panelBySection: panelBySection,
      localBySection: localBySection,
      sectionDiffLines: diffs,
      lBusCommsFaultBusNumbers: List<String>.from(lBusCommsFaultBusNumbers),
      isAppCacheEmpty: appCacheEmpty,
    );
  }
}
