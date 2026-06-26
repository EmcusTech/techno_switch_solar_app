import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
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
    StringConstants.zone: ['Fault', 'Fire', StringConstants.disablement, StringConstants.fireSnd],
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
    StringConstants.extOut: [StringConstants.extSnd1, 'Ext. Snd 2', StringConstants.manReleaseSnd],
  };

  static const List<String> _zoneModes = [
    StringConstants.normal,
    StringConstants.none,
    StringConstants.verified,
    StringConstants.immediate,
  ];

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
      while (list.length < 31) {
        list.add(const LBusSetupData());
      }
      m.lBusSetupDataList.value = list;
    }

    final extOut = await PeripheralSetupCache.loadExtOutSetup(deviceId);
    if (extOut != null) _applyExtOut(m, extOut);
  }

  static void _applyPanelInfo(BleManager m, Map<String, dynamic> data) {
    m.panelInfoPanelNo.value = (data[StringConstants.offlineprovisioned] as num?)?.toInt() ?? 0;
    m.panelInfoPanelName.value = (data[StringConstants.panelname] as String?) ?? '';
    m.panelInfoYear.value = (data['year'] as num?)?.toInt() ?? 0;
    m.panelInfoMonth.value = (data['month'] as num?)?.toInt() ?? 0;
    m.panelInfoDay.value = (data['day'] as num?)?.toInt() ?? 0;
    m.panelInfoHour.value = (data['hour'] as num?)?.toInt() ?? 0;
    m.panelInfoMinute.value = (data['minute'] as num?)?.toInt() ?? 0;
    m.panelInfoSecond.value = (data['second'] as num?)?.toInt() ?? 0;
    m.panelInfoEventReminderDelay.value = (data['delay'] as num?)?.toInt() ?? 0;
  }

  static void _applyGeneralModule(BleManager m, Map<String, dynamic> data) {
    final bp = m.bleProcess;
    bp.generalModuleLvlTimeOut.value =
        (data['lvlTimeout'] as num?)?.toInt() ?? 0;

    const buzzer = [StringConstants.accessLevel1, StringConstants.accessLevel2];
    const sounder = [StringConstants.accessLevel2, StringConstants.accessLevel3];
    const reset = [StringConstants.accessLevel2, StringConstants.accessLevel3];
    const yn = ['No', StringConstants.yes];

    final sb = (data[StringConstants.silencebuzzerlevel] as String?) ?? buzzer.first;
    final ss = (data['silenceSoundersLevel'] as String?) ?? sounder.first;
    final rl = (data['resetLevel'] as String?) ?? reset.first;
    final fl = (data[StringConstants.silencesounderslevel] as String?) ?? yn.first;

    bp.generalModuleSilenceBuzzerLvl.value =
        buzzer.contains(sb) ? buzzer.indexOf(sb) : 0;
    bp.generalModuleSilenceSounderLvl.value =
        sounder.contains(ss) ? sounder.indexOf(ss) : 0;
    bp.generalModuleResetLvl.value = reset.contains(rl) ? reset.indexOf(rl) : 0;
    bp.generalModuleFaultLatching.value = yn.contains(fl) ? yn.indexOf(fl) : 0;
  }

  static void _applyServiceDue(BleManager m, Map<String, dynamic> data) {
    m.serviceDueYear.value = (data['year'] as num?)?.toInt() ?? 0;
    m.serviceDueMonth.value = (data['month'] as num?)?.toInt() ?? 0;
    m.serviceDueDay.value = (data['day'] as num?)?.toInt() ?? 0;
    m.serviceDueHour.value = (data['hour'] as num?)?.toInt() ?? 0;
    m.serviceDueMinute.value = (data['minute'] as num?)?.toInt() ?? 0;
    m.serviceDueCompany.value = (data['company'] as String?) ?? '';
    m.serviceDueContact.value = (data['contact'] as String?) ?? '';
    m.serviceDueReminder.value = (data['reminder'] as num?)?.toInt() ?? 0;
  }

  static const List<String> _inputGroups = ['None', 'General', StringConstants.extOut];

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
    final gIdx = _clampInt((data['group'] as num?)?.toInt() ?? 0, 2);
    final groupName = _inputGroups[gIdx];
    final fn = (data['function'] as num?)?.toInt() ?? 0;
    final opts = _inputFunctions[groupName]!;
    final fi = fn.clamp(0, opts.length - 1);

    final isEnabled = data['enabled'] == true;
    final isTest = data['test'] == true;
    final isInverted = data['inverted'] == true;

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
    m.inputSetupText.value = (data['text'] as String?) ?? '';
  }

  static void _applyRelay(BleManager m, Map<String, dynamic> data) {
    for (var i = 0; i < 3; i++) {
      final r = data['r${i + 1}'] as Map<String, dynamic>?;
      if (r == null) continue;

      final gIdx = _clampInt((r['group'] as num?)?.toInt() ?? 0, 3);
      final group = _relayGroups[gIdx];
      final opts = _relayFunctions[group]!;
      final fIdx = _clampInt(
        (r['function'] as num?)?.toInt() ?? 0,
        opts.length - 1,
      );
      final isEnabled = r['enabled'] == true;
      final isTest = r['test'] == true;

      final cfg = OutputModeConfig(
        outputEnable: isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: isTest ? OutputMode.test : OutputMode.normal,
        supervisionMode: SupervisionMode.normal,
      );
      final hex = OutputModeCodec.encodeHex(cfg);

      var dyn = (r[StringConstants.outputtext] as String?) ?? '';
      if (group == StringConstants.extOut) dyn = '1';

      switch (i) {
        case 0:
          m.relayOneMode.value = hex;
          m.relayOneSetupGroup.value = gIdx;
          m.relayOneSetupFunction.value = fIdx;
          m.isRelayOneSetupEnabled.value = isEnabled;
          m.isRelayOneSetupTest.value = isTest;
          m.relayOneSetupOutputText.value = (r['outputText'] as String?) ?? '';
          m.relayOneSetupDynamicText.value = dyn;
          break;
        case 1:
          m.relayTwoMode.value = hex;
          m.relayTwoSetupGroup.value = gIdx;
          m.relayTwoSetupFunction.value = fIdx;
          m.isRelayTwoSetupEnabled.value = isEnabled;
          m.isRelayTwoSetupTest.value = isTest;
          m.relayTwoSetupOutputText.value = (r['outputText'] as String?) ?? '';
          m.relayTwoSetupDynamicText.value = dyn;
          break;
        default:
          m.relayThreeMode.value = hex;
          m.relayThreeSetupGroup.value = gIdx;
          m.relayThreeSetupFunction.value = fIdx;
          m.isRelayThreeSetupEnabled.value = isEnabled;
          m.isRelayThreeSetupTest.value = isTest;
          m.relayThreeSetupOutputText.value =
              (r['outputText'] as String?) ?? '';
          m.relayThreeSetupDynamicText.value = dyn;
      }
    }
  }

  static void _applyZone(BleManager m, Map<String, dynamic> data) {
    applyZoneTestFlagsFromCacheMap(m, data);

    for (var i = 0; i < 3; i++) {
      final z = data['z${i + 1}'] as Map<String, dynamic>?;
      if (z == null) continue;

      final typeIdx = (z['type'] as num?)?.toInt() ?? 0;
      final enabled = z['enabled'] == true;
      final dm = _clampInt(
        (z[StringConstants.isMTL5561] as num?)?.toInt() ?? 0,
        _zoneModes.length - 1,
      );
      final vTime = (z[StringConstants.verificationtime] as String?) ?? '0';
      final text = (z['text'] as String?) ?? '';

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

      final gIdx = _clampInt((s['group'] as num?)?.toInt() ?? 0, 3);
      final group = _sounderGroups[gIdx];
      final opts = _sounderFunctions[group]!;
      final fIdx = _clampInt(
        (s['function'] as num?)?.toInt() ?? 0,
        opts.length - 1,
      );
      final isEnabled = s['enabled'] == true;
      final isTest = s['test'] == true;
      final isNormal = s['normal'] != false;
      final outText = (s['outputText'] as String?) ?? '';
      final fn = (s[StringConstants.functionno] as num?)?.toInt() ?? 0;

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
      final isEnabled = z['enabled'] == true;
      final isTest = z['test'] == true;
      final ai = _clampInt(
        (z['action'] as num?)?.toInt() ?? 0,
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
      final isEnabled = e['enabled'] == true;
      final isTest = e['test'] == true;
      final ci = _clampInt(
        (e[StringConstants.countdownaction] as num?)?.toInt() ?? 0,
        _sounderExtActions.length - 1,
      );
      final hi = _clampInt(
        (e[StringConstants.holdaction] as num?)?.toInt() ?? 0,
        _sounderExtActions.length - 1,
      );
      final ri = _clampInt(
        (e[StringConstants.releaseaction] as num?)?.toInt() ?? 0,
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
      final ge = gen['enabled'] == true;
      final gt = gen['test'] == true;
      final gd = gen['delayed'] == true;
      m.isSounderGeneralEnabled.value = ge;
      m.isSounderGeneralTest.value = gt;
      m.isSounderGeneralDelay.value = gd;
      m.sounderGeneralAction.value = (gen['action'] as num?)?.toInt() ?? 0;
      m.sounderGeneralDelay.value = (gen['delay'] as num?)?.toInt() ?? 0;

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
    final en = _clampInt((data['enabled'] as num?)?.toInt() ?? 0, 1);
    final holdRestart = _clampInt(
      (data[StringConstants.holdmode] as num?)?.toInt() ?? 0,
      HoldMode.values.length - 1,
    );
    final resetAllowedInt = _clampInt(
      (data[StringConstants.resetallowed] as num?)?.toInt() ?? 0,
      1,
    );
    final functionInt = _clampInt((data['function'] as num?)?.toInt() ?? 0, 8);
    final actuaturTypeInt = _clampInt(
      (data[StringConstants.actuatortype] as num?)?.toInt() ?? 0,
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
        (data['countdownAuto'] as num?)?.toInt() ?? 0;
    m.extZoneCountdownMan.value = (data['countdownMan'] as num?)?.toInt() ?? 0;
    m.extZoneReleaseTime.value = (data['releaseTime'] as num?)?.toInt() ?? 0;
    m.extZoneResetDelay.value = (data[StringConstants.resetdelay] as num?)?.toInt() ?? 0;
    m.extZoneAction.value = _clampInt(
      (data['action'] as num?)?.toInt() ?? 0,
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
