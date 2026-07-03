import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class TestModeScreen extends StatefulWidget {
  const TestModeScreen({super.key});

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
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
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: SvgPicture.asset(
                            AssetConstants.arrowBackIcon,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          StringConstants.testMode,
                          style: StyleConstants.black20w700Style,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  _buildTestModeContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestModeContainer() {
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
              alignment: Alignment.topRight,
              child: SvgPicture.asset(AssetConstants.background2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      StringConstants.testMode,
                      style: StyleConstants.textMuted20w600Style,
                    ),
                    Text(
                      StringConstants.configuration,
                      style: StyleConstants.textBodyDark32w700Style,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTestModeOption(
                    StringConstants.batteryTest,
                    AssetConstants.batteryTestIcon,
                    () {
                      // Handle battery test
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTestModeOption(
                    StringConstants.solarPanelTest,
                    AssetConstants.solarPanelTestIcon,
                    () {
                      // Handle solar panel test
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTestModeOption(
                    StringConstants.inverterTest,
                    AssetConstants.inverterTestIcon,
                    () {
                      // Handle inverter test
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTestModeOption(
                    StringConstants.systemTest,
                    AssetConstants.systemTestIcon,
                    () {
                      // Handle system test
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestModeOption(
    String title,
    String iconPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.borderGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      ColorConstants.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: StyleConstants.textDark16w600Style,
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: ColorConstants.textDark),
            ],
          ),
        ),
      ),
    );
  }
}
