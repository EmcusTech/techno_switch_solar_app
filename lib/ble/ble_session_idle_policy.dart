import 'package:flutter/foundation.dart';

class BleSessionIdlePolicy {
  BleSessionIdlePolicy._();

  static final ValueNotifier<bool> suppressIdleDisconnect = ValueNotifier<bool>(
    false,
  );

  static final ValueNotifier<bool> suppressFirmwareDisconnectUi =
      ValueNotifier<bool>(false);
}
