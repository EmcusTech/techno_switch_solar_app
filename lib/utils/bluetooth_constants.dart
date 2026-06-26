import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class BleUuids {
  static const String primaryServiceUuid =
      StringConstants.bleServiceUuid;
  static const String primaryReadCharUuid =
      StringConstants.bleNotifyUuid;
  static const String primaryWriteCharUuid =
      StringConstants.bleWriteUuid;

  static final Uuid primaryService = Uuid.parse(primaryServiceUuid);
  static final Uuid primaryReadChar = Uuid.parse(primaryReadCharUuid);
  static final Uuid primaryWriteChar = Uuid.parse(primaryWriteCharUuid);
}
