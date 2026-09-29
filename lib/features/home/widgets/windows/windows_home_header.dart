import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_controller.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class WindowsHomeHeader extends StatelessWidget {
  const WindowsHomeHeader({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
      child: Row(
        children: [
          InkWell(
            onTap: null,
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.white,
                border: Border.all(color: ColorConstants.borderGray, width: 1),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Opacity(
                            opacity: 1,
                            child: Container(
                              width: 166,
                              height: 166,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorConstants.blueLight,
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(
                        //   width: ScreenUtil().screenWidth,
                        //   child: SvgPicture.asset(
                        //     AssetConstants.background1,
                        //     height: ScreenUtil().screenHeight * 0.29,
                        //     width: ScreenUtil().screenWidth,
                        //     fit: BoxFit.fitWidth,
                        //   ),
                        // ),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Container(
                                  width: 106,
                                  height: 106,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorConstants.blueMedium,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(25),
                                    child: SvgPicture.asset(
                                      AssetConstants.zapIcon,
                                      height: 59.29,
                                      width: 51,
                                      colorFilter: const ColorFilter.mode(
                                        ColorConstants.primaryBlue,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              StringConstants.connectViaUsb,
                              style: StyleConstants.textDark16w800Style,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      StringConstants.tapToConnectDescription,
                      style: StyleConstants.textDark12w400Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      StringConstants.connectDevice,
                      style: StyleConstants.primaryBlue16w600Style,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: controller.openTapToConnectScan,
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.white,
                border: Border.all(color: ColorConstants.borderGray, width: 1),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Opacity(
                            opacity: 1,
                            child: Container(
                              width: 166,
                              height: 166,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorConstants.blueLight,
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(
                        //   width: ScreenUtil().screenWidth,
                        //   child: SvgPicture.asset(
                        //     AssetConstants.background1,
                        //     height: ScreenUtil().screenHeight * 0.29,
                        //     width: ScreenUtil().screenWidth,
                        //     fit: BoxFit.fitWidth,
                        //   ),
                        // ),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Container(
                                  width: 106,
                                  height: 106,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorConstants.blueMedium,
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
                            const SizedBox(height: 15),
                            Text(
                              StringConstants.tapToConnect,
                              style: StyleConstants.textDark16w800Style,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      StringConstants.tapToConnectDescription,
                      style: StyleConstants.textDark12w400Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      StringConstants.connectDevice,
                      style: StyleConstants.primary16w600Style,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
