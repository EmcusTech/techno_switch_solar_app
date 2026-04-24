import 'package:flutter/foundation.dart';

/// Global policy for [BleSessionIdleTimeout].
///
/// When [suppressIdleDisconnect] is true, the idle timer does not run (e.g. during
/// the create-site wizard). [ProjectDashboardScreen] clears this so the timer
/// applies on the dashboard.
class BleSessionIdlePolicy {
  BleSessionIdlePolicy._();

  static final ValueNotifier<bool> suppressIdleDisconnect =
      ValueNotifier<bool>(false);
}
