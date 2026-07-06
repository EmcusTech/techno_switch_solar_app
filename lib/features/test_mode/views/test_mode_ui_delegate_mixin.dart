import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_ui_delegate.dart';

mixin TestModeUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements TestModeUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
