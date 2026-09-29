import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class WindowsSplashShell extends StatelessWidget {
  const WindowsSplashShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          child,
        ],
      ),
    );
  }
}
