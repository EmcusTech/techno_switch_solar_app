import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/modes/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/sounder_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/modes/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/modes/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SounderConfig {
  final int index;

  String group = 'None';
  String function = 'None';
  String enabled = SounderDefaults.enabledLabel;
  String type = SounderDefaults.typeLabel;

  bool groupLocked = false;
  bool functionLocked = false;

  TextEditingController outputController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();

  SounderConfig({required this.index});
}

class ZoneConfig {
  final int index;

  String enabled = SounderDefaults.zoneEnabledLabel;
  String test = SounderDefaults.zoneTestLabel;
  String action = SounderDefaults.actionContinuousLabel;

  ZoneConfig({required this.index});
}

class ExtOutConfig {
  final int index;

  String enabled = SounderDefaults.extOutEnabledLabel;
  String test = SounderDefaults.extOutTestLabel;
  String countdownAction = SounderDefaults.countdownActionLabel;
  String holdAction = SounderDefaults.holdActionLabel;
  String releaseAction = SounderDefaults.releaseActionLabel;

  ExtOutConfig({required this.index});
}

/// Controller for the Sounder Mode bottom sheet.
class SounderModeController extends PeripheralModeController {
  SounderModeController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  final List<String> groupOptions = [
    'None',
    'General',
    StringConstants.zone,
    StringConstants.extOut,
  ];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [StringConstants.fireSnd],
    StringConstants.zone: [StringConstants.fireSnd],
    StringConstants.extOut: [
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
    ],
  };

  final List<String> yesNoOptions = ['No', StringConstants.yes];

  final List<String> typeOptions = [
    PanelValues.sounderTypeNormal,
    StringConstants.isMTL5525,
  ];

  final List<String> actionOptions = [
    'Continuous',
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
  ];

  final List<String> extOutActionOptions = [
    'Continuous',
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
    StringConstants.off,
  ];

  final functions = [
    StringConstants.extSnd1,
    'Ext. Snd 2',
    StringConstants.manReleaseSnd,
  ];

  late List<SounderConfig> sounders;
  late List<ZoneConfig> zones;
  late List<ExtOutConfig> extOuts;

  final TextEditingController delayController = TextEditingController(
    text: SounderDefaults.delayBle.toString(),
  );

  String delayed = SounderDefaults.delayedLabel;

  @override
  void initModel() {
    sounders = List.generate(3, (i) {
      final config = SounderConfig(index: i);
      _applyMainSounderConfig(config, i, SounderDefaults.mainSounderEntry(i));
      if (i == 0) {
        config.groupLocked = true;
        config.functionLocked = true;
      }
      return config;
    });
    zones = List.generate(3, (i) {
      final zone = ZoneConfig(index: i);
      _applyZoneFromMap(SounderDefaults.zoneEntry(), zone: zone);
      return zone;
    });
    extOuts = List.generate(3, (i) {
      final extOut = ExtOutConfig(index: i);
      _applyExtOutFromMap(extOut, SounderDefaults.extOutEntry());
      return extOut;
    });
  }

  String _boolToYesNo(bool value) => value ? StringConstants.yes : 'No';

  void _applyMainSounderFromMap(int index, Map<String, dynamic> data) {
    _applyMainSounderConfig(sounders[index], index, data);
  }

  void _applyMainSounderConfig(
    SounderConfig sounder,
    int index,
    Map<String, dynamic> data,
  ) {
    final defaults = SounderDefaults.mainSounderEntry(index);
    final enabled = (data['enabled'] as bool?) ?? defaults['enabled'] as bool;
    sounder.enabled = _boolToYesNo(enabled);
    final normal = (data['normal'] as bool?) ?? defaults['normal'] as bool;
    sounder.type = SounderDefaults.typeLabelFromNormal(normal);
    sounder.outputController.text =
        (data['outputText'] as String?) ?? SounderDefaults.outputText;
    final groupIdx =
        ((data['group'] as num?)?.toInt() ?? defaults['group'] as int).clamp(
          0,
          groupOptions.length - 1,
        );
    sounder.group = groupOptions[groupIdx];
    final fnOpts = functionOptionsMap[sounder.group]!;
    final fnIdx =
        ((data['function'] as num?)?.toInt() ?? defaults['function'] as int)
            .clamp(0, fnOpts.length - 1);
    sounder.function = fnOpts[fnIdx];
    if (index > 0) {
      sounder.dynamicController.text =
          ((data[StringConstants.functionno] as num?)?.toInt() ??
                  defaults['functionNo'] as int)
              .toString();
    }
  }

  void _applyZoneFromMap(Map<String, dynamic> data, {required ZoneConfig zone}) {
    final enabled = (data['enabled'] as bool?) ?? SounderDefaults.enabledBle;
    zone.enabled = _boolToYesNo(enabled);
    final test = (data['test'] as bool?) ?? SounderDefaults.testBle;
    zone.test = _boolToYesNo(test);
    final actionIdx =
        ((data['action'] as num?)?.toInt() ?? SounderDefaults.actionContinuousBle)
            .clamp(0, actionOptions.length - 1);
    zone.action = actionOptions[actionIdx];
  }

  void _applyExtOutFromMap(ExtOutConfig extOut, Map<String, dynamic> data) {
    final enabled = (data['enabled'] as bool?) ?? SounderDefaults.enabledBle;
    extOut.enabled = _boolToYesNo(enabled);
    final test = (data['test'] as bool?) ?? SounderDefaults.testBle;
    extOut.test = _boolToYesNo(test);
    extOut.countdownAction =
        extOutActionOptions[((data[StringConstants.countdownaction] as num?)
                    ?.toInt() ??
                SounderDefaults.countdownActionBle)
            .clamp(0, extOutActionOptions.length - 1)];
    extOut.holdAction =
        extOutActionOptions[((data[StringConstants.holdaction] as num?)?.toInt() ??
                SounderDefaults.holdActionBle)
            .clamp(0, extOutActionOptions.length - 1)];
    extOut.releaseAction =
        extOutActionOptions[((data[StringConstants.releaseaction] as num?)
                    ?.toInt() ??
                SounderDefaults.releaseActionBle)
            .clamp(0, extOutActionOptions.length - 1)];
  }

  void _applyGeneralToManager(Map<String, dynamic> data) {
    final m = manager;
    if (m == null) return;
    final enabled =
        (data['enabled'] as bool?) ?? SounderDefaults.generalEnabledBle;
    final test = (data['test'] as bool?) ?? SounderDefaults.generalTestBle;
    final delayedFlag = (data['delayed'] as bool?) ?? SounderDefaults.delayedBle;
    m.isSounderGeneralEnabled.value = enabled;
    m.isSounderGeneralTest.value = test;
    m.isSounderGeneralDelay.value = delayedFlag;
    m.sounderGeneralAction.value =
        (data['action'] as num?)?.toInt() ?? SounderDefaults.generalActionBle;
    m.sounderGeneralDelay.value =
        (data['delay'] as num?)?.toInt() ?? SounderDefaults.delayBle;
    m.sounderGeneralMode.value = GeneralEquipmentModeCodec.encodeHex(
      GeneralEquipmentModeConfig(
        equipmentEnable:
            enabled ? EquipmentEnable.enabled : EquipmentEnable.disabled,
        equipmentMode: test ? EquipmentMode.test : EquipmentMode.normal,
        sounderDelay:
            delayedFlag ? SounderDelay.enabled : SounderDelay.disabled,
      ),
    );
  }

  @override
  void disposeModel() {
    for (final s in sounders) {
      s.outputController.dispose();
      s.dynamicController.dispose();
    }
    delayController.dispose();
  }

  bool _isDelayValid() {
    final val = int.tryParse(delayController.text);
    return val != null && val >= 0 && val <= 600;
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadSounderSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (data['s1'] != null) {
      _applyMainSounderFromMap(0, Map<String, dynamic>.from(data['s1'] as Map));
    }
    if (data[StringConstants.s2] != null) {
      _applyMainSounderFromMap(
        1,
        Map<String, dynamic>.from(data[StringConstants.s2] as Map),
      );
    }
    if (data[StringConstants.s3] != null) {
      _applyMainSounderFromMap(
        2,
        Map<String, dynamic>.from(data[StringConstants.s3] as Map),
      );
    }
    for (var i = 0; i < 3; i++) {
      final key =
          i == 0
              ? StringConstants.z1
              : i == 1
              ? StringConstants.z2
              : StringConstants.z3;
      final z = data[key] as Map<String, dynamic>?;
      if (z != null) _applyZoneFromMap(z, zone: zones[i]);
    }
    for (var i = 0; i < 3; i++) {
      final key = i == 0 ? StringConstants.e1 : i == 1 ? StringConstants.e2 : 'e3';
      final e = data[key] as Map<String, dynamic>?;
      if (e != null) _applyExtOutFromMap(extOuts[i], e);
    }
    final gen = data[StringConstants.s123] as Map<String, dynamic>?;
    if (gen != null) {
      delayController.text =
          (gen['delay'] as int?)?.toString() ??
          SounderDefaults.delayBle.toString();
      delayed =
          (gen['delayed'] as bool?) ?? SounderDefaults.delayedBle
              ? SounderDefaults.delayedLabel
              : PanelValues.noOption;
      _applyGeneralToManager(gen);
    }
    if (manager != null) {
      applySounderMainTestFlagsFromCacheMap(manager!, data);
    }
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    final sounderOne = sounders[0];
    final sounderTwo = sounders[1];
    final sounderThree = sounders[2];

    sounderOne.enabled =
        manager!.isSounderOneEnabled.value ? StringConstants.yes : 'No';
    sounderOne.type = SounderDefaults.typeLabelFromNormal(
      manager!.isSounderOneNormal.value,
    );
    sounderTwo.enabled =
        manager!.isSounderTwoEnabled.value ? StringConstants.yes : 'No';
    sounderTwo.type = SounderDefaults.typeLabelFromNormal(
      manager!.isSounderTwoNormal.value,
    );
    sounderThree.enabled =
        manager!.isSounderThreeEnabled.value ? StringConstants.yes : 'No';
    sounderThree.type = SounderDefaults.typeLabelFromNormal(
      manager!.isSounderThreeNormal.value,
    );
    sounderOne.outputController.text = manager!.sounderOneOutputText.value;
    sounderTwo.outputController.text = manager!.sounderTwoOutputText.value;
    sounderThree.outputController.text = manager!.sounderThreeOutputText.value;

    sounderOne.group =
        groupOptions[manager!.sounderOneRelayFunctionGroup.value];
    sounderTwo.group =
        groupOptions[manager!.sounderTwoRelayFunctionGroup.value];
    sounderThree.group =
        groupOptions[manager!.sounderThreeRelayFunctionGroup.value];
    sounderOne.function =
        functionOptionsMap[sounderOne.group]![manager!
            .sounderOneRelayFunction
            .value];
    sounderTwo.function =
        functionOptionsMap[sounderTwo.group]![manager!
            .sounderTwoRelayFunction
            .value];
    sounderThree.function =
        functionOptionsMap[sounderThree.group]![manager!
            .sounderThreeRelayFunction
            .value];

    sounderTwo.dynamicController.text =
        manager!.sounderTwoFunctionNo.value.toString();
    sounderThree.dynamicController.text =
        manager!.sounderThreeFunctionNo.value.toString();

    delayController.text = manager!.sounderGeneralDelay.value.toString();
    delayed =
        manager!.isSounderGeneralDelay.value
            ? SounderDefaults.delayedLabel
            : PanelValues.noOption;

    final zoneOne = zones[0];
    final zoneTwo = zones[1];
    final zoneThree = zones[2];

    zoneOne.enabled =
        manager!.isZoneOneEnabled.value ? StringConstants.yes : 'No';
    zoneOne.test = manager!.isZoneOneTest.value ? StringConstants.yes : 'No';
    zoneOne.action = actionOptions[manager!.zoneOneAction.value];
    zoneTwo.enabled =
        manager!.isZoneTwoEnabled.value ? StringConstants.yes : 'No';
    zoneTwo.test = manager!.isZoneTwoTest.value ? StringConstants.yes : 'No';
    zoneTwo.action = actionOptions[manager!.zoneTwoAction.value];
    zoneThree.enabled =
        manager!.isZoneThreeEnabled.value ? StringConstants.yes : 'No';
    zoneThree.test =
        manager!.isZoneThreeTest.value ? StringConstants.yes : 'No';
    zoneThree.action = actionOptions[manager!.zoneThreeAction.value];

    final extOutOne = extOuts[0];
    final extOutTwo = extOuts[1];
    final extOutThree = extOuts[2];

    extOutOne.enabled =
        manager!.isExtOutOneEnabled.value ? StringConstants.yes : 'No';
    extOutOne.test =
        manager!.isExtOutOneTest.value ? StringConstants.yes : 'No';
    extOutOne.countdownAction =
        extOutActionOptions[manager!.extoutOneCountdownAction.value];
    extOutOne.holdAction =
        extOutActionOptions[manager!.extoutOneHoldAction.value];
    extOutOne.releaseAction =
        extOutActionOptions[manager!.extoutOneReleaseAction.value];
    extOutTwo.enabled =
        manager!.isExtOutTwoEnabled.value ? StringConstants.yes : 'No';
    extOutTwo.test =
        manager!.isExtOutTwoTest.value ? StringConstants.yes : 'No';
    extOutTwo.countdownAction =
        extOutActionOptions[manager!.extoutTwoCountdownAction.value];
    extOutTwo.holdAction =
        extOutActionOptions[manager!.extoutTwoHoldAction.value];
    extOutTwo.releaseAction =
        extOutActionOptions[manager!.extoutTwoReleaseAction.value];
    extOutThree.enabled =
        manager!.isExtOutThreeEnabled.value ? StringConstants.yes : 'No';
    extOutThree.test =
        manager!.isExtOutThreeTest.value ? StringConstants.yes : 'No';
    extOutThree.countdownAction =
        extOutActionOptions[manager!.extoutThreeCountdownAction.value];
    extOutThree.holdAction =
        extOutActionOptions[manager!.extoutThreeHoldAction.value];
    extOutThree.releaseAction =
        extOutActionOptions[manager!.extoutThreeReleaseAction.value];

    refreshUi();
  }

  int returnIndex(String value, List<String> list) => list.indexOf(value);

  @override
  void pushToManager() {
    final m = manager!;
    final snapshotTest = [
      m.isSounderOneTest.value,
      m.isSounderTwoTest.value,
      m.isSounderThreeTest.value,
    ];
    for (int i = 0; i < 3; i++) {
      final sounder = sounders[i];

      bool isEnabled = sounder.enabled == StringConstants.yes;
      bool isTest = isEnabled && snapshotTest[i];
      bool isNormal = sounder.type == PanelValues.sounderTypeNormal;
      String outputText = sounder.outputController.text;
      int functionNo = int.tryParse(sounder.dynamicController.text) ?? 0;
      int groupIndex = returnIndex(sounder.group, groupOptions);
      int functionIndex = returnIndex(
        sounder.function,
        functionOptionsMap[sounder.group]!,
      );

      switch (i) {
        case 0:
          m.sounderOneRelayFunctionGroup.value = groupIndex;
          m.sounderOneRelayFunction.value = functionIndex;
          m.sounderOneFunctionNo.value = functionNo;
          m.sounderOneOutputText.value = outputText;
          m.isSounderOneEnabled.value = isEnabled;
          m.isSounderOneTest.value = isTest;
          m.isSounderOneNormal.value = isNormal;
          break;
        case 1:
          m.sounderTwoRelayFunctionGroup.value = groupIndex;
          m.sounderTwoRelayFunction.value = functionIndex;
          m.sounderTwoFunctionNo.value = functionNo;
          m.sounderTwoOutputText.value = outputText;
          m.isSounderTwoEnabled.value = isEnabled;
          m.isSounderTwoTest.value = isTest;
          m.isSounderTwoNormal.value = isNormal;
          break;
        case 2:
          m.sounderThreeRelayFunctionGroup.value = groupIndex;
          m.sounderThreeRelayFunction.value = functionIndex;
          m.sounderThreeFunctionNo.value = functionNo;
          m.sounderThreeOutputText.value = outputText;
          m.isSounderThreeEnabled.value = isEnabled;
          m.isSounderThreeTest.value = isTest;
          m.isSounderThreeNormal.value = isNormal;
          break;
      }
    }
    syncSounderMainOutputModeHexFromBleManager(m);

    final generalConfig = GeneralEquipmentModeConfig(
      equipmentEnable:
          m.isSounderGeneralEnabled.value
              ? EquipmentEnable.enabled
              : EquipmentEnable.disabled,
      equipmentMode:
          m.isSounderGeneralTest.value
              ? EquipmentMode.test
              : EquipmentMode.normal,
      sounderDelay:
          m.isSounderGeneralDelay.value
              ? SounderDelay.enabled
              : SounderDelay.disabled,
    );
    m.sounderGeneralMode.value = GeneralEquipmentModeCodec.encodeHex(
      generalConfig,
    );
    m.sounderGeneralDelay.value =
        int.tryParse(delayController.text) ?? SounderDefaults.delayBle;

    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      bool isEnabled = zone.enabled == StringConstants.yes;
      bool isTest = zone.test == StringConstants.yes;
      int actionIndex = returnIndex(zone.action, actionOptions);
      final zoneConfig = ZoneEquipmentModeConfig(
        zoneEnable:
            isEnabled
                ? ZoneEquipmentEnable.enabled
                : ZoneEquipmentEnable.disabled,
        zoneMode: isTest ? ZoneEquipmentMode.test : ZoneEquipmentMode.normal,
        sounderDelay: ZoneSounderDelay.disabled,
      );
      final String zoneHexValue = ZoneEquipmentModeCodec.encodeHex(zoneConfig);

      switch (i) {
        case 0:
          m.sounderZoneOneMode.value = zoneHexValue;
          m.isZoneOneEnabled.value = isEnabled;
          m.isZoneOneTest.value = isTest;
          m.zoneOneAction.value = actionIndex;
          break;
        case 1:
          m.sounderZoneTwoMode.value = zoneHexValue;
          m.isZoneTwoEnabled.value = isEnabled;
          m.isZoneTwoTest.value = isTest;
          m.zoneTwoAction.value = actionIndex;
          break;
        case 2:
          m.sounderZoneThreeMode.value = zoneHexValue;
          m.isZoneThreeEnabled.value = isEnabled;
          m.isZoneThreeTest.value = isTest;
          m.zoneThreeAction.value = actionIndex;
          break;
      }
    }

    for (int i = 0; i < 3; i++) {
      final extOut = extOuts[i];
      bool isEnabled = extOut.enabled == StringConstants.yes;
      bool isTest = extOut.test == StringConstants.yes;
      int countdownIndex = returnIndex(
        extOut.countdownAction,
        extOutActionOptions,
      );
      int holdIndex = returnIndex(extOut.holdAction, extOutActionOptions);
      int releaseIndex = returnIndex(extOut.releaseAction, extOutActionOptions);

      final extOutConfig = ExtZoneEquipmentModeConfig(
        zoneEnable:
            isEnabled
                ? ExtZoneEquipmentEnable.enabled
                : ExtZoneEquipmentEnable.disabled,
        zoneMode:
            isTest ? ExtZoneEquipmentMode.test : ExtZoneEquipmentMode.normal,
      );
      final String extOutHexValue = ExtZoneEquipmentModeCodec.encodeHex(
        extOutConfig,
      );

      switch (i) {
        case 0:
          m.sounderExtOutOneMode.value = extOutHexValue;
          m.isExtOutOneEnabled.value = isEnabled;
          m.isExtOutOneTest.value = isTest;
          m.extoutOneCountdownAction.value = countdownIndex;
          m.extoutOneHoldAction.value = holdIndex;
          m.extoutOneReleaseAction.value = releaseIndex;
          break;
        case 1:
          m.sounderExtOutTwoMode.value = extOutHexValue;
          m.isExtOutTwoEnabled.value = isEnabled;
          m.isExtOutTwoTest.value = isTest;
          m.extoutTwoCountdownAction.value = countdownIndex;
          m.extoutTwoHoldAction.value = holdIndex;
          m.extoutTwoReleaseAction.value = releaseIndex;
          break;
        case 2:
          m.sounderExtOutThreeMode.value = extOutHexValue;
          m.isExtOutThreeEnabled.value = isEnabled;
          m.isExtOutThreeTest.value = isTest;
          m.extoutThreeCountdownAction.value = countdownIndex;
          m.extoutThreeHoldAction.value = holdIndex;
          m.extoutThreeReleaseAction.value = releaseIndex;
          break;
      }
    }
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveSounder(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() => _isDelayValid();

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void setSounderGroup(int index, String v) {
    sounders[index].group = v;
    sounders[index].function = functionOptionsMap[v]!.first;
    refreshUi();
  }

  void setSounderFunction(int index, String v) {
    sounders[index].function = v;
    refreshUi();
  }

  void setSounderEnabled(int index, String v) {
    sounders[index].enabled = v;
    if (v == 'No' && manager != null) {
      clearSounderMainTestOnManager(manager!, sounders[index].index);
    }
    refreshUi();
  }

  void setSounderType(int index, String v) {
    sounders[index].type = v;
    refreshUi();
  }

  void setZoneEnabled(int index, String v) {
    zones[index].enabled = v;
    refreshUi();
  }

  void setZoneTest(int index, String v) {
    zones[index].test = v;
    refreshUi();
  }

  void setZoneAction(int index, String v) {
    zones[index].action = v;
    refreshUi();
  }

  void setExtEnabled(int index, String v) {
    extOuts[index].enabled = v;
    refreshUi();
  }

  void setExtTest(int index, String v) {
    extOuts[index].test = v;
    refreshUi();
  }

  void setExtCountdown(int index, String v) {
    extOuts[index].countdownAction = v;
    refreshUi();
  }

  void setExtHold(int index, String v) {
    extOuts[index].holdAction = v;
    refreshUi();
  }

  void setExtRelease(int index, String v) {
    extOuts[index].releaseAction = v;
    refreshUi();
  }
}
