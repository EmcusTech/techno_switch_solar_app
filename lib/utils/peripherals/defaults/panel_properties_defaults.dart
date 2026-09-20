import 'package:techno_switch_solar_app/utils/peripherals/defaults/general_module_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/panel_info_defaults.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/service_due_defaults.dart';

/// Factory defaults for `st_panel_properties_def`.
abstract final class PanelPropertiesDefaults {
  static const int panelNum = PanelInfoDefaults.panelNoBle;
  static const String panelName = PanelInfoDefaults.panelNameBle;
  static const int eventReminderDelay = PanelInfoDefaults.delayBle;
  static const int remEnable = ServiceDueDefaults.reminderBle;
  static const int lvlTimeout = GeneralModuleDefaults.lvlTimeoutBle;
  static const int silenceBuzzLvl = GeneralModuleDefaults.silenceBuzzerLevelIndex;
  static const int silenceSndrLvl =
      GeneralModuleDefaults.silenceSoundersLevelIndex;
  static const int resetLvl = GeneralModuleDefaults.resetLevelIndex;
  static const int faultLatch = GeneralModuleDefaults.faultLatchingIndex;
  static const int serviceDueMonth = ServiceDueDefaults.month;
  static const int serviceDueDay = ServiceDueDefaults.day;
  static const int serviceDueYear = ServiceDueDefaults.year;
  static const int serviceDueHour = ServiceDueDefaults.hour;
  static const int serviceDueMinute = ServiceDueDefaults.minute;
  static const String companyName = ServiceDueDefaults.company;
  static const String serviceContact = ServiceDueDefaults.contact;

  static Map<String, dynamic> toCacheMap() => {
    'panelNum': panelNum,
    'panelName': panelName,
    'eventReminderDelay': eventReminderDelay,
    'remEnable': remEnable,
    'lvlTimeout': lvlTimeout,
    'silenceBuzzLvl': silenceBuzzLvl,
    'silenceSndrLvl': silenceSndrLvl,
    'resetLvl': resetLvl,
    'faultLatch': faultLatch,
    'serviceDueMonth': serviceDueMonth,
    'serviceDueDay': serviceDueDay,
    'serviceDueYear': serviceDueYear,
    'serviceDueHour': serviceDueHour,
    'serviceDueMinute': serviceDueMinute,
    'companyName': companyName,
    'serviceContact': serviceContact,
  };
}
