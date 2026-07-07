import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/home/bindings/home_screen_binding.dart';
import 'package:techno_switch_solar_app/features/home/views/home_screen.dart';
import 'package:techno_switch_solar_app/features/splash/controllers/splash_ui_delegate.dart';

mixin SplashUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SplashUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  void openHome() {
    if (!mounted) return;
    HomeScreenBinding().dependencies();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
