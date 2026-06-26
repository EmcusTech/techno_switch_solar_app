import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class GeneralSettingsData {
  String levelTimeout;
  double timerSettings;
  String faultLatching;
  String panelDateTime;
  String serviceDue;
  String serviceDueReminder;
  String eventReminder;
  String? expandedField;

  GeneralSettingsData({
    this.levelTimeout = StringConstants.s300Seconds,
    this.timerSettings = 300,
    this.faultLatching = StringConstants.yes,
    this.panelDateTime = StringConstants.s13052025103102,
    this.serviceDue = StringConstants.s13092025,
    this.serviceDueReminder = StringConstants.s13092025,
    this.eventReminder = StringConstants.s13092025,
    this.expandedField,
  });

  GeneralSettingsData copyWith({
    String? levelTimeout,
    double? timerSettings,
    String? faultLatching,
    String? panelDateTime,
    String? serviceDue,
    String? serviceDueReminder,
    String? eventReminder,
    String? expandedField,
  }) {
    return GeneralSettingsData(
      levelTimeout: levelTimeout ?? this.levelTimeout,
      timerSettings: timerSettings ?? this.timerSettings,
      faultLatching: faultLatching ?? this.faultLatching,
      panelDateTime: panelDateTime ?? this.panelDateTime,
      serviceDue: serviceDue ?? this.serviceDue,
      serviceDueReminder: serviceDueReminder ?? this.serviceDueReminder,
      eventReminder: eventReminder ?? this.eventReminder,
      expandedField: expandedField ?? this.expandedField,
    );
  }
}
