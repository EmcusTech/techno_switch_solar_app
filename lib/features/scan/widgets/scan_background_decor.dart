import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

class ScanBackgroundDecor extends StatelessWidget {
  const ScanBackgroundDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(AssetConstants.background1),
        const Spacer(),
        Transform.rotate(
          angle: 3.14159,
          child: SvgPicture.asset(AssetConstants.background1),
        ),
      ],
    );
  }
}
