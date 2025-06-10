import 'package:flutter/material.dart';

class PanelSettingsBottomSheet extends StatelessWidget {
  final Widget childWidget;
  const PanelSettingsBottomSheet({super.key, required this.childWidget});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: IntrinsicHeight(
        child: childWidget,
      ),
    );
  }
}