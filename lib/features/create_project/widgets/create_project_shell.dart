import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class CreateProjectShell extends StatelessWidget {
  const CreateProjectShell({
    super.key,
    required this.appBar,
    required this.body,
  });

  final Widget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorConstants.scaffoldGradientTop,
            ColorConstants.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          SvgPicture.asset(AssetConstants.background1),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                appBar,
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 20),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
