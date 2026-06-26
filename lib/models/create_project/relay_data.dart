import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
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
      relayTests[relayName] = StringConstants.no;
      relayStates[relayName] = StringConstants.enable;
      relayGroups[relayName] = StringConstants.groupA;
      relayFunctions[relayName] = 'Function 1A';
    }
  }

  void updateRelayField(String relayName, String fieldType, String value) {
    switch (fieldType) {
      case StringConstants.relaytext:
        relayTexts[relayName] = value;
        break;
      case StringConstants.relaytest:
        relayTests[relayName] = value;
        break;
      case StringConstants.relaystate:
        relayStates[relayName] = value;
        break;
      case StringConstants.relaygroup:
        relayGroups[relayName] = value;
        break;
      case StringConstants.relayfunction:
        relayFunctions[relayName] = value;
        break;
    }
  }
}
