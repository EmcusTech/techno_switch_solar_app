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
  }) : lbusInputs = lbusInputs ?? {'L-BUS 1': '', 'L-BUS 2': ''},
       lbusInputTexts = lbusInputTexts ?? {'L-BUS 1': '', 'L-BUS 2': ''},
       lbusProducts =
           lbusProducts ?? {'L-BUS 1': 'ONYX202', 'L-BUS 2': 'ONYX202'},
       lbusGroups = lbusGroups ?? {'L-BUS 1': 'Group A', 'L-BUS 2': 'Group A'},
       lbusFunctions =
           lbusFunctions ?? {'L-BUS 1': 'Function A', 'L-BUS 2': 'Function A'},
       lbusEnabled = lbusEnabled ?? {'L-BUS 1': 'Yes', 'L-BUS 2': 'Yes'},
       lbusTests = lbusTests ?? {'L-BUS 1': 'No', 'L-BUS 2': 'No'},
       lbusInverted = lbusInverted ?? {'L-BUS 1': 'No', 'L-BUS 2': 'No'};

  void updateLBusField(String lbusName, String fieldType, String value) {
    switch (fieldType) {
      case 'input':
        lbusInputs[lbusName] = value;
        break;
      case 'inputText':
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
    this.enabled = 'Yes',
    this.actuatorType = 'Type B',
    this.function = 'Function B',
    this.autoCountdown = '15 Sec',
    this.manualCountdown = '30 Sec',
    this.releaseTime = '45 Sec',
    this.resetInCount = 'Yes',
    this.holdCount = '5 Sec',
    this.action = 'Extinguish',
  });

  void updateField(String label, String value) {
    switch (label) {
      case 'Enabled':
        enabled = value;
        break;
      case 'Actuator Type':
        actuatorType = value;
        break;
      case 'Function':
        function = value;
        break;
      case 'Auto Countdown':
        autoCountdown = value;
        break;
      case 'Manual Countdown':
        manualCountdown = value;
        break;
      case 'Release Time':
        releaseTime = value;
        break;
      case 'Reset in Count':
        resetInCount = value;
        break;
      case 'Hold / Count':
        holdCount = value;
        break;
      case 'Action':
        action = value;
        break;
    }
  }
}
