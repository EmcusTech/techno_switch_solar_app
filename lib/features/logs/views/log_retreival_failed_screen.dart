import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class LogRetrievalFailedScreen extends StatefulWidget {
  const LogRetrievalFailedScreen({super.key});

  @override
  State<LogRetrievalFailedScreen> createState() =>
      _LogRetrievalFailedScreenState();
}

class _LogRetrievalFailedScreenState extends State<LogRetrievalFailedScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pop();
                          },
                          child: SvgPicture.asset(
                            AssetConstants.arrowBackIcon,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          StringConstants.logRetrievalFailed,
                          style: StyleConstants.black20w700Style,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  _buildCompletedLogsContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedLogsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Stack(
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
        ),
      ),
    );
  }
}
