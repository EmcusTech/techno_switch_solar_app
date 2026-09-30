import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';

class WindowsScanBackgroundDecor extends StatelessWidget {
  const WindowsScanBackgroundDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ColorConstants.cardBorder),
        ),
        child: Image.asset(
          AssetConstants.windowsScanBackground,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
