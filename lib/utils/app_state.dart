// app_state.dart
import 'package:flutter/foundation.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final ValueNotifier<String> connectedDeviceId = ValueNotifier<String>("");
}
