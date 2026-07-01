/// Panel configuration dropdown / display option values.
abstract final class PanelValues {
  static const String zoneTypeNone = 'None';
  static const String zoneTypeIsMtl5561 = 'IS (MTL 5561)';

  static const String zoneModeNormal = 'Normal';
  static const String zoneModeNone = 'None';
  static const String zoneModeVerified = 'Verified';
  static const String zoneModeImmediate = 'Immediate';

  static const List<String> zoneTypeOptions = [
    zoneTypeNone,
    zoneTypeIsMtl5561,
  ];

  static const List<String> zoneModeOptions = [
    zoneModeNormal,
    zoneModeNone,
    zoneModeVerified,
    zoneModeImmediate,
  ];

  static const String sounderTypeNone = 'None';
  static const String sounderTypeIsMtl5525 = 'IS (MTL 5525)';

  static const String diagnosticAllNominal = 'All Nominal';

  static const String yesOption = 'Yes';
  static const String noOption = 'No';
}
