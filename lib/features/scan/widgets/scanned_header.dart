import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_back_button.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScannedHeader extends StatelessWidget {
  const ScannedHeader({
    super.key,
    required this.onScanAgain,
    required this.onBack,
  });

  final VoidCallback onScanAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset(AssetConstants.background1),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: onScanAgain,
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.errorIconBackground,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          AssetConstants.logo,
                          height: 59.29,
                          width: 51,
                          colorFilter: const ColorFilter.mode(
                            ColorConstants.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                StringConstants.tapToScanAgain,
                style: StyleConstants.textDark14w400Style,
              ),
            ],
          ),
        ),
        ScanBackButton(onTap: onBack),
      ],
    );
  }
}
