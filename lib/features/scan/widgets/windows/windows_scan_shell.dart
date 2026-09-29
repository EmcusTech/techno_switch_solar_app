import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class WindowsScanShell extends StatelessWidget {
  const WindowsScanShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: ColorConstants.backgroundSubtle),
      child: child,
    );
  }
}
