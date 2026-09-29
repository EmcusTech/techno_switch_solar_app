import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class WindowsSplashContent extends StatelessWidget {
  const WindowsSplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AssetConstants.fullLogo, scale: 2.5),
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
