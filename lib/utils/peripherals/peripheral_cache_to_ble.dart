import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/modes/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/modes/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/utils/modes/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/modes/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/modes/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/modes/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/general_module_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/panel_info_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/service_due_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/zone_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/sounder_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/input_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/relay_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/ext_out_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/l_bus_defaults.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PeripheralCacheToBle {
  PeripheralCacheToBle._();

  static const List<String> _relayGroups = [
    'None',
    'General',
    StringConstants.zone,
    StringConstants.extOut,
  ];

  static const Map<String, List<String>> _relayFunctions = {
    'None': ['None'],
    'General': [
      'Fault',
      StringConstants.extnlFault,
      StringConstants.supplyFault,
      StringConstants.extnlSupplyFault,
      StringConstants.sounderFault,
      StringConstants.sounderSilenced,
      StringConstants.sounderActivated,
      StringConstants.sounderDisabled,
      StringConstants.disablement,
      StringConstants.test,
      'Fire',
      'Reset',
      StringConstants.controlsEnabled,
      StringConstants.supervisory,
      StringConstants.fireSnd,
    ],
    StringConstants.zone: [
      'Fault',
      'Fire',
      StringConstants.disablement,
      StringConstants.fireSnd,
    ],
    StringConstants.extOut: [
      StringConstants.releaseInitiated,
      StringConstants.extAgentReleased,
      StringConstants.releaseHold,
      StringConstants.manualMode,
      StringConstants.manualRelease,
      StringConstants.extnlExtFault,
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
    ],
  };

  static const List<String> _sounderGroups = [
    'None',
    'General',
    StringConstants.zone,
    StringConstants.extOut,
  ];

  static const Map<String, List<String>> _sounderFunctions = {
    'None': ['None'],
    'General': [StringConstants.fireSnd],
    StringConstants.zone: [StringConstants.fireSnd],
    StringConstants.extOut: [
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
    ],
  };

  static const List<String> _zoneModes = PanelValues.zoneModeOptions;

  static const List<String> _sounderActions = [
    'Continuous',
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
  ];

  static const List<String> _sounderExtActions = [
    'Continuous',
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
    'Off',
  ];

  static int _clampInt(int v, int max) => v.clamp(0, max);

  static Future<void> applyToBleManager(BleManager m, String deviceId) async {
    final panel = await PeripheralSetupCache.loadPanelInfoSetup(deviceId);
    if (panel != null) _applyPanelInfo(m, panel);

    final general = await PeripheralSetupCache.loadGeneralModuleSetup(deviceId);
    if (general != null) _applyGeneralModule(m, general);

    final access = await PeripheralSetupCache.loadAccessCodeSetup(deviceId);
    if (access != null && access.isNotEmpty) {
      var list = access.map((e) => AccessCodeSetupData.fromJson(e)).toList();
      while (list.length < 8) {
        list.add(const AccessCodeSetupData());
      }
      m.accessCodeSetupDataList.value = list;
    }

    final serviceDue = await PeripheralSetupCache.loadServiceDueSetup(deviceId);
    if (serviceDue != null) _applyServiceDue(m, serviceDue);

    final input = await PeripheralSetupCache.loadInputSetup(deviceId);
    if (input != null) _applyInput(m, input);

    final relay = await PeripheralSetupCache.loadRelaySetup(deviceId);
    if (relay != null) _applyRelay(m, relay);

    final zone = await PeripheralSetupCache.loadZoneSetup(deviceId);
    if (zone != null) _applyZone(m, zone);

    final sounder = await PeripheralSetupCache.loadSounderSetup(deviceId);
    if (sounder != null) _applySounder(m, sounder);

    final lBus = await PeripheralSetupCache.loadLBusSetup(deviceId);
    if (lBus != null && lBus.isNotEmpty) {
      var list = lBus.map((e) => LBusSetupData.fromJson(e)).toList();
      while (list.length < LBusDefaults.busCount) {
        list.add(const LBusSetupData());
      }
      m.lBusSetupDataList.value = list;
    }

    final extOut = await PeripheralSetupCache.loadExtOutSetup(deviceId);
    if (extOut != null) _applyExtOut(m, extOut);
  }

  static void _applyPanelInfo(BleManager m, Map<String, dynamic> data) {
    final now = DateTime.now();
    m.panelInfoPanelNo.value =
        (data['panelId'] as num?)?.toInt() ??
        (data[StringConstants.offlineprovisioned] as num?)?.toInt() ??
        PanelInfoDefaults.panelNoBle;
    m.panelInfoPanelName.value =
        (data['panelName'] as String?) ??
        (data[StringConstants.panelname] as String?) ??
        PanelInfoDefaults.panelNameBle;
    m.panelInfoYear.value = (data['year'] as num?)?.toInt() ?? now.year;
    m.panelInfoMonth.value = (data['month'] as num?)?.toInt() ?? now.month;
    m.panelInfoDay.value = (data['day'] as num?)?.toInt() ?? now.day;
    m.panelInfoHour.value = (data['hour'] as num?)?.toInt() ?? now.hour;
    m.panelInfoMinute.value = (data['minute'] as num?)?.toInt() ?? now.minute;
    m.panelInfoSecond.value = (data['second'] as num?)?.toInt() ?? now.second;
    m.panelInfoEventReminderDelay.value =
        (data['delay'] as num?)?.toInt() ?? PanelInfoDefaults.delayBle;
  }

  static void _applyGeneralModule(BleManager m, Map<String, dynamic> data) {
    final bp = m.bleProcess;
    bp.generalModuleLvlTimeOut.value =
        (data['lvlTimeout'] as num?)?.toInt() ??
        GeneralModuleDefaults.lvlTimeoutBle;

    const buzzer = [StringConstants.accessLevel1, StringConstants.accessLevel2];
    const sounder = [
      StringConstants.accessLevel2,
      StringConstants.accessLevel3,
    ];
    const reset = [StringConstants.accessLevel2, StringConstants.accessLevel3];
    const yn = [StringConstants.no, StringConstants.yes];

    final sb =
        (data[StringConstants.silencebuzzerlevel] as String?) ??
        GeneralModuleDefaults.silenceBuzzerLevel;
    final ss =
        (data['silenceSoundersLevel'] as String?) ??
        GeneralModuleDefaults.silenceSoundersLevel;
    final rl =
        (data['resetLevel'] as String?) ?? GeneralModuleDefaults.resetLevel;
    final fl =
        (data[StringConstants.silencesounderslevel] as String?) ??
        GeneralModuleDefaults.faultLatching;

    bp.generalModuleSilenceBuzzerLvl.value =
        buzzer.contains(sb)
            ? buzzer.indexOf(sb)
            : GeneralModuleDefaults.silenceBuzzerLevelIndex;
    bp.generalModuleSilenceSounderLvl.value =
        sounder.contains(ss)
            ? sounder.indexOf(ss)
            : GeneralModuleDefaults.silenceSoundersLevelIndex;
    bp.generalModuleResetLvl.value =
        reset.contains(rl)
            ? reset.indexOf(rl)
            : GeneralModuleDefaults.resetLevelIndex;
    bp.generalModuleFaultLatching.value =
        yn.contains(fl) ? yn.indexOf(fl) : GeneralModuleDefaults.faultLatchingIndex;
  }

  static void _applyServiceDue(BleManager m, Map<String, dynamic> data) {
    m.serviceDueYear.value =
        (data['year'] as num?)?.toInt() ?? ServiceDueDefaults.year;
    m.serviceDueMonth.value =
        (data['month'] as num?)?.toInt() ?? ServiceDueDefaults.month;
    m.serviceDueDay.value =
        (data['day'] as num?)?.toInt() ?? ServiceDueDefaults.day;
    m.serviceDueHour.value =
        (data['hour'] as num?)?.toInt() ?? ServiceDueDefaults.hour;
    m.serviceDueMinute.value =
        (data['minute'] as num?)?.toInt() ?? ServiceDueDefaults.minute;
    m.serviceDueCompany.value =
        (data['company'] as String?) ?? ServiceDueDefaults.company;
    m.serviceDueContact.value =
        (data['contact'] as String?) ?? ServiceDueDefaults.contact;
    m.serviceDueReminder.value =
        (data['reminder'] as num?)?.toInt() ?? ServiceDueDefaults.reminderBle;
  }

  static const List<String> _inputGroups = [
    'None',
    'General',
    StringConstants.extOut,
  ];

  static const Map<String, List<String>> _inputFunctions = {
    'None': ['None'],
    'General': [
      StringConstants.extnlFault,
      'Reset',
      StringConstants.extnlControlsEnabled,
      StringConstants.silenceAlarm,
      StringConstants.soundAlarm,
      StringConstants.silenceBuzzer,
      StringConstants.mute,
      StringConstants.extnlSupervisory,
      StringConstants.extnlSupplyFault,
    ],
    StringConstants.extOut: [
      StringConstants.manualTrigger,
      StringConstants.manualMode,
      'Hold',
      StringConstants.extnlDisableGas,
      StringConstants.extnlExtFault,
    ],
  };

  static void _applyInput(BleManager m, Map<String, dynamic> data) {
    final gIdx = _clampInt(
      (data['group'] as num?)?.toInt() ?? InputDefaults.groupBle,
      2,
    );
    final groupName = _inputGroups[gIdx];
    final fn =
        (data['function'] as num?)?.toInt() ?? InputDefaults.functionBle;
    final opts = _inputFunctions[groupName]!;
    final fi = fn.clamp(0, opts.length - 1);

    final isEnabled =
        (data['enabled'] as bool?) ?? InputDefaults.enabledBle;
    final isTest = (data['test'] as bool?) ?? InputDefaults.testBle;
    final isInverted =
        (data['inverted'] as bool?) ?? InputDefaults.invertedBle;

    final config = InputModeConfig(
      inputEnable: isEnabled ? InputEnable.enabled : InputEnable.disabled,
      inputMode: isTest ? InputMode.test : InputMode.normal,
      latchMode: LatchMode.nonLatched,
      invertMode: isInverted ? InvertMode.inverted : InvertMode.notInverted,
    );

    m.inputMode.value = InputModeCodec.encodeHex(config);
    m.inputSetupGroup.value = gIdx;
    m.inputSetupFunction.value = fi;
    m.isInputSetupEnabled.value = isEnabled;
    m.isInputSetupTest.value = isTest;
    m.isInputSetupInverted.value = isInverted;
    m.inputSetupText.value =
        (data['text'] as String?) ?? InputDefaults.inputText;
  }

  static void _applyRelay(BleManager m, Map<String, dynamic> data) {
    for (var i = 0; i < 3; i++) {
      final r = data['r${i + 1}'] as Map<String, dynamic>?;
      if (r == null) continue;

      final defaults = RelayDefaults.relayEntry(i);
      final gIdx = _clampInt(
        (r['group'] as num?)?.toInt() ?? defaults['group'] as int,
        3,
      );
      final group = _relayGroups[gIdx];
      final opts = _relayFunctions[group]!;
      final fIdx = _clampInt(
        (r['function'] as num?)?.toInt() ?? defaults['function'] as int,
        opts.length - 1,
      );
      final isEnabled =
          (r['enabled'] as bool?) ?? defaults['enabled'] as bool;
      final isTest = (r['test'] as bool?) ?? defaults['test'] as bool;

      final cfg = OutputModeConfig(
        outputEnable: isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: isTest ? OutputMode.test : OutputMode.normal,
        supervisionMode: SupervisionMode.normal,
      );
      final hex = OutputModeCodec.encodeHex(cfg);

      var dyn =
          (r[StringConstants.outputtext] as String?) ??
          defaults[StringConstants.outputtext] as String;
      if (group == StringConstants.extOut) dyn = '1';

      switch (i) {
        case 0:
          m.relayOneMode.value = hex;
          m.relayOneSetupGroup.value = gIdx;
          m.relayOneSetupFunction.value = fIdx;
          m.isRelayOneSetupEnabled.value = isEnabled;
          m.isRelayOneSetupTest.value = isTest;
          m.relayOneSetupOutputText.value =
              (r['outputText'] as String?) ?? RelayDefaults.outputText;
          m.relayOneSetupDynamicText.value = dyn;
          break;
        case 1:
          m.relayTwoMode.value = hex;
          m.relayTwoSetupGroup.value = gIdx;
          m.relayTwoSetupFunction.value = fIdx;
          m.isRelayTwoSetupEnabled.value = isEnabled;
          m.isRelayTwoSetupTest.value = isTest;
          m.relayTwoSetupOutputText.value =
              (r['outputText'] as String?) ?? RelayDefaults.outputText;
          m.relayTwoSetupDynamicText.value = dyn;
          break;
        default:
          m.relayThreeMode.value = hex;
          m.relayThreeSetupGroup.value = gIdx;
          m.relayThreeSetupFunction.value = fIdx;
          m.isRelayThreeSetupEnabled.value = isEnabled;
          m.isRelayThreeSetupTest.value = isTest;
          m.relayThreeSetupOutputText.value =
              (r['outputText'] as String?) ?? RelayDefaults.outputText;
          m.relayThreeSetupDynamicText.value = dyn;
      }
    }
  }

  static void _applyZone(BleManager m, Map<String, dynamic> data) {
    applyZoneTestFlagsFromCacheMap(m, data);

    for (var i = 0; i < 3; i++) {
      final z = data['z${i + 1}'] as Map<String, dynamic>?;
      if (z == null) continue;

      final typeIdx =
          (z['type'] as num?)?.toInt() ?? ZoneDefaults.typeBle;
      final enabled = (z['enabled'] as bool?) ?? ZoneDefaults.enabledBle;
      final dm = _clampInt(
        (z[StringConstants.isMTL5561] as num?)?.toInt() ??
            ZoneDefaults.detectionModeBle,
        _zoneModes.length - 1,
      );
      final vTime =
          (z[StringConstants.verificationtime] as String?) ??
          ZoneDefaults.verificationTime;
      final text = (z['text'] as String?) ?? ZoneDefaults.text;

      switch (i) {
        case 0:
          m.zoneOneSetupText.value = text;
          m.zoneOneSetupType.value = typeIdx.clamp(0, 1);
          m.isZoneOneSetupEnabled.value = enabled;
          m.zoneOneSetupVerificationTime.value = vTime;
          m.zoneOneSetupDetectionMode.value = dm;
          break;
        case 1:
          m.zoneTwoSetupText.value = text;
          m.zoneTwoSetupType.value = typeIdx.clamp(0, 1);
          m.isZoneTwoSetupEnabled.value = enabled;
          m.zoneTwoSetupVerificationTime.value = vTime;
          m.zoneTwoSetupDetectionMode.value = dm;
          break;
        default:
          m.zoneThreeSetupText.value = text;
          m.zoneThreeSetupType.value = typeIdx.clamp(0, 1);
          m.isZoneThreeSetupEnabled.value = enabled;
          m.zoneThreeSetupVerificationTime.value = vTime;
          m.zoneThreeSetupDetectionMode.value = dm;
      }
    }
    syncZoneModeHexFromBleManager(m);
  }

  static void _applySounder(BleManager m, Map<String, dynamic> data) {
    for (var i = 0; i < 3; i++) {
      final s = data['s${i + 1}'] as Map<String, dynamic>?;
      if (s == null) continue;

      final defaults = SounderDefaults.mainSounderEntry(i);
      final gIdx = _clampInt(
        (s['group'] as num?)?.toInt() ?? defaults['group'] as int,
        3,
      );
      final group = _sounderGroups[gIdx];
      final opts = _sounderFunctions[group]!;
      final fIdx = _clampInt(
        (s['function'] as num?)?.toInt() ?? defaults['function'] as int,
        opts.length - 1,
      );
      final isEnabled =
          (s['enabled'] as bool?) ?? defaults['enabled'] as bool;
      final isTest = (s['test'] as bool?) ?? defaults['test'] as bool;
      final isNormal = (s['normal'] as bool?) ?? defaults['normal'] as bool;
      final outText =
          (s['outputText'] as String?) ?? SounderDefaults.outputText;
      final fn =
          (s[StringConstants.functionno] as num?)?.toInt() ??
          defaults['functionNo'] as int;

      final cfg = OutputModeConfig(
        outputEnable: isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: isTest ? OutputMode.test : OutputMode.normal,
        supervisionMode:
            isNormal ? SupervisionMode.normal : SupervisionMode.mtl5525,
      );
      final hex = OutputModeCodec.encodeHex(cfg);

      switch (i) {
        case 0:
          m.sounderOneRelayOutputMode.value = hex;
          m.sounderOneRelayFunctionGroup.value = gIdx;
          m.sounderOneRelayFunction.value = fIdx;
          m.sounderOneFunctionNo.value = fn;
          m.sounderOneOutputText.value = outText;
          m.isSounderOneEnabled.value = isEnabled;
          m.isSounderOneTest.value = isTest;
          m.isSounderOneNormal.value = isNormal;
          break;
        case 1:
          m.sounderTwoRelayOutputMode.value = hex;
          m.sounderTwoRelayFunctionGroup.value = gIdx;
          m.sounderTwoRelayFunction.value = fIdx;
          m.sounderTwoFunctionNo.value = fn;
          m.sounderTwoOutputText.value = outText;
          m.isSounderTwoEnabled.value = isEnabled;
          m.isSounderTwoTest.value = isTest;
          m.isSounderTwoNormal.value = isNormal;
          break;
        default:
          m.sounderThreeRelayOutputMode.value = hex;
          m.sounderThreeRelayFunctionGroup.value = gIdx;
          m.sounderThreeRelayFunction.value = fIdx;
          m.sounderThreeFunctionNo.value = fn;
          m.sounderThreeOutputText.value = outText;
          m.isSounderThreeEnabled.value = isEnabled;
          m.isSounderThreeTest.value = isTest;
          m.isSounderThreeNormal.value = isNormal;
      }
    }

    for (var i = 0; i < 3; i++) {
      final z = data['z${i + 1}'] as Map<String, dynamic>?;
      if (z == null) continue;
      final zoneDefaults = SounderDefaults.zoneEntry();
      final isEnabled =
          (z['enabled'] as bool?) ?? zoneDefaults['enabled'] as bool;
      final isTest = (z['test'] as bool?) ?? zoneDefaults['test'] as bool;
      final ai = _clampInt(
        (z['action'] as num?)?.toInt() ?? SounderDefaults.actionContinuousBle,
        _sounderActions.length - 1,
      );
      final zcfg = ZoneEquipmentModeConfig(
        zoneEnable:
            isEnabled
                ? ZoneEquipmentEnable.enabled
                : ZoneEquipmentEnable.disabled,
        zoneMode: isTest ? ZoneEquipmentMode.test : ZoneEquipmentMode.normal,
        sounderDelay: ZoneSounderDelay.disabled,
      );
      final zHex = ZoneEquipmentModeCodec.encodeHex(zcfg);
      switch (i) {
        case 0:
          m.sounderZoneOneMode.value = zHex;
          m.isZoneOneEnabled.value = isEnabled;
          m.isZoneOneTest.value = isTest;
          m.zoneOneAction.value = ai;
          break;
        case 1:
          m.sounderZoneTwoMode.value = zHex;
          m.isZoneTwoEnabled.value = isEnabled;
          m.isZoneTwoTest.value = isTest;
          m.zoneTwoAction.value = ai;
          break;
        default:
          m.sounderZoneThreeMode.value = zHex;
          m.isZoneThreeEnabled.value = isEnabled;
          m.isZoneThreeTest.value = isTest;
          m.zoneThreeAction.value = ai;
      }
    }

    for (var i = 0; i < 3; i++) {
      final e = data['e${i + 1}'] as Map<String, dynamic>?;
      if (e == null) continue;
      final extDefaults = SounderDefaults.extOutEntry();
      final isEnabled =
          (e['enabled'] as bool?) ?? extDefaults['enabled'] as bool;
      final isTest = (e['test'] as bool?) ?? extDefaults['test'] as bool;
      final ci = _clampInt(
        (e[StringConstants.countdownaction] as num?)?.toInt() ??
            SounderDefaults.countdownActionBle,
        _sounderExtActions.length - 1,
      );
      final hi = _clampInt(
        (e[StringConstants.holdaction] as num?)?.toInt() ??
            SounderDefaults.holdActionBle,
        _sounderExtActions.length - 1,
      );
      final ri = _clampInt(
        (e[StringConstants.releaseaction] as num?)?.toInt() ??
            SounderDefaults.releaseActionBle,
        _sounderExtActions.length - 1,
      );
      final ecfg = ExtZoneEquipmentModeConfig(
        zoneEnable:
            isEnabled
                ? ExtZoneEquipmentEnable.enabled
                : ExtZoneEquipmentEnable.disabled,
        zoneMode:
            isTest ? ExtZoneEquipmentMode.test : ExtZoneEquipmentMode.normal,
      );
      final eHex = ExtZoneEquipmentModeCodec.encodeHex(ecfg);
      switch (i) {
        case 0:
          m.sounderExtOutOneMode.value = eHex;
          m.isExtOutOneEnabled.value = isEnabled;
          m.isExtOutOneTest.value = isTest;
          m.extoutOneCountdownAction.value = ci;
          m.extoutOneHoldAction.value = hi;
          m.extoutOneReleaseAction.value = ri;
          break;
        case 1:
          m.sounderExtOutTwoMode.value = eHex;
          m.isExtOutTwoEnabled.value = isEnabled;
          m.isExtOutTwoTest.value = isTest;
          m.extoutTwoCountdownAction.value = ci;
          m.extoutTwoHoldAction.value = hi;
          m.extoutTwoReleaseAction.value = ri;
          break;
        default:
          m.sounderExtOutThreeMode.value = eHex;
          m.isExtOutThreeEnabled.value = isEnabled;
          m.isExtOutThreeTest.value = isTest;
          m.extoutThreeCountdownAction.value = ci;
          m.extoutThreeHoldAction.value = hi;
          m.extoutThreeReleaseAction.value = ri;
      }
    }

    final gen = data[StringConstants.s123] as Map<String, dynamic>?;
    if (gen != null) {
      final generalDefaults = SounderDefaults.general();
      final ge =
          (gen['enabled'] as bool?) ?? generalDefaults['enabled'] as bool;
      final gt = (gen['test'] as bool?) ?? generalDefaults['test'] as bool;
      final gd =
          (gen['delayed'] as bool?) ?? generalDefaults['delayed'] as bool;
      m.isSounderGeneralEnabled.value = ge;
      m.isSounderGeneralTest.value = gt;
      m.isSounderGeneralDelay.value = gd;
      m.sounderGeneralAction.value =
          (gen['action'] as num?)?.toInt() ??
          SounderDefaults.generalActionBle;
      m.sounderGeneralDelay.value =
          (gen['delay'] as num?)?.toInt() ?? SounderDefaults.delayBle;

      final gcfg = GeneralEquipmentModeConfig(
        equipmentEnable:
            ge ? EquipmentEnable.enabled : EquipmentEnable.disabled,
        equipmentMode: gt ? EquipmentMode.test : EquipmentMode.normal,
        sounderDelay: gd ? SounderDelay.enabled : SounderDelay.disabled,
      );
      m.sounderGeneralMode.value = GeneralEquipmentModeCodec.encodeHex(gcfg);
    }
  }

  static void _applyExtOut(BleManager m, Map<String, dynamic> data) {
    final en = _clampInt(
      (data['enabled'] as num?)?.toInt() ?? ExtOutDefaults.enabledBle,
      1,
    );
    final holdRestart = _clampInt(
      (data[StringConstants.holdmode] as num?)?.toInt() ??
          ExtOutDefaults.holdModeBle,
      HoldMode.values.length - 1,
    );
    final resetAllowedInt = _clampInt(
      (data[StringConstants.resetallowed] as num?)?.toInt() ??
          ExtOutDefaults.resetAllowedBle,
      1,
    );
    final functionInt = _clampInt(
      (data['function'] as num?)?.toInt() ?? ExtOutDefaults.functionBle,
      8,
    );
    final actuaturTypeInt = _clampInt(
      (data[StringConstants.actuatortype] as num?)?.toInt() ??
          ExtOutDefaults.actuatorTypeBle,
      3,
    );
    final resetAllowed = resetAllowedInt == 0;

    final config = ExtZoneModeConfig(
      extZoneEnable: ExtZoneEnable.values[en],
      extZoneMode: ExtZoneMode.normal,
      holdMode: HoldMode.values[holdRestart],
      resetAllowed: resetAllowed,
      flowDetectionUsed: false,
    );
    final hexValue = ExtZoneModeCodec.encodeHex(config);

    m.isExtZoneEnabled.value = en;
    m.extZoneMode.value = hexValue;
    m.extZoneCountdownAuto.value =
        (data['countdownAuto'] as num?)?.toInt() ??
        ExtOutDefaults.countdownAutoBle;
    m.extZoneCountdownMan.value =
        (data['countdownMan'] as num?)?.toInt() ??
        ExtOutDefaults.countdownManBle;
    m.extZoneReleaseTime.value =
        (data['releaseTime'] as num?)?.toInt() ??
        ExtOutDefaults.releaseTimeBle;
    m.extZoneResetDelay.value =
        (data[StringConstants.resetdelay] as num?)?.toInt() ??
        ExtOutDefaults.resetDelayBle;
    m.extZoneAction.value = _clampInt(
      (data['action'] as num?)?.toInt() ?? ExtOutDefaults.actionBle,
      9,
    );
    m.extZoneFunction.value = functionInt;
    m.extZoneActuatorType.value = actuaturTypeInt;
    m.isResetAllowed.value = resetAllowedInt;
    m.extZoneHoldMode.value = holdRestart;
    m.extZoneText.value = (data['text'] as String?) ?? '';

    final solar = data[StringConstants.issolar] == true;
    m.bleProcess.isExtOutApplyButtonActive.value = solar;
  }
}
