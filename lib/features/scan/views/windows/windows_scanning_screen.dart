import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/scan/controllers/scan_controller.dart';
import 'package:Technoswitch/features/scan/models/scan_type.dart';
import 'package:Technoswitch/features/scan/views/scan_ui_delegate_mixin.dart';
import 'package:Technoswitch/features/scan/widgets/scan_shell.dart';
import 'package:Technoswitch/features/scan/widgets/scanning_radar_view.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_shell.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scanning_radar_view.dart';

class WindowsScanningScreen extends StatefulWidget {
  const WindowsScanningScreen({super.key});

  @override
  State<WindowsScanningScreen> createState() => _WindowsScanningScreenState();
}

class _WindowsScanningScreenState extends State<WindowsScanningScreen>
    with SingleTickerProviderStateMixin, ScanUiDelegateMixin {
  late final ScanController _controller;
  late final AnimationController _sweepController;
  final ValueNotifier<bool> _scanAnimationsPaused = ValueNotifier(false);

  @override
  ScanController get scanController => _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ScanController>();
    _controller.attachScanningUi(this);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _controller.setAnimationCallbacks(
      pause: () {
        _scanAnimationsPaused.value = true;
        if (_sweepController.isAnimating) {
          _sweepController.stop();
        }
      },
      resume: () {
        _scanAnimationsPaused.value = false;
        if (!_sweepController.isAnimating) {
          _sweepController.repeat();
        }
      },
    );
    _controller.startScanning(ScanType.bluetooth);
  }

  @override
  void dispose() {
    if (!_controller.transitioningToScanned) {
      _controller.detachUi(this);
    }
    if (!_controller.transitioningToScanned &&
        Get.isRegistered<ScanController>()) {
      Get.delete<ScanController>();
    }
    _scanAnimationsPaused.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScanController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: WindowsScanShell(
            child: WindowsScanningRadarView(
              controller: controller,
              sweepController: _sweepController,
              scanAnimationsPaused: _scanAnimationsPaused,
            ),
          ),
        );
      },
    );
  }
}
