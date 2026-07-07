import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
      zoneTypes[zoneName] = StringConstants.doubleKnock;
      zoneStates[zoneName] = StringConstants.enable;
      zoneTests[zoneName] = StringConstants.yes;
      zoneModes[zoneName] = StringConstants.yes;
      zoneVerificationTimes[zoneName] = StringConstants.s300Sec;
    }
  }

  void updateZoneField(String zoneName, String fieldType, String value) {
    switch (fieldType) {
      case StringConstants.zonetext:
        zoneTexts[zoneName] = value;
        break;
      case StringConstants.zonetype:
        zoneTypes[zoneName] = value;
        break;
      case StringConstants.zonestate:
        zoneStates[zoneName] = value;
        break;
      case StringConstants.zonetest:
        zoneTests[zoneName] = value;
        break;
      case StringConstants.zonemode:
        zoneModes[zoneName] = value;
        break;
      case StringConstants.zoneverificationtime:
        zoneVerificationTimes[zoneName] = value;
        break;
    }
  }
}
