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
      sounderStates[sounderName] = 'Enable';
      sounderTests[sounderName] = 'Yes';
      sounderTypes[sounderName] = 'Horn';
      sounderGroups[sounderName] = defaultZone;
      sounderFunctions[sounderName] = 'P1';
    }
  }

  void updateSounderField(String sounderName, String fieldType, String value) {
    switch (fieldType) {
      case 'sounderText':
        sounderTexts[sounderName] = value;
        break;
      case 'sounderState':
        sounderStates[sounderName] = value;
        break;
      case 'sounderTest':
        sounderTests[sounderName] = value;
        break;
      case 'sounderType':
        sounderTypes[sounderName] = value;
        break;
      case 'sounderGroup':
        sounderGroups[sounderName] = value;
        break;
      case 'sounderFunction':
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
    this.fireSounderDelay = '300 Sec',
    this.countDownAction = 'Pulsing 1s ON, 4s OFF',
    this.holdAction = 'Pulsing 1s ON, 4s OFF',
    this.releaseAction = 'Pulsing 1s ON, 4s OFF',
    this.extSounderDelay = '300 Sec',
  });
}
