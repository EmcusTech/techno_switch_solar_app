import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/splash/controllers/splash_controller.dart';
import 'package:techno_switch_solar_app/features/splash/views/splash_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/splash/widgets/splash_content.dart';
import 'package:techno_switch_solar_app/features/splash/widgets/splash_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SplashUiDelegateMixin {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SplashController>();
    _controller.attachUi(this);
    _controller.startSplash();
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SplashController>()) {
      Get.delete<SplashController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashShell(
        child: SplashContent(),
      ),
    );
  }
}
