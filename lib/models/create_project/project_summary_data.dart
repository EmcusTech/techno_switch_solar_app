import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ProjectSummaryData {
  final String enabled;
  final String actuatorType;
  final String function;
  final String autoCountdown;
  final String manualCountdown;
  final String releaseTime;
  final String resetInCount;
  final String holdCount;
  final String action;

  ProjectSummaryData({
    this.enabled = StringConstants.yes,
    this.actuatorType = StringConstants.typeA,
    this.function = StringConstants.functionA,
    this.autoCountdown = StringConstants.s10Sec,
    this.manualCountdown = StringConstants.s30Sec,
    this.releaseTime = StringConstants.s45Sec,
    this.resetInCount = StringConstants.yes,
    this.holdCount = StringConstants.s5Sec,
    this.action = StringConstants.extinguish,
  });

  ProjectSummaryData copyWith({
    String? enabled,
    String? actuatorType,
    String? function,
    String? autoCountdown,
    String? manualCountdown,
    String? releaseTime,
    String? resetInCount,
    String? holdCount,
    String? action,
  }) {
    return ProjectSummaryData(
      enabled: enabled ?? this.enabled,
      actuatorType: actuatorType ?? this.actuatorType,
      function: function ?? this.function,
      autoCountdown: autoCountdown ?? this.autoCountdown,
      manualCountdown: manualCountdown ?? this.manualCountdown,
      releaseTime: releaseTime ?? this.releaseTime,
      resetInCount: resetInCount ?? this.resetInCount,
      holdCount: holdCount ?? this.holdCount,
      action: action ?? this.action,
    );
  }
}
