import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class WindowsHomeShell extends StatelessWidget {
  const WindowsHomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: ColorConstants.backgroundSubtle),
      child: child,
    );
  }
}
