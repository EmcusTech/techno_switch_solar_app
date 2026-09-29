import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class HelpShell extends StatelessWidget {
  const HelpShell({super.key, required this.child});

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
      child: SingleChildScrollView(child: child),
    );
  }
}
