import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

/// Phone bottom sheets keep the curved red lip. Windows panes use a flat frame.
class PeripheralSheetChrome {
  static bool get flat => Platform.isWindows;

  static Color get lipColor =>
      flat ? ColorConstants.white : ColorConstants.primaryVariant;

  static double get lipPadding => flat ? 0 : 8;

  static BorderRadius topRadius({double phoneRadius = 50}) {
    if (flat) return BorderRadius.zero;
    return BorderRadius.vertical(top: Radius.circular(phoneRadius));
  }
}

class PeripheralSheetHeaderRow extends StatelessWidget {
  const PeripheralSheetHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (PeripheralSheetChrome.flat) {
      return const SizedBox.shrink();
    }

    final close = Padding(
      padding: const EdgeInsets.only(right: 32),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorConstants.blackMaterial.withValues(alpha: 0.06),
          ),
          child: const Icon(Icons.close, size: 20),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [SvgPicture.asset(AssetConstants.bottomsheetLogo), close],
    );
  }
}

class PeripheralSheetDragHandle extends StatelessWidget {
  const PeripheralSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    if (PeripheralSheetChrome.flat) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
