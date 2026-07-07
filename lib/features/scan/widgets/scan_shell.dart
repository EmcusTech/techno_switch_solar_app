import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class ScanShell extends StatelessWidget {
  const ScanShell({super.key, required this.child});

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
      child: child,
    );
  }
}
