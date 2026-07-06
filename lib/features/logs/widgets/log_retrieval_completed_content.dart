import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalCompletedContent extends StatelessWidget {
  const LogRetrievalCompletedContent({
    super.key,
    required this.onBack,
    required this.onNext,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SvgPicture.asset(AssetConstants.background3),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 45),
            child: Text(
              'Retrieval\nCompleted!',
              style: StyleConstants.success24w600Style,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Lottie.asset(
          AssetConstants.firmwareUpgradeSuccessJson,
          height: 180,
          width: 180,
          repeat: false,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.buttonSecondaryBackground,
                      borderRadius: BorderRadius.circular(28.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 30,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: ColorConstants.labelText,
                          ),
                          SizedBox(width: 6),
                          Text(
                            StringConstants.back,
                            style: StyleConstants.labelText14boldStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(28.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 30,
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Row(
                        children: [
                          Text(
                            UiStrings.nextButton,
                            style: StyleConstants.white14boldStyle,
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            color: ColorConstants.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
