import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:techno_switch_solar_app/features/home/views/home_screen.dart';
import 'package:techno_switch_solar_app/features/splash/controllers/splash_controller.dart';
import 'package:techno_switch_solar_app/features/splash/controllers/splash_ui_delegate.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SplashPageHost(controller: controller);
  }
}

class _SplashPageHost extends StatefulWidget {
  const _SplashPageHost({required this.controller});

  final SplashController controller;

  @override
  State<_SplashPageHost> createState() => _SplashPageHostState();
}

class _SplashPageHostState extends State<_SplashPageHost>
    implements SplashUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  void openHome() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void initState() {
    super.initState();
    widget.controller.attachUi(this);
  }

  @override
  void dispose() {
    widget.controller.detachUi();
    if (Get.isRegistered<SplashController>()) {
      Get.delete<SplashController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      AssetConstants.splashscreenBackground1,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Expanded(
                    child: SvgPicture.asset(
                      AssetConstants.splashscreenBackground2,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 32,
                    ),
                    child: Image.asset(AssetConstants.fullLogo),
                  ),
                  Text(
                    StringConstants.panelConfigurationTool,
                    style: StyleConstants.textDark22w700Style,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      height: 2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.white,
                            ColorConstants.primary,
                            ColorConstants.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    StringConstants.testingVersion,
                    style: StyleConstants.primary12w600Style,
                  ),
                  const SizedBox(height: 24),
                  LoadingAnimationWidget.waveDots(
                    color: ColorConstants.primary,
                    size: 54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
