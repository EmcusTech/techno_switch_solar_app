import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for L-Bus configuration (all 31 buses).
abstract final class LBusDefaults {
  static const int busCount = 31;
  static const int firstBusNumber = 1;

  static const String enabledLabel = StringConstants.no;
  static const String idLedLabel = StringConstants.no;
  static const String productLabel = 'None';
  static const String deviceText = '';
  static const int id = 0;
  static const int revision = 0;
  static const String productRev = '';
  static const String hardware = '0.0.0.0';
  static const String firmware = '0.0.0.0';
  static const String date = '';
  static const int protocol = 0;

  static Map<String, dynamic> toCacheMap() => {
    'enabled': enabledLabel,
    'idLed': idLedLabel,
    'product': productLabel,
    'deviceText': deviceText,
    'id': id,
    'revision': revision,
    'productRev': productRev,
    'hardware': hardware,
    'firmware': firmware,
    'date': date,
    'protocol': protocol,
  };
}
