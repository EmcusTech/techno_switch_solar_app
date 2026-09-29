import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Technoswitch/features/home/bindings/home_screen_binding.dart';
import 'package:Technoswitch/features/home/views/home_screen.dart';
import 'package:Technoswitch/features/home/views/windows/windows_home_screen.dart';
import 'package:Technoswitch/features/splash/controllers/splash_ui_delegate.dart';

mixin SplashUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SplashUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  void openHome() {
    if (!mounted) return;
    HomeScreenBinding().dependencies();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) =>
                Platform.isWindows
                    ? const WindowsHomeScreen()
                    : const HomeScreen(),
      ),
    );
  }
}
