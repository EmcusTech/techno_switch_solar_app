import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:Technoswitch/bindings/initial_binding.dart';
import 'package:Technoswitch/features/splash/bindings/splash_binding.dart';
import 'package:Technoswitch/techno_switch_app.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      center: true,
      title: 'TechnoSwitch',
      size: Size(1280, 720),
      minimumSize: Size(1280, 720),
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  InitialBinding().dependencies();
  SplashBinding().dependencies();

  await InitialBinding().setAppInitials();

  runApp(const TechnoSwitchApp());
}
