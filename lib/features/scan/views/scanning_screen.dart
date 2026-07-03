import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/features/scan/views/scan_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';

class ScanningScreen extends GetView<ScanController> {
  const ScanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScanningPageHost(controller: controller);
  }
}

class _ScanningPageHost extends StatefulWidget {
  const _ScanningPageHost({required this.controller});

  final ScanController controller;

  @override
  State<_ScanningPageHost> createState() => _ScanningPageHostState();
}

class _ScanningPageHostState extends State<_ScanningPageHost>
    with SingleTickerProviderStateMixin, ScanUiDelegateMixin {
  @override
  ScanController get scanController => widget.controller;

  late final AnimationController _sweepController;
  final ValueNotifier<bool> _scanAnimationsPaused = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.controller.attachScanningUi(this);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    widget.controller.setAnimationCallbacks(
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
    widget.controller.startScanning(ScanType.bluetooth);
  }

  @override
  void dispose() {
    widget.controller.detachUi();
    if (!widget.controller.transitioningToScanned &&
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
      init: widget.controller,
      builder: (ctrl) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
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
            child:
                ctrl.showSelection
                    ? _buildSelectionView(ctrl)
                    : _buildScanningView(ctrl),
          ),
        );
      },
    );
  }

  Widget _buildSelectionView(ScanController ctrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            const Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset(AssetConstants.background1),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: Center(child: SvgPicture.asset(AssetConstants.logo)),
            ),
            const SizedBox(height: 40),
            Text(
              StringConstants.chooseScanType,
              style: StyleConstants.textDark24w700Style,
            ),
            const SizedBox(height: 12),
            Text(
              StringConstants.selectTheTypeOfDevicesYouWantToScanFor,
              textAlign: TextAlign.center,
              style: StyleConstants.textBodyDark14w400Style,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => ctrl.startScanning(ScanType.usb),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColorConstants.surfaceMuted),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.blackMaterial.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.usb, color: ColorConstants.primary),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(StringConstants.usbSerialDevicesTitle),
                              Text(
                                StringConstants.scanForConnectedUSBSolarDevices,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => ctrl.startScanning(ScanType.bluetooth),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColorConstants.surfaceMuted),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.blackMaterial.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth, color: Colors.blue),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(StringConstants.bluetoothBleDevicesTitle),
                              Text(
                                StringConstants
                                    .scanForNearbyBluetoothSolarDevices,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanningView(ScanController ctrl) {
    const double radarSize = 340;

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            const Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset(AssetConstants.background1),
            ),
          ],
        ),
        Align(
          alignment: Alignment.center,
          child: ScanningAnimation(pausedListenable: _scanAnimationsPaused),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: ctrl.goBackToSelection,
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
                onTap: () => ctrl.stopScanning(true),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorConstants.primary,
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
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
                    painter: _RadarPainter(sweepAnimation: _sweepController),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweepController,
                    builder:
                        (c, _) => CustomPaint(
                          painter: _SweepPainter(
                            progress: _sweepController.value,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.2,
          left: 20,
          width: radarSize,
          height: radarSize,
          child: Stack(
            children: [
              ..._buildGridSlotWidgets(ctrl, maxWidth: radarSize),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGridSlotWidgets(
    ScanController ctrl, {
    required double maxWidth,
  }) {
    const int columns = 3;
    const double spacing = 12;
    const double cardWidth = 100;
    const double cardHeight = 130;

    final widgets = <Widget>[];
    final slots = ctrl.slotToDevice.keys.toList()..sort();

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final deviceKey = ctrl.slotToDevice[slot];
      if (deviceKey == null) continue;

      final device = ctrl.discoveredDevices.cast<dynamic>().firstWhere(
        (d) => ctrl.deviceKeyByObject(d) == deviceKey,
        orElse: () => null,
      );
      if (device == null || device is! DiscoveredDevice) continue;

      final row = i ~/ columns;
      final col = i % columns;

      final left = col * (cardWidth + spacing);
      final top = row * (cardHeight + spacing);

      final justAssigned = ctrl.justAssigned.containsKey(deviceKey);

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(deviceKey),
          left: left,
          top: top,
          width: cardWidth,
          height: cardHeight,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: _AnimatedGridCard(
            highlight: justAssigned,
            child: _buildDeviceCard(ctrl, device),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDeviceCard(ScanController ctrl, DiscoveredDevice device) {
    final label = device.name;

    return GestureDetector(
      onTap:
          () => ctrl.onDeviceSelected(
            device,
            isScanningConnectFlow: true,
          ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(label),
                style: StyleConstants.textDark8boldStyle,
              ),
              SizedBox(height: 6),
              SvgPicture.asset(AssetConstants.panelIcon, width: 60, height: 60),
              SizedBox(height: 6),
              Expanded(
                child: Text(
                  BleNameUtils.getDisplayIdFromBleName(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: StyleConstants.black12boldStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> sweepAnimation;
  _RadarPainter({required this.sweepAnimation})
    : super(repaint: sweepAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final int rings = 4;
    for (int i = 1; i <= rings; i++) {
      paint.color = Colors.green.withOpacity(0.12 + i * 0.03);
      canvas.drawCircle(center, (size.width / 2) * (i / (rings + 1)), paint);
    }

    final centerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(center, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

class _SweepPainter extends CustomPainter {
  final double progress;
  _SweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.green.withOpacity(0.22),
              Colors.green.withOpacity(0.02),
              ColorConstants.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.fill;

    final angle = progress * 2 * pi;
    const double sweep = pi / 6;
    final path = Path()..moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      angle - sweep / 2,
      sweep,
      false,
    );
    path.close();

    canvas.drawPath(path, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedGridCard extends StatefulWidget {
  final Widget child;
  final bool highlight;

  const _AnimatedGridCard({required this.child, required this.highlight});

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [widget.child, if (widget.highlight) const _PulseGlow()],
        ),
      ),
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow();

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.25 * (1 - _controller.value),
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
