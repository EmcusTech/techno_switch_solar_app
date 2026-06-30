import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
