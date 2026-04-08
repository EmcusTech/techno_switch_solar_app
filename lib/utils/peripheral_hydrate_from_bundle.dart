import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_bundle.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';

/// Writes [bundle] values into [BleManager] notifiers so subsequent BLE apply packets match the bundle.
void hydrateBleManagerFromBundle(BleManager m, PeripheralConfigBundle bundle) {
  _hydrateRelays(m, bundle.relays);
  _hydrateInputs(m, bundle.inputs);
  _hydrateZones(m, bundle.zones);
  _hydrateSounders(m, bundle.sounders);
  _hydrateLBus(m, bundle.lBusBuses);
  _hydrateExtOut(m, bundle.extOut);
  _hydrateServiceDue(m, bundle.serviceDue);
  _hydrateAccessCodes(m, bundle.accessCodes);
  _hydratePanelInfo(m, bundle.panelInfo);
  _hydrateGeneral(m.bleProcess, bundle.general);
}

void _hydrateRelays(BleManager m, Map<String, dynamic> r) {
  for (var i = 1; i <= 3; i++) {
    final map = r['r$i'] as Map<String, dynamic>?;
    if (map == null) continue;
    final enabled = map['enabled'] == true;
    final test = map['test'] == true;
    final hex = OutputModeCodec.encodeHex(
      OutputModeConfig(
        outputEnable: enabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: test ? OutputMode.test : OutputMode.normal,
        supervisionMode: SupervisionMode.normal,
      ),
    );
    final gi = (map['group'] as num?)?.toInt() ?? 0;
    final fi = (map['function'] as num?)?.toInt() ?? 0;
    final out = (map['outputText'] as String?) ?? '';
    final dyn = (map['dynamicText'] as String?) ?? '';
    switch (i) {
      case 1:
        m.relayOneMode.value = hex;
        m.relayOneSetupGroup.value = gi;
        m.relayOneSetupFunction.value = fi;
        m.isRelayOneSetupEnabled.value = enabled;
        m.isRelayOneSetupTest.value = test;
        m.relayOneSetupOutputText.value = out;
        m.relayOneSetupDynamicText.value = dyn;
        break;
      case 2:
        m.relayTwoMode.value = hex;
        m.relayTwoSetupGroup.value = gi;
        m.relayTwoSetupFunction.value = fi;
        m.isRelayTwoSetupEnabled.value = enabled;
        m.isRelayTwoSetupTest.value = test;
        m.relayTwoSetupOutputText.value = out;
        m.relayTwoSetupDynamicText.value = dyn;
        break;
      case 3:
        m.relayThreeMode.value = hex;
        m.relayThreeSetupGroup.value = gi;
        m.relayThreeSetupFunction.value = fi;
        m.isRelayThreeSetupEnabled.value = enabled;
        m.isRelayThreeSetupTest.value = test;
        m.relayThreeSetupOutputText.value = out;
        m.relayThreeSetupDynamicText.value = dyn;
        break;
    }
  }
}

void _hydrateInputs(BleManager m, Map<String, dynamic> data) {
  final enabled = data['enabled'] == true;
  final test = data['test'] == true;
  final inverted = data['inverted'] == true;
  final gi = (data['group'] as num?)?.toInt() ?? 0;
  final fi = (data['function'] as num?)?.toInt() ?? 0;
  final hex = InputModeCodec.encodeHex(
    InputModeConfig(
      inputEnable: InputEnable.values[enabled ? 1 : 0],
      inputMode: InputMode.values[test ? 1 : 0],
      latchMode: LatchMode.nonLatched,
      invertMode: InvertMode.values[inverted ? 1 : 0],
    ),
  );
  m.inputMode.value = hex;
  m.inputSetupGroup.value = gi;
  m.inputSetupFunction.value = fi;
  m.isInputSetupEnabled.value = enabled;
  m.isInputSetupTest.value = test;
  m.isInputSetupInverted.value = inverted;
  m.inputSetupText.value = (data['text'] as String?) ?? '';
}

void _hydrateZones(BleManager m, Map<String, dynamic> z) {
  for (var i = 1; i <= 3; i++) {
    final zm = z['z$i'] as Map<String, dynamic>?;
    if (zm == null) continue;
    switch (i) {
      case 1:
        m.isZoneOneSetupEnabled.value = zm['enabled'] == true;
        m.isZoneOneSetupTest.value = zm['test'] == true;
        m.zoneOneSetupType.value = (zm['type'] as num?)?.toInt() ?? 0;
        m.zoneOneSetupDetectionMode.value =
            (zm['detectionMode'] as num?)?.toInt() ?? 0;
        m.zoneOneSetupVerificationTime.value =
            (zm['verificationTime'] as String?) ?? '';
        m.zoneOneSetupText.value = (zm['text'] as String?) ?? '';
        break;
      case 2:
        m.isZoneTwoSetupEnabled.value = zm['enabled'] == true;
        m.isZoneTwoSetupTest.value = zm['test'] == true;
        m.zoneTwoSetupType.value = (zm['type'] as num?)?.toInt() ?? 0;
        m.zoneTwoSetupDetectionMode.value =
            (zm['detectionMode'] as num?)?.toInt() ?? 0;
        m.zoneTwoSetupVerificationTime.value =
            (zm['verificationTime'] as String?) ?? '';
        m.zoneTwoSetupText.value = (zm['text'] as String?) ?? '';
        break;
      case 3:
        m.isZoneThreeSetupEnabled.value = zm['enabled'] == true;
        m.isZoneThreeSetupTest.value = zm['test'] == true;
        m.zoneThreeSetupType.value = (zm['type'] as num?)?.toInt() ?? 0;
        m.zoneThreeSetupDetectionMode.value =
            (zm['detectionMode'] as num?)?.toInt() ?? 0;
        m.zoneThreeSetupVerificationTime.value =
            (zm['verificationTime'] as String?) ?? '';
        m.zoneThreeSetupText.value = (zm['text'] as String?) ?? '';
        break;
    }
  }
  syncZoneModeHexFromBleManager(m);
}

void _hydrateSounders(BleManager m, Map<String, dynamic> data) {
  for (var i = 1; i <= 3; i++) {
    final sm = data['s$i'] as Map<String, dynamic>?;
    if (sm == null) continue;
    final enabled = sm['enabled'] == true;
    final test = sm['test'] == true;
    final normal = sm['normal'] != false;
    final gi = (sm['group'] as num?)?.toInt() ?? 0;
    final fi = (sm['function'] as num?)?.toInt() ?? 0;
    final fn = (sm['functionNo'] as num?)?.toInt() ?? 0;
    final out = (sm['outputText'] as String?) ?? '';
    final hex = OutputModeCodec.encodeHex(
      OutputModeConfig(
        outputEnable: enabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: test ? OutputMode.test : OutputMode.normal,
        supervisionMode:
            normal ? SupervisionMode.normal : SupervisionMode.mtl5525,
      ),
    );
    switch (i) {
      case 1:
        m.sounderOneRelayOutputMode.value = hex;
        m.sounderOneRelayFunctionGroup.value = gi;
        m.sounderOneRelayFunction.value = fi;
        m.sounderOneFunctionNo.value = fn;
        m.sounderOneOutputText.value = out;
        m.isSounderOneEnabled.value = enabled;
        m.isSounderOneTest.value = test;
        m.isSounderOneNormal.value = normal;
        break;
      case 2:
        m.sounderTwoRelayOutputMode.value = hex;
        m.sounderTwoRelayFunctionGroup.value = gi;
        m.sounderTwoRelayFunction.value = fi;
        m.sounderTwoFunctionNo.value = fn;
        m.sounderTwoOutputText.value = out;
        m.isSounderTwoEnabled.value = enabled;
        m.isSounderTwoTest.value = test;
        m.isSounderTwoNormal.value = normal;
        break;
      case 3:
        m.sounderThreeRelayOutputMode.value = hex;
        m.sounderThreeRelayFunctionGroup.value = gi;
        m.sounderThreeRelayFunction.value = fi;
        m.sounderThreeFunctionNo.value = fn;
        m.sounderThreeOutputText.value = out;
        m.isSounderThreeEnabled.value = enabled;
        m.isSounderThreeTest.value = test;
        m.isSounderThreeNormal.value = normal;
        break;
    }
  }

  final g = data['general'] as Map<String, dynamic>?;
  if (g != null) {
    final gen = GeneralEquipmentModeConfig(
      equipmentEnable:
          g['enabled'] == true
              ? EquipmentEnable.enabled
              : EquipmentEnable.disabled,
      equipmentMode:
          g['test'] == true ? EquipmentMode.test : EquipmentMode.normal,
      sounderDelay:
          g['delayed'] == true ? SounderDelay.enabled : SounderDelay.disabled,
    );
    m.sounderGeneralMode.value = GeneralEquipmentModeCodec.encodeHex(gen);
    m.sounderGeneralDelay.value = (g['delay'] as num?)?.toInt() ?? 0;
    m.isSounderGeneralEnabled.value = g['enabled'] == true;
    m.isSounderGeneralTest.value = g['test'] == true;
    m.isSounderGeneralDelay.value = g['delayed'] == true;
    m.sounderGeneralAction.value = (g['action'] as num?)?.toInt() ?? 0;
  }

  for (var i = 1; i <= 3; i++) {
    final zm = data['z$i'] as Map<String, dynamic>?;
    if (zm == null) continue;
    final enabled = zm['enabled'] == true;
    final test = zm['test'] == true;
    final ai = (zm['action'] as num?)?.toInt() ?? 0;
    final zc = ZoneEquipmentModeConfig(
      zoneEnable:
          enabled ? ZoneEquipmentEnable.enabled : ZoneEquipmentEnable.disabled,
      zoneMode: test ? ZoneEquipmentMode.test : ZoneEquipmentMode.normal,
      sounderDelay: ZoneSounderDelay.disabled,
    );
    final zhex = ZoneEquipmentModeCodec.encodeHex(zc);
    switch (i) {
      case 1:
        m.sounderZoneOneMode.value = zhex;
        m.isZoneOneEnabled.value = enabled;
        m.isZoneOneTest.value = test;
        m.zoneOneAction.value = ai;
        break;
      case 2:
        m.sounderZoneTwoMode.value = zhex;
        m.isZoneTwoEnabled.value = enabled;
        m.isZoneTwoTest.value = test;
        m.zoneTwoAction.value = ai;
        break;
      case 3:
        m.sounderZoneThreeMode.value = zhex;
        m.isZoneThreeEnabled.value = enabled;
        m.isZoneThreeTest.value = test;
        m.zoneThreeAction.value = ai;
        break;
    }
  }

  for (var i = 1; i <= 3; i++) {
    final em = data['e$i'] as Map<String, dynamic>?;
    if (em == null) continue;
    final enabled = em['enabled'] == true;
    final test = em['test'] == true;
    final ci = (em['countdownAction'] as num?)?.toInt() ?? 0;
    final hi = (em['holdAction'] as num?)?.toInt() ?? 0;
    final ri = (em['releaseAction'] as num?)?.toInt() ?? 0;
    final ec = ExtZoneEquipmentModeConfig(
      zoneEnable:
          enabled
              ? ExtZoneEquipmentEnable.enabled
              : ExtZoneEquipmentEnable.disabled,
      zoneMode: test ? ExtZoneEquipmentMode.test : ExtZoneEquipmentMode.normal,
    );
    final ehex = ExtZoneEquipmentModeCodec.encodeHex(ec);
    switch (i) {
      case 1:
        m.sounderExtOutOneMode.value = ehex;
        m.isExtOutOneEnabled.value = enabled;
        m.isExtOutOneTest.value = test;
        m.extoutOneCountdownAction.value = ci;
        m.extoutOneHoldAction.value = hi;
        m.extoutOneReleaseAction.value = ri;
        break;
      case 2:
        m.sounderExtOutTwoMode.value = ehex;
        m.isExtOutTwoEnabled.value = enabled;
        m.isExtOutTwoTest.value = test;
        m.extoutTwoCountdownAction.value = ci;
        m.extoutTwoHoldAction.value = hi;
        m.extoutTwoReleaseAction.value = ri;
        break;
      case 3:
        m.sounderExtOutThreeMode.value = ehex;
        m.isExtOutThreeEnabled.value = enabled;
        m.isExtOutThreeTest.value = test;
        m.extoutThreeCountdownAction.value = ci;
        m.extoutThreeHoldAction.value = hi;
        m.extoutThreeReleaseAction.value = ri;
        break;
    }
  }
}

void _hydrateLBus(BleManager m, List<Map<String, dynamic>> buses) {
  final padded = List<Map<String, dynamic>>.from(buses);
  while (padded.length < 31) {
    padded.add(LBusSetupData().toJson());
  }
  m.lBusSetupDataList.value =
      padded.take(31).map(LBusSetupData.fromJson).toList();
}

void _hydrateExtOut(BleManager m, Map<String, dynamic> data) {
  final zoneEnable = (data['enabled'] as num?)?.toInt() ?? 0;
  final holdMode = (data['holdMode'] as num?)?.toInt() ?? 0;
  final rawReset = data['resetAllowed'];
  final bool resetAllowedBool;
  if (rawReset is bool) {
    resetAllowedBool = rawReset;
  } else if (rawReset is int) {
    resetAllowedBool = rawReset == 0;
  } else {
    resetAllowedBool = false;
  }
  final cfg = ExtZoneModeConfig(
    extZoneEnable:
        ExtZoneEnable.values[zoneEnable.clamp(
          0,
          ExtZoneEnable.values.length - 1,
        )],
    extZoneMode: ExtZoneMode.normal,
    holdMode: HoldMode.values[holdMode.clamp(0, HoldMode.values.length - 1)],
    resetAllowed: resetAllowedBool,
    flowDetectionUsed: false,
  );
  m.isExtZoneEnabled.value = zoneEnable;
  m.extZoneMode.value = ExtZoneModeCodec.encodeHex(cfg);
  m.extZoneCountdownAuto.value = (data['countdownAuto'] as num?)?.toInt() ?? 0;
  m.extZoneCountdownMan.value = (data['countdownMan'] as num?)?.toInt() ?? 0;
  m.extZoneReleaseTime.value = (data['releaseTime'] as num?)?.toInt() ?? 0;
  m.extZoneResetDelay.value = (data['resetDelay'] as num?)?.toInt() ?? 0;
  m.extZoneAction.value = (data['action'] as num?)?.toInt() ?? 0;
  m.extZoneFunction.value = (data['function'] as num?)?.toInt() ?? 0;
  m.extZoneActuatorType.value = (data['actuatorType'] as num?)?.toInt() ?? 0;
  m.isResetAllowed.value = resetAllowedBool ? 0 : 1;
  m.extZoneHoldMode.value = holdMode;
  m.extZoneText.value = (data['text'] as String?) ?? '';
  m.bleProcess.isExtOutApplyButtonActive.value = data['isSolar'] == true;
}

void _hydrateServiceDue(BleManager m, Map<String, dynamic> data) {
  m.serviceDueYear.value = (data['year'] as num?)?.toInt() ?? 0;
  m.serviceDueMonth.value = (data['month'] as num?)?.toInt() ?? 0;
  m.serviceDueDay.value = (data['day'] as num?)?.toInt() ?? 0;
  m.serviceDueHour.value = (data['hour'] as num?)?.toInt() ?? 0;
  m.serviceDueMinute.value = (data['minute'] as num?)?.toInt() ?? 0;
  m.serviceDueCompany.value = (data['company'] as String?) ?? '';
  m.serviceDueContact.value = (data['contact'] as String?) ?? '';
  m.serviceDueReminder.value = (data['reminder'] as num?)?.toInt() ?? 0;
}

void _hydrateAccessCodes(BleManager m, List<Map<String, dynamic>> codes) {
  m.accessCodeSetupDataList.value =
      codes.map(AccessCodeSetupData.fromJson).toList();
}

void _hydratePanelInfo(BleManager m, Map<String, dynamic> data) {
  m.panelInfoPanelNo.value = (data['panelId'] as num?)?.toInt() ?? 0;
  m.panelInfoPanelName.value = (data['panelName'] as String?) ?? '';
  m.panelInfoYear.value = (data['year'] as num?)?.toInt() ?? 0;
  m.panelInfoMonth.value = (data['month'] as num?)?.toInt() ?? 0;
  m.panelInfoDay.value = (data['day'] as num?)?.toInt() ?? 0;
  m.panelInfoHour.value = (data['hour'] as num?)?.toInt() ?? 0;
  m.panelInfoMinute.value = (data['minute'] as num?)?.toInt() ?? 0;
  m.panelInfoSecond.value = (data['second'] as num?)?.toInt() ?? 0;
  m.panelInfoEventReminderDelay.value = (data['delay'] as num?)?.toInt() ?? 0;
}

void _hydrateGeneral(BleProcess bp, Map<String, dynamic> data) {
  const buzzerOptions = ['Access Level 1', 'Access Level 2'];
  const sounderOptions = ['Access Level 2', 'Access Level 3'];
  const resetOptions = ['Access Level 2', 'Access Level 3'];
  const yesNo = ['No', 'Yes'];
  bp.generalModuleLvlTimeOut.value = (data['lvlTimeout'] as num?)?.toInt() ?? 0;
  bp.generalModuleSilenceBuzzerLvl.value = buzzerOptions
      .indexOf((data['silenceBuzzerLevel'] as String?) ?? buzzerOptions.first)
      .clamp(0, buzzerOptions.length - 1);
  bp.generalModuleSilenceSounderLvl.value = sounderOptions
      .indexOf(
        (data['silenceSoundersLevel'] as String?) ?? sounderOptions.first,
      )
      .clamp(0, sounderOptions.length - 1);
  bp.generalModuleResetLvl.value = resetOptions
      .indexOf((data['resetLevel'] as String?) ?? resetOptions.first)
      .clamp(0, resetOptions.length - 1);
  bp.generalModuleFaultLatching.value = yesNo
      .indexOf((data['faultLatching'] as String?) ?? yesNo.first)
      .clamp(0, yesNo.length - 1);
}
