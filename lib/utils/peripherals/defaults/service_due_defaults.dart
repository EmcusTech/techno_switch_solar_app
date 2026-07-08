import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for Service Due configuration.
abstract final class ServiceDueDefaults {
  static const int year = 2010;
  static const int month = 1;
  static const int day = 1;
  static const int hour = 9;
  static const int minute = 0;
  static const String company = '';
  static const String contact = '';
  static const String reminderLabel = StringConstants.off;
  static const int reminderBle = 0;

  static Map<String, dynamic> toCacheMap() => {
    'year': year,
    'month': month,
    'day': day,
    'hour': hour,
    'minute': minute,
    'company': company,
    'contact': contact,
    'reminder': reminderBle,
  };
}
