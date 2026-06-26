import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SounderConfig {
  final int index;

  String group = 'None';
  String function = 'None';
  String enabled = 'No';
  String type = StringConstants.none;

  bool groupLocked = false;
  bool functionLocked = false;

  TextEditingController outputController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();

  SounderConfig({required this.index});
}

class ZoneConfig {
  final int index;

  String enabled = 'No';
  String test = 'No';
  String action = 'Continuous';

  ZoneConfig({required this.index});
}

class ExtOutConfig {
  final int index;

  String enabled = 'No';
  String test = 'No';
  String countdownAction = 'Continuous';
  String holdAction = 'Continuous';
  String releaseAction = 'Continuous';

  ExtOutConfig({required this.index});
}

/// Controller for the Sounder Mode bottom sheet.
class SounderModeController extends PeripheralModeController {
  SounderModeController({required super.deviceId, required super.refreshTrigger});

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

  final List<String> typeOptions = [StringConstants.none, StringConstants.isMTL5525];

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

  final TextEditingController delayController = TextEditingController(text: '0');

  String delayed = 'No';

  @override
  void initModel() {
    sounders = List.generate(3, (i) {
      final config = SounderConfig(index: i);
      if (i == 0) {
        config.group = 'General';
        config.function = StringConstants.fireSnd;
        config.groupLocked = true;
        config.functionLocked = true;
      }
      return config;
    });
    zones = List.generate(3, (i) => ZoneConfig(index: i));
    extOuts = List.generate(3, (i) => ExtOutConfig(index: i));
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
    final s1 = data['s1'] as Map<String, dynamic>?;
    final s2 = data[StringConstants.s2] as Map<String, dynamic>?;
    final s3 = data[StringConstants.s3] as Map<String, dynamic>?;
    final z1 = data[StringConstants.z1] as Map<String, dynamic>?;
    final z2 = data[StringConstants.z2] as Map<String, dynamic>?;
    final z3 = data[StringConstants.z3] as Map<String, dynamic>?;
    final e1 = data[StringConstants.e1] as Map<String, dynamic>?;
    final e2 = data[StringConstants.e2] as Map<String, dynamic>?;
    final e3 = data['e3'] as Map<String, dynamic>?;

    if (s1 != null) {
      sounders[0].enabled = (s1['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      sounders[0].type =
          (s1['normal'] as bool?) ?? true ? StringConstants.none : StringConstants.isMTL5525;
      sounders[0].outputController.text = (s1['outputText'] as String?) ?? '';
      sounders[0].group =
          groupOptions[((s1['group'] as int?) ?? 0).clamp(0, groupOptions.length - 1)];
      sounders[0].function =
          functionOptionsMap[sounders[0].group]![((s1['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[0].group]!.length - 1)];
    }
    if (s2 != null) {
      sounders[1].enabled = (s2['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      sounders[1].type =
          (s2['normal'] as bool?) ?? true ? StringConstants.none : StringConstants.isMTL5525;
      sounders[1].outputController.text = (s2['outputText'] as String?) ?? '';
      sounders[1].group =
          groupOptions[((s2['group'] as int?) ?? 0).clamp(0, groupOptions.length - 1)];
      sounders[1].function =
          functionOptionsMap[sounders[1].group]![((s2['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[1].group]!.length - 1)];
      sounders[1].dynamicController.text =
          (s2[StringConstants.functionno] as int?)?.toString() ?? '0';
    }
    if (s3 != null) {
      sounders[2].enabled = (s3['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      sounders[2].type =
          (s3['normal'] as bool?) ?? true ? StringConstants.none : StringConstants.isMTL5525;
      sounders[2].outputController.text = (s3['outputText'] as String?) ?? '';
      sounders[2].group =
          groupOptions[((s3['group'] as int?) ?? 0).clamp(0, groupOptions.length - 1)];
      sounders[2].function =
          functionOptionsMap[sounders[2].group]![((s3['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[2].group]!.length - 1)];
      sounders[2].dynamicController.text =
          (s3[StringConstants.functionno] as int?)?.toString() ?? '0';
    }
    if (z1 != null) {
      zones[0].enabled = (z1['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[0].test = (z1['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[0].action =
          actionOptions[((z1['action'] as int?) ?? 0).clamp(0, actionOptions.length - 1)];
    }
    if (z2 != null) {
      zones[1].enabled = (z2['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[1].test = (z2['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[1].action =
          actionOptions[((z2['action'] as int?) ?? 0).clamp(0, actionOptions.length - 1)];
    }
    if (z3 != null) {
      zones[2].enabled = (z3['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[2].test = (z3['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      zones[2].action =
          actionOptions[((z3['action'] as int?) ?? 0).clamp(0, actionOptions.length - 1)];
    }
    if (e1 != null) {
      extOuts[0].enabled = (e1['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[0].test = (e1['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[0].countdownAction = extOutActionOptions[
          ((e1[StringConstants.countdownaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[0].holdAction = extOutActionOptions[
          ((e1[StringConstants.holdaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[0].releaseAction = extOutActionOptions[
          ((e1[StringConstants.releaseaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
    }
    if (e2 != null) {
      extOuts[1].enabled = (e2['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[1].test = (e2['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[1].countdownAction = extOutActionOptions[
          ((e2[StringConstants.countdownaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[1].holdAction = extOutActionOptions[
          ((e2[StringConstants.holdaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[1].releaseAction = extOutActionOptions[
          ((e2[StringConstants.releaseaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
    }
    if (e3 != null) {
      extOuts[2].enabled = (e3['enabled'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[2].test = (e3['test'] as bool?) ?? false ? StringConstants.yes : 'No';
      extOuts[2].countdownAction = extOutActionOptions[
          ((e3[StringConstants.countdownaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[2].holdAction = extOutActionOptions[
          ((e3[StringConstants.holdaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
      extOuts[2].releaseAction = extOutActionOptions[
          ((e3[StringConstants.releaseaction] as int?) ?? 0)
              .clamp(0, extOutActionOptions.length - 1)];
    }
    final gen = data[StringConstants.s123] as Map<String, dynamic>?;
    if (gen != null) {
      delayController.text = (gen['delay'] as int?)?.toString() ?? '0';
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

    sounderOne.enabled = manager!.isSounderOneEnabled.value ? StringConstants.yes : 'No';
    sounderOne.type =
        manager!.isSounderOneNormal.value ? StringConstants.none : StringConstants.isMTL5525;
    sounderTwo.enabled = manager!.isSounderTwoEnabled.value ? StringConstants.yes : 'No';
    sounderTwo.type =
        manager!.isSounderTwoNormal.value ? StringConstants.none : StringConstants.isMTL5525;
    sounderThree.enabled = manager!.isSounderThreeEnabled.value ? StringConstants.yes : 'No';
    sounderThree.type =
        manager!.isSounderThreeNormal.value ? StringConstants.none : StringConstants.isMTL5525;
    sounderOne.outputController.text = manager!.sounderOneOutputText.value;
    sounderTwo.outputController.text = manager!.sounderTwoOutputText.value;
    sounderThree.outputController.text = manager!.sounderThreeOutputText.value;

    sounderOne.group = groupOptions[manager!.sounderOneRelayFunctionGroup.value];
    sounderTwo.group = groupOptions[manager!.sounderTwoRelayFunctionGroup.value];
    sounderThree.group = groupOptions[manager!.sounderThreeRelayFunctionGroup.value];
    sounderOne.function =
        functionOptionsMap[sounderOne.group]![manager!.sounderOneRelayFunction.value];
    sounderTwo.function =
        functionOptionsMap[sounderTwo.group]![manager!.sounderTwoRelayFunction.value];
    sounderThree.function =
        functionOptionsMap[sounderThree.group]![manager!.sounderThreeRelayFunction.value];

    sounderTwo.dynamicController.text = manager!.sounderTwoFunctionNo.value.toString();
    sounderThree.dynamicController.text = manager!.sounderThreeFunctionNo.value.toString();

    delayController.text = manager!.sounderGeneralDelay.value.toString();

    final zoneOne = zones[0];
    final zoneTwo = zones[1];
    final zoneThree = zones[2];

    zoneOne.enabled = manager!.isZoneOneEnabled.value ? StringConstants.yes : 'No';
    zoneOne.test = manager!.isZoneOneTest.value ? StringConstants.yes : 'No';
    zoneOne.action = actionOptions[manager!.zoneOneAction.value];
    zoneTwo.enabled = manager!.isZoneTwoEnabled.value ? StringConstants.yes : 'No';
    zoneTwo.test = manager!.isZoneTwoTest.value ? StringConstants.yes : 'No';
    zoneTwo.action = actionOptions[manager!.zoneTwoAction.value];
    zoneThree.enabled = manager!.isZoneThreeEnabled.value ? StringConstants.yes : 'No';
    zoneThree.test = manager!.isZoneThreeTest.value ? StringConstants.yes : 'No';
    zoneThree.action = actionOptions[manager!.zoneThreeAction.value];

    final extOutOne = extOuts[0];
    final extOutTwo = extOuts[1];
    final extOutThree = extOuts[2];

    extOutOne.enabled = manager!.isExtOutOneEnabled.value ? StringConstants.yes : 'No';
    extOutOne.test = manager!.isExtOutOneTest.value ? StringConstants.yes : 'No';
    extOutOne.countdownAction = extOutActionOptions[manager!.extoutOneCountdownAction.value];
    extOutOne.holdAction = extOutActionOptions[manager!.extoutOneHoldAction.value];
    extOutOne.releaseAction = extOutActionOptions[manager!.extoutOneReleaseAction.value];
    extOutTwo.enabled = manager!.isExtOutTwoEnabled.value ? StringConstants.yes : 'No';
    extOutTwo.test = manager!.isExtOutTwoTest.value ? StringConstants.yes : 'No';
    extOutTwo.countdownAction = extOutActionOptions[manager!.extoutTwoCountdownAction.value];
    extOutTwo.holdAction = extOutActionOptions[manager!.extoutTwoHoldAction.value];
    extOutTwo.releaseAction = extOutActionOptions[manager!.extoutTwoReleaseAction.value];
    extOutThree.enabled = manager!.isExtOutThreeEnabled.value ? StringConstants.yes : 'No';
    extOutThree.test = manager!.isExtOutThreeTest.value ? StringConstants.yes : 'No';
    extOutThree.countdownAction =
        extOutActionOptions[manager!.extoutThreeCountdownAction.value];
    extOutThree.holdAction = extOutActionOptions[manager!.extoutThreeHoldAction.value];
    extOutThree.releaseAction = extOutActionOptions[manager!.extoutThreeReleaseAction.value];

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
      bool isNormal = sounder.type == StringConstants.none;
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
    m.sounderGeneralMode.value =
        GeneralEquipmentModeCodec.encodeHex(generalConfig);
    m.sounderGeneralDelay.value = int.tryParse(delayController.text) ?? 0;

    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      bool isEnabled = zone.enabled == StringConstants.yes;
      bool isTest = zone.test == StringConstants.yes;
      int actionIndex = returnIndex(zone.action, actionOptions);
      final zoneConfig = ZoneEquipmentModeConfig(
        zoneEnable:
            isEnabled ? ZoneEquipmentEnable.enabled : ZoneEquipmentEnable.disabled,
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
      int countdownIndex = returnIndex(extOut.countdownAction, extOutActionOptions);
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
      final String extOutHexValue =
          ExtZoneEquipmentModeCodec.encodeHex(extOutConfig);

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
