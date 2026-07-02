import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/bindings/initial_binding.dart';
import 'package:techno_switch_solar_app/features/splash/bindings/splash_binding.dart';
import 'package:techno_switch_solar_app/techno_switch_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  InitialBinding().dependencies();
  SplashBinding().dependencies();

  await InitialBinding().setAppInitials();

  runApp(const TechnoSwitchApp());
}
