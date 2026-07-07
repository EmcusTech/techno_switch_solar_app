import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
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
        SizedBox(
          width: ScreenUtil().screenWidth,
          child: SvgPicture.asset(
            AssetConstants.background1,
            height: ScreenUtil().screenHeight * 0.29,
            width: ScreenUtil().screenWidth,
            fit: BoxFit.fitWidth,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: InkWell(
                    onTap: controller.openTapToConnectScan,
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.errorIconBackground,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
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
                StringConstants.tapToConnect,
                style: StyleConstants.textDark14w400Style,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
