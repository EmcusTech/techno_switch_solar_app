import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class LBusData {
  String? expandedLBus;
  Map<String, String> lbusInputs;
  Map<String, String> lbusInputTexts;
  Map<String, String> lbusProducts;
  Map<String, String> lbusGroups;
  Map<String, String> lbusFunctions;
  Map<String, String> lbusEnabled;
  Map<String, String> lbusTests;
  Map<String, String> lbusInverted;

  LBusData({
    this.expandedLBus,
    Map<String, String>? lbusInputs,
    Map<String, String>? lbusInputTexts,
    Map<String, String>? lbusProducts,
    Map<String, String>? lbusGroups,
    Map<String, String>? lbusFunctions,
    Map<String, String>? lbusEnabled,
    Map<String, String>? lbusTests,
    Map<String, String>? lbusInverted,
  }) : lbusInputs = lbusInputs ?? {StringConstants.lBUS1: '', StringConstants.lBUS2: ''},
       lbusInputTexts = lbusInputTexts ?? {StringConstants.lBUS1: '', StringConstants.lBUS2: ''},
       lbusProducts =
           lbusProducts ?? {StringConstants.lBUS1: StringConstants.onyx202, StringConstants.lBUS2: StringConstants.onyx202},
       lbusGroups = lbusGroups ?? {StringConstants.lBUS1: StringConstants.groupA, StringConstants.lBUS2: StringConstants.groupA},
       lbusFunctions =
           lbusFunctions ?? {StringConstants.lBUS1: StringConstants.functionA, StringConstants.lBUS2: StringConstants.functionA},
       lbusEnabled = lbusEnabled ?? {StringConstants.lBUS1: StringConstants.yes, StringConstants.lBUS2: StringConstants.yes},
       lbusTests = lbusTests ?? {StringConstants.lBUS1: StringConstants.no, StringConstants.lBUS2: StringConstants.no},
       lbusInverted = lbusInverted ?? {StringConstants.lBUS1: StringConstants.no, StringConstants.lBUS2: StringConstants.no};

  void updateLBusField(String lbusName, String fieldType, String value) {
    switch (fieldType) {
      case 'input':
        lbusInputs[lbusName] = value;
        break;
      case StringConstants.inputtext:
        lbusInputTexts[lbusName] = value;
        break;
      case 'product':
        lbusProducts[lbusName] = value;
        break;
      case 'group':
        lbusGroups[lbusName] = value;
        break;
      case 'function':
        lbusFunctions[lbusName] = value;
        break;
      case 'enabled':
        lbusEnabled[lbusName] = value;
        break;
      case 'test':
        lbusTests[lbusName] = value;
        break;
      case 'inverted':
        lbusInverted[lbusName] = value;
        break;
    }
  }
}

class ExtinguishingData {
  String enabled;
  String actuatorType;
  String function;
  String autoCountdown;
  String manualCountdown;
  String releaseTime;
  String resetInCount;
  String holdCount;
  String action;

  ExtinguishingData({
    this.enabled = StringConstants.yes,
    this.actuatorType = StringConstants.typeB,
    this.function = StringConstants.functionB,
    this.autoCountdown = StringConstants.s15Sec,
    this.manualCountdown = StringConstants.s30Sec,
    this.releaseTime = StringConstants.s45Sec,
    this.resetInCount = StringConstants.yes,
    this.holdCount = StringConstants.s5Sec,
    this.action = StringConstants.extinguish,
  });

  void updateField(String label, String value) {
    switch (label) {
      case StringConstants.enabled:
        enabled = value;
        break;
      case StringConstants.actuatorType:
        actuatorType = value;
        break;
      case 'Function':
        function = value;
        break;
      case StringConstants.autoCountdown:
        autoCountdown = value;
        break;
      case StringConstants.manualCountdown:
        manualCountdown = value;
        break;
      case StringConstants.releaseTime:
        releaseTime = value;
        break;
      case StringConstants.resetInCount:
        resetInCount = value;
        break;
      case StringConstants.holdCount:
        holdCount = value;
        break;
      case StringConstants.action:
        action = value;
        break;
    }
  }
}
