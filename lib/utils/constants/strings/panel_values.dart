/// Panel configuration dropdown / display option values.
abstract final class PanelValues {
  static const String zoneTypeNormal = 'Normal';
  static const String zoneTypeIsMtl5561 = 'IS (MTL 5561)';

  static const String zoneModeImmediate = 'Immediate';
  static const String zoneModeNormal = 'Normal';
  static const String zoneModeVerified = 'Verified';
  static const String zoneModeConfirmed = 'Confirmed';
  /// Used outside zone mode dropdown (e.g. diagnostics); not a zone detection mode.
  static const String zoneModeNone = 'None';

  static const List<String> zoneTypeOptions = [
    zoneTypeNormal,
    zoneTypeIsMtl5561,
  ];

  static const List<String> zoneModeOptions = [
    zoneModeImmediate,
    zoneModeNormal,
    zoneModeVerified,
    zoneModeConfirmed,
  ];

  static const String sounderTypeNormal = 'Normal';
  static const String sounderTypeIsMtl5525 = 'IS (MTL 5525)';

  static const String diagnosticAllNominal = 'All Nominal';

  static const String yesOption = 'Yes';
  static const String noOption = 'No';
}
