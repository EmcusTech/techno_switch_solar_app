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
    this.levelTimeout = '300 Seconds',
    this.timerSettings = 300,
    this.faultLatching = 'Yes',
    this.panelDateTime = '13/05/2025 - 10:31:02',
    this.serviceDue = '13/09/2025',
    this.serviceDueReminder = '13/09/2025',
    this.eventReminder = '13/09/2025',
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
