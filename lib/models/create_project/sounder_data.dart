import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class SounderData {
  String? expandedSounder;
  Map<String, String> sounderTexts;
  Map<String, String> sounderStates;
  Map<String, String> sounderTests;
  Map<String, String> sounderTypes;
  Map<String, String> sounderGroups;
  Map<String, String> sounderFunctions;

  SounderData({
    this.expandedSounder,
    Map<String, String>? sounderTexts,
    Map<String, String>? sounderStates,
    Map<String, String>? sounderTests,
    Map<String, String>? sounderTypes,
    Map<String, String>? sounderGroups,
    Map<String, String>? sounderFunctions,
  }) : sounderTexts = sounderTexts ?? {},
       sounderStates = sounderStates ?? {},
       sounderTests = sounderTests ?? {},
       sounderTypes = sounderTypes ?? {},
       sounderGroups = sounderGroups ?? {},
       sounderFunctions = sounderFunctions ?? {};

  void initializeSounders(int count, String defaultZone) {
    sounderTexts.clear();
    sounderStates.clear();
    sounderTests.clear();
    sounderTypes.clear();
    sounderGroups.clear();
    sounderFunctions.clear();
    expandedSounder = null;

    for (int i = 1; i <= count; i++) {
      final sounderName = 'Sounder $i';
      sounderTexts[sounderName] = sounderName;
      sounderStates[sounderName] = StringConstants.enable;
      sounderTests[sounderName] = StringConstants.yes;
      sounderTypes[sounderName] = StringConstants.horn;
      sounderGroups[sounderName] = defaultZone;
      sounderFunctions[sounderName] = StringConstants.p1;
    }
  }

  void updateSounderField(String sounderName, String fieldType, String value) {
    switch (fieldType) {
      case StringConstants.soundertext:
        sounderTexts[sounderName] = value;
        break;
      case StringConstants.sounderstate:
        sounderStates[sounderName] = value;
        break;
      case StringConstants.soundertest:
        sounderTests[sounderName] = value;
        break;
      case StringConstants.soundertype:
        sounderTypes[sounderName] = value;
        break;
      case StringConstants.soundergroup:
        sounderGroups[sounderName] = value;
        break;
      case StringConstants.sounderfunction:
        sounderFunctions[sounderName] = value;
        break;
    }
  }
}

class SounderSettingsData {
  String fireSoundTone;
  String fireSounderDelay;
  String countDownAction;
  String holdAction;
  String releaseAction;
  String extSounderDelay;

  SounderSettingsData({
    this.fireSoundTone = 'Pulsing 1s ON, 4s OFF',
    this.fireSounderDelay = StringConstants.s300Sec,
    this.countDownAction = 'Pulsing 1s ON, 4s OFF',
    this.holdAction = 'Pulsing 1s ON, 4s OFF',
    this.releaseAction = 'Pulsing 1s ON, 4s OFF',
    this.extSounderDelay = StringConstants.s300Sec,
  });
}
