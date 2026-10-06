import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_device_grid.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/scan/controllers/scan_controller.dart';
import 'package:Technoswitch/features/scan/widgets/radar_painter.dart';
import 'package:Technoswitch/features/scan/widgets/sweep_painter.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_background_decor.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/scanning_widget.dart';

class WindowsScanningRadarView extends StatelessWidget {
  const WindowsScanningRadarView({
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
        const WindowsScanBackgroundDecor(),
        Align(
          alignment: Alignment.center,
          child: ScanningAnimation(pausedListenable: scanAnimationsPaused),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => controller.stopScanning(true),
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 40,
                    ),
                    child: Text(
                      StringConstants.stopScanning,
                      style: StyleConstants.white14w700Style,
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
        WindowsScanDeviceGrid(
          controller: controller,
          topOffset: gridTopOffset,
          radarSize: radarSize,
        ),
      ],
    );
  }
}
