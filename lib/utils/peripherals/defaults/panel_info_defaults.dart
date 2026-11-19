import 'package:Technoswitch/utils/constants/string_constants.dart';

/// Factory defaults for Panel Info configuration.
abstract final class PanelInfoDefaults {
  static const int panelNo = 1;
  static const String fallbackPanelName = '';
  static const int eventReminderDelay = 600;
  static const bool useMobileTime = true;

  static const int panelNoBle = 1;
  static const String panelNameBle = fallbackPanelName;
  static const int delayBle = 600;

  static String resolvePanelName({String? projectPanelName}) {
    return fallbackPanelName;
  }

  static Map<String, dynamic> toCacheMap({String? projectPanelName}) => {
    'panelId': panelNo,
    StringConstants.panelname: resolvePanelName(
      projectPanelName: projectPanelName,
    ),
    'delay': eventReminderDelay,
    StringConstants.usemobiletime: useMobileTime,
  };
}
