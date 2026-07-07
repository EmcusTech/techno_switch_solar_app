import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: Image.asset(AssetConstants.fullLogo),
          ),
          Text(
            StringConstants.panelConfigurationTool,
            style: StyleConstants.textDark22w700Style,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 2,
              width: double.infinity,
              decoration: const BoxDecoration(
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
          const SizedBox(height: 10),
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
    );
  }
}
