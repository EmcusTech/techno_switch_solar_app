import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalFailedContent extends StatelessWidget {
  const LogRetrievalFailedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SvgPicture.asset(AssetConstants.background2),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 45),
            child: Text(
              'Event Log Retrieval\nFailed!',
              style: StyleConstants.primary24w600Style,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: ColorConstants.white,
                    size: 56,
                  ),
                ),
              ),
              SizedBox(height: 120),
              Text(
                UiStrings.unableToConnectToPanelMessage,
                style: StyleConstants.black14w400Style,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
