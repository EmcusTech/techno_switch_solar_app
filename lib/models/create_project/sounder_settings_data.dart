import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SounderSettingsData {
  final String fireSoundTone;
  final String fireSounderDelay;
  final String countDownAction;
  final String holdAction;
  final String releaseAction;
  final String extSounderDelay;

  SounderSettingsData({
    this.fireSoundTone = StringConstants.s300Seconds,
    this.fireSounderDelay = StringConstants.s300Seconds,
    this.countDownAction = StringConstants.s300Seconds,
    this.holdAction = StringConstants.s300Seconds,
    this.releaseAction = StringConstants.s300Seconds,
    this.extSounderDelay = StringConstants.s300Seconds,
  });

  SounderSettingsData copyWith({
    String? fireSoundTone,
    String? fireSounderDelay,
    String? countDownAction,
    String? holdAction,
    String? releaseAction,
    String? extSounderDelay,
  }) {
    return SounderSettingsData(
      fireSoundTone: fireSoundTone ?? this.fireSoundTone,
      fireSounderDelay: fireSounderDelay ?? this.fireSounderDelay,
      countDownAction: countDownAction ?? this.countDownAction,
      holdAction: holdAction ?? this.holdAction,
      releaseAction: releaseAction ?? this.releaseAction,
      extSounderDelay: extSounderDelay ?? this.extSounderDelay,
    );
  }
}
