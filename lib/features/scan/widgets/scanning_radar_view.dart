import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/radar_painter.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_background_decor.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_device_grid.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/sweep_painter.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';

class ScanningRadarView extends StatelessWidget {
  const ScanningRadarView({
    super.key,
    required this.controller,
    required this.sweepController,
    required this.scanAnimationsPaused,
  });

  final ScanController controller;
  final AnimationController sweepController;
  final ValueNotifier<bool> scanAnimationsPaused;

  static const double radarSize = 340;

  @override
  Widget build(BuildContext context) {
    final gridTopOffset = MediaQuery.sizeOf(context).height * 0.2;

    return Stack(
      alignment: Alignment.center,
      children: [
        const ScanBackgroundDecor(),
        Align(
          alignment: Alignment.center,
          child: ScanningAnimation(pausedListenable: scanAnimationsPaused),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: controller.exitScanning,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.blackMaterial.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: ColorConstants.textDark,
                size: 18,
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => controller.stopScanning(true),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        StringConstants.stopScanning,
                        style: StyleConstants.white14w700Style,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              StringConstants.pleaseWaitTillScanIdentifiesTheDevices,
              style: StyleConstants.textBodyDark14w400Style,
            ),
            const SizedBox(height: 20),
          ],
        ),
        Center(
          child: SizedBox(
            width: radarSize,
            height: radarSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RadarPainter(sweepAnimation: sweepController),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: sweepController,
                    builder:
                        (c, _) => CustomPaint(
                          painter: SweepPainter(
                            progress: sweepController.value,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ScanDeviceGrid(
          controller: controller,
          topOffset: gridTopOffset,
          radarSize: radarSize,
        ),
      ],
    );
  }
}
