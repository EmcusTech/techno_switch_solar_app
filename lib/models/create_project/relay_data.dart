class RelayData {
  String? expandedRelay;
  Map<String, String> relayTexts;
  Map<String, String> relayTests;
  Map<String, String> relayStates;
  Map<String, String> relayGroups;
  Map<String, String> relayFunctions;

  RelayData({
    this.expandedRelay,
    Map<String, String>? relayTexts,
    Map<String, String>? relayTests,
    Map<String, String>? relayStates,
    Map<String, String>? relayGroups,
    Map<String, String>? relayFunctions,
  }) : relayTexts = relayTexts ?? {},
       relayTests = relayTests ?? {},
       relayStates = relayStates ?? {},
       relayGroups = relayGroups ?? {},
       relayFunctions = relayFunctions ?? {};

  void initializeRelays(int count) {
    relayTexts.clear();
    relayTests.clear();
    relayStates.clear();
    relayGroups.clear();
    relayFunctions.clear();
    expandedRelay = null;

    for (int i = 1; i <= count; i++) {
      final relayName = 'Relay $i';
      relayTexts[relayName] = relayName;
      relayTests[relayName] = 'No';
      relayStates[relayName] = 'Enable';
      relayGroups[relayName] = 'Group A';
      relayFunctions[relayName] = 'Function 1A';
    }
  }

  void updateRelayField(String relayName, String fieldType, String value) {
    switch (fieldType) {
      case 'relayText':
        relayTexts[relayName] = value;
        break;
      case 'relayTest':
        relayTests[relayName] = value;
        break;
      case 'relayState':
        relayStates[relayName] = value;
        break;
      case 'relayGroup':
        relayGroups[relayName] = value;
        break;
      case 'relayFunction':
        relayFunctions[relayName] = value;
        break;
    }
  }
}
