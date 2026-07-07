import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';

mixin SiteDetailUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SiteDetailUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
