import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';

class WindowsScanBackgroundDecor extends StatelessWidget {
  const WindowsScanBackgroundDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        AssetConstants.windowsScanBackground,
        fit: BoxFit.cover,
      ),
    );
  }
}
