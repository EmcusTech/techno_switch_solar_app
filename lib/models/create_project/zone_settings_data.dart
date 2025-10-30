class ZoneSettingsData {
  String? expandedZone;
  Map<String, String> zoneTexts;
  Map<String, String> zoneTypes;
  Map<String, String> zoneStates;
  Map<String, String> zoneTests;
  Map<String, String> zoneModes;
  Map<String, String> zoneVerificationTimes;

  ZoneSettingsData({
    this.expandedZone,
    Map<String, String>? zoneTexts,
    Map<String, String>? zoneTypes,
    Map<String, String>? zoneStates,
    Map<String, String>? zoneTests,
    Map<String, String>? zoneModes,
    Map<String, String>? zoneVerificationTimes,
  }) : zoneTexts = zoneTexts ?? {},
       zoneTypes = zoneTypes ?? {},
       zoneStates = zoneStates ?? {},
       zoneTests = zoneTests ?? {},
       zoneModes = zoneModes ?? {},
       zoneVerificationTimes = zoneVerificationTimes ?? {};

  void initializeZones(int count) {
    zoneTexts.clear();
    zoneTypes.clear();
    zoneStates.clear();
    zoneTests.clear();
    zoneModes.clear();
    zoneVerificationTimes.clear();
    expandedZone = null;

    for (int i = 1; i <= count; i++) {
      final zoneName = 'Zone $i';
      zoneTexts[zoneName] = zoneName;
      zoneTypes[zoneName] = 'Double Knock';
      zoneStates[zoneName] = 'Enable';
      zoneTests[zoneName] = 'Yes';
      zoneModes[zoneName] = 'Yes';
      zoneVerificationTimes[zoneName] = '300 Sec';
    }
  }

  void updateZoneField(String zoneName, String fieldType, String value) {
    switch (fieldType) {
      case 'zoneText':
        zoneTexts[zoneName] = value;
        break;
      case 'zoneType':
        zoneTypes[zoneName] = value;
        break;
      case 'zoneState':
        zoneStates[zoneName] = value;
        break;
      case 'zoneTest':
        zoneTests[zoneName] = value;
        break;
      case 'zoneMode':
        zoneModes[zoneName] = value;
        break;
      case 'zoneVerificationTime':
        zoneVerificationTimes[zoneName] = value;
        break;
    }
  }
}
