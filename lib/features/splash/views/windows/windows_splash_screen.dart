import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/splash/controllers/splash_controller.dart';
import 'package:Technoswitch/features/splash/views/splash_ui_delegate_mixin.dart';
import 'package:Technoswitch/features/splash/widgets/windows/windows_splash_content.dart';
import 'package:Technoswitch/features/splash/widgets/windows/windows_splash_shell.dart';

class WindowsSplashScreen extends StatefulWidget {
  const WindowsSplashScreen({super.key});

  @override
  State<WindowsSplashScreen> createState() => _WindowsSplashScreenState();
}

class _WindowsSplashScreenState extends State<WindowsSplashScreen>
    with SplashUiDelegateMixin {
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
      body: WindowsSplashShell(child: WindowsSplashContent()),
    );
  }
}
