import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Canonical JSON-like maps for comparing panel vs app baseline (cache or defaults).
class PeripheralConfigBundle {
  PeripheralConfigBundle({
    required this.relays,
    required this.inputs,
    required this.zones,
    required this.sounders,
    required this.module,
    required this.lBusBuses,
    required this.extOut,
    required this.serviceDue,
    required this.accessCodes,
    required this.panelInfo,
    required this.general,
    required this.diagnostics,
  });

  final Map<String, dynamic> relays;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> zones;
  final Map<String, dynamic> sounders;
  final Map<String, dynamic> module;
  final List<Map<String, dynamic>> lBusBuses;
  final Map<String, dynamic> extOut;
  final Map<String, dynamic> serviceDue;
  final List<Map<String, dynamic>> accessCodes;
  final Map<String, dynamic> panelInfo;
  final Map<String, dynamic> general;
  final Map<String, dynamic> diagnostics;

  /// Walk Test UI uses zone test flags only.
  Map<String, dynamic> get walkTest => {
    'z1': (zones['z1'] is Map) ? (zones['z1'] as Map)['test'] : null,
    'z2': (zones['z2'] is Map) ? (zones['z2'] as Map)['test'] : null,
    'z3': (zones['z3'] is Map) ? (zones['z3'] as Map)['test'] : null,
  };

  static String _generalLevelLabel(int index, List<String> options) {
    if (index >= 0 && index < options.length) return options[index];
    return options.first;
  }

  static PeripheralConfigBundle fromBleManager(BleManager m) {
    final bp = m.bleProcess;
    return PeripheralConfigBundle(
      relays: {
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
      },
      inputs: {
        'group': m.inputSetupGroup.value,
        'function': m.inputSetupFunction.value,
        'enabled': m.isInputSetupEnabled.value,
        'test': m.isInputSetupTest.value,
        'inverted': m.isInputSetupInverted.value,
        'text': m.inputSetupText.value,
      },
      zones: {
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
      },
      sounders: {
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
      },
      module: {
        'moduleNo': m.moduleNo.value,
        'enabled': m.moduleEnabled.value,
        'product': m.moduleProduct.value,
        'id': m.moduleId.value,
        'revision': m.moduleRevision.value,
        'hardware': m.moduleHardware.value,
        'firmware': m.moduleFirmware.value,
        'date': m.moduleDate.value,
        'protocol': m.moduleProtocol.value,
      },
      lBusBuses: m.lBusSetupDataList.value.map((e) => e.toJson()).toList(),
      extOut: {
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
        'isSolar': bp.isExtOutApplyButtonActive.value,
      },
      serviceDue: {
        'year': m.serviceDueYear.value,
        'month': m.serviceDueMonth.value,
        'day': m.serviceDueDay.value,
        'hour': m.serviceDueHour.value,
        'minute': m.serviceDueMinute.value,
        'company': m.serviceDueCompany.value,
        'contact': m.serviceDueContact.value,
        'reminder': m.serviceDueReminder.value,
      },
      accessCodes:
          m.accessCodeSetupDataList.value.map((e) => e.toJson()).toList(),
      panelInfo: {
        'panelId': m.panelInfoPanelNo.value,
        'panelName': m.panelInfoPanelName.value,
        'year': m.panelInfoYear.value,
        'month': m.panelInfoMonth.value,
        'day': m.panelInfoDay.value,
        'hour': m.panelInfoHour.value,
        'minute': m.panelInfoMinute.value,
        'second': m.panelInfoSecond.value,
        'delay': m.panelInfoEventReminderDelay.value,
      },
      general: {
        'lvlTimeout': bp.generalModuleLvlTimeOut.value,
        'silenceBuzzerLevel': _generalLevelLabel(
          bp.generalModuleSilenceBuzzerLvl.value,
          ['Access Level 1', 'Access Level 2'],
        ),
        'silenceSoundersLevel': _generalLevelLabel(
          bp.generalModuleSilenceSounderLvl.value,
          ['Access Level 2', 'Access Level 3'],
        ),
        'resetLevel': _generalLevelLabel(bp.generalModuleResetLvl.value, [
          'Access Level 2',
          'Access Level 3',
        ]),
        'faultLatching':
            bp.generalModuleFaultLatching.value == 0 ? 'No' : 'Yes',
      },
      diagnostics: {
        'sounder1': bp.sounderOneAdcValue.value,
        'sounder2': bp.sounderTwoAdcValue.value,
        'sounder3': bp.sounderThreeAdcValue.value,
        'discharge': bp.dischargeAdcValue.value,
        'vaux': bp.vauxAdcValue.value,
        'vin': bp.vinAdcValue.value,
        'progInput': bp.progInputAdcValue.value,
        'holdInput': bp.holdInputAdcValue.value,
        'zone1': bp.zone1AdcValue.value,
        'zone2': bp.zone2AdcValue.value,
        'zone3': bp.zone3AdcValue.value,
        'earth': bp.earthAdcValue.value,
      },
    );
  }

  static Future<PeripheralConfigBundle> baselineForDevice(
    String deviceId,
  ) async {
    final relays = await PeripheralSetupCache.loadRelaySetup(deviceId);
    final inputs = await PeripheralSetupCache.loadInputSetup(deviceId);
    final zones = await PeripheralSetupCache.loadZoneSetup(deviceId);
    final sounders = await PeripheralSetupCache.loadSounderSetup(deviceId);
    final module = await PeripheralSetupCache.loadModuleSetup(deviceId);
    final lBus = await PeripheralSetupCache.loadLBusSetup(deviceId);
    final extOut = await PeripheralSetupCache.loadExtOutSetup(deviceId);
    final serviceDue = await PeripheralSetupCache.loadServiceDueSetup(deviceId);
    final access = await PeripheralSetupCache.loadAccessCodeSetup(deviceId);
    final panelInfo = await PeripheralSetupCache.loadPanelInfoSetup(deviceId);
    final general = await PeripheralSetupCache.loadGeneralModuleSetup(deviceId);
    final diagnostic = await PeripheralSetupCache.loadDiagnosticSetup(deviceId);

    return PeripheralConfigBundle(
      relays: relays ?? _defaultRelays(),
      inputs: inputs ?? _defaultInputs(),
      zones: zones ?? _defaultZones(),
      sounders: sounders ?? _defaultSounders(),
      module: module ?? _defaultModule(),
      lBusBuses: lBus ?? _defaultLBus(),
      extOut: extOut ?? _defaultExtOut(),
      serviceDue: serviceDue ?? _defaultServiceDue(),
      accessCodes: access ?? _defaultAccessCodes(),
      panelInfo: panelInfo ?? _defaultPanelInfo(),
      general: general ?? _defaultGeneral(),
      diagnostics: diagnostic ?? _defaultDiagnostics(),
    );
  }

  static Map<String, dynamic> _defaultRelays() => {
    'r1': {
      'enabled': false,
      'test': false,
      'group': 0,
      'function': 0,
      'outputText': '',
      'dynamicText': '',
    },
    'r2': {
      'enabled': false,
      'test': false,
      'group': 0,
      'function': 0,
      'outputText': '',
      'dynamicText': '',
    },
    'r3': {
      'enabled': false,
      'test': false,
      'group': 0,
      'function': 0,
      'outputText': '',
      'dynamicText': '',
    },
  };

  static Map<String, dynamic> _defaultInputs() => {
    'group': 0,
    'function': 0,
    'enabled': false,
    'test': false,
    'inverted': false,
    'text': '',
  };

  static Map<String, dynamic> _defaultZones() => {
    'z1': {
      'enabled': false,
      'test': false,
      'type': 0,
      'detectionMode': 0,
      'verificationTime': '',
      'text': '',
    },
    'z2': {
      'enabled': false,
      'test': false,
      'type': 0,
      'detectionMode': 0,
      'verificationTime': '',
      'text': '',
    },
    'z3': {
      'enabled': false,
      'test': false,
      'type': 0,
      'detectionMode': 0,
      'verificationTime': '',
      'text': '',
    },
  };

  static Map<String, dynamic> _defaultSounders() => {
    's1': {
      'enabled': false,
      'test': false,
      'normal': false,
      'outputText': '',
      'group': 0,
      'function': 0,
      'functionNo': 0,
    },
    's2': {
      'enabled': false,
      'test': false,
      'normal': false,
      'outputText': '',
      'group': 0,
      'function': 0,
      'functionNo': 0,
    },
    's3': {
      'enabled': false,
      'test': false,
      'normal': false,
      'outputText': '',
      'group': 0,
      'function': 0,
      'functionNo': 0,
    },
    'z1': {'enabled': false, 'test': false, 'action': 0},
    'z2': {'enabled': false, 'test': false, 'action': 0},
    'z3': {'enabled': false, 'test': false, 'action': 0},
    'e1': {
      'enabled': false,
      'test': false,
      'countdownAction': 0,
      'holdAction': 0,
      'releaseAction': 0,
    },
    'e2': {
      'enabled': false,
      'test': false,
      'countdownAction': 0,
      'holdAction': 0,
      'releaseAction': 0,
    },
    'e3': {
      'enabled': false,
      'test': false,
      'countdownAction': 0,
      'holdAction': 0,
      'releaseAction': 0,
    },
    'general': {
      'enabled': false,
      'test': false,
      'action': 0,
      'delay': 0,
      'delayed': false,
    },
  };

  static Map<String, dynamic> _defaultModule() => {
    'moduleNo': 0,
    'enabled': false,
    'product': '',
    'id': 0,
    'revision': 0,
    'hardware': '',
    'firmware': '',
    'date': '',
    'protocol': 0,
  };

  static List<Map<String, dynamic>> _defaultLBus() =>
      List.generate(31, (_) => LBusSetupData().toJson());

  static Map<String, dynamic> _defaultExtOut() => {
    'enabled': 0,
    'actuatorType': 0,
    'function': 0,
    'resetAllowed': 0,
    'holdMode': 0,
    'action': 0,
    'countdownAuto': 0,
    'countdownMan': 0,
    'releaseTime': 0,
    'resetDelay': 0,
    'text': '',
    'isSolar': false,
  };

  static Map<String, dynamic> _defaultServiceDue() => {
    'year': 0,
    'month': 0,
    'day': 0,
    'hour': 0,
    'minute': 0,
    'company': '',
    'contact': '',
    'reminder': 0,
  };

  static List<Map<String, dynamic>> _defaultAccessCodes() => [];

  static Map<String, dynamic> _defaultPanelInfo() => {
    'panelId': 0,
    'panelName': '',
    'year': 0,
    'month': 0,
    'day': 0,
    'hour': 0,
    'minute': 0,
    'second': 0,
    'delay': 0,
  };

  static Map<String, dynamic> _defaultGeneral() => {
    'lvlTimeout': 0,
    'silenceBuzzerLevel': 'Access Level 1',
    'silenceSoundersLevel': 'Access Level 2',
    'resetLevel': 'Access Level 2',
    'faultLatching': 'No',
  };

  static Map<String, dynamic> _defaultDiagnostics() => {
    'sounder1': 0.0,
    'sounder2': 0.0,
    'sounder3': 0.0,
    'discharge': 0.0,
    'vaux': 0.0,
    'vin': 0.0,
    'progInput': 0.0,
    'holdInput': 0.0,
    'zone1': 0.0,
    'zone2': 0.0,
    'zone3': 0.0,
    'earth': 0.0,
  };
}

/// Persists a bundle to [PeripheralSetupCache] (same shape as dashboard download saves).
Future<void> savePeripheralBundleToCache(
  String deviceId,
  PeripheralConfigBundle bundle,
) async {
  await PeripheralSetupCache.saveRelaySetup(deviceId, bundle.relays);
  await PeripheralSetupCache.saveInputSetup(deviceId, bundle.inputs);
  await PeripheralSetupCache.saveZoneSetup(deviceId, bundle.zones);
  await PeripheralSetupCache.saveSounderSetup(deviceId, bundle.sounders);
  await PeripheralSetupCache.saveModuleSetup(deviceId, bundle.module);
  await PeripheralSetupCache.saveLBusSetup(deviceId, bundle.lBusBuses);
  await PeripheralSetupCache.saveExtOutSetup(deviceId, bundle.extOut);
  await PeripheralSetupCache.saveServiceDueSetup(deviceId, bundle.serviceDue);
  await PeripheralSetupCache.saveAccessCodeSetup(deviceId, bundle.accessCodes);
  await PeripheralSetupCache.savePanelInfoSetup(deviceId, bundle.panelInfo);
  await PeripheralSetupCache.saveGeneralModuleSetup(deviceId, bundle.general);
  await PeripheralSetupCache.saveDiagnosticSetup(deviceId, bundle.diagnostics);
}
