import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';

class BleUuids {
  static const String primaryServiceUuid =
      "D973F2F0-B19E-11E2-9E96-0800200C9A66";
  static const String primaryReadCharUuid =
      "D973F2F1-B19E-11E2-9E96-0800200C9A66";
  static const String primaryWriteCharUuid =
      "D973F2F2-B19E-11E2-9E96-0800200C9A66";

  static final Uuid primaryService = Uuid.parse(primaryServiceUuid);
  static final Uuid primaryReadChar = Uuid.parse(primaryReadCharUuid);
  static final Uuid primaryWriteChar = Uuid.parse(primaryWriteCharUuid);
}
