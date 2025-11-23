import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BleUuids {
  static const String primaryServiceUuid =
      "D973F2E0-B19E-11E2-9E96-0800200C9A66";
  static const String primaryReadCharUuid =
      "D973F2E1-B19E-11E2-9E96-0800200C9A66";
  static const String primaryWriteCharUuid =
      "D973F2E2-B19E-11E2-9E96-0800200C9A66";

  static final fbp.Guid primaryService = fbp.Guid(primaryServiceUuid);
  static final fbp.Guid primaryReadChar = fbp.Guid(primaryReadCharUuid);
  static final fbp.Guid primaryWriteChar = fbp.Guid(primaryWriteCharUuid);
}
