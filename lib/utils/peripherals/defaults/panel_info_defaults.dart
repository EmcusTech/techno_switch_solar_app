import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for Panel Info configuration.
abstract final class PanelInfoDefaults {
  static const int panelNo = 1;
  static const String fallbackPanelName = 'TS Panel';
  static const int eventReminderDelay = 600;
  static const bool useMobileTime = true;

  static const int panelNoBle = 1;
  static const String panelNameBle = fallbackPanelName;
  static const int delayBle = 600;

  static String resolvePanelName({String? projectPanelName}) {
    final trimmed = projectPanelName?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : fallbackPanelName;
  }

  static Map<String, dynamic> toCacheMap({String? projectPanelName}) => {
    'panelId': panelNo,
    StringConstants.panelname: resolvePanelName(projectPanelName: projectPanelName),
    'delay': eventReminderDelay,
    StringConstants.usemobiletime: useMobileTime,
  };
}
