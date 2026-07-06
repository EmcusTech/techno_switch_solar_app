import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_animated_grid_card.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_device_card.dart';

class ScanDeviceGrid extends StatelessWidget {
  const ScanDeviceGrid({
    super.key,
    required this.controller,
    required this.topOffset,
    required this.radarSize,
  });

  final ScanController controller;
  final double topOffset;
  final double radarSize;

  static const int _columns = 3;
  static const double _spacing = 12;
  static const double _cardWidth = 100;
  static const double _cardHeight = 130;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 20,
      width: radarSize,
      height: radarSize,
      child: Stack(
        children: _buildSlotWidgets(),
      ),
    );
  }

  List<Widget> _buildSlotWidgets() {
    final widgets = <Widget>[];
    final slots = controller.slotToDevice.keys.toList()..sort();

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final deviceKey = controller.slotToDevice[slot];
      if (deviceKey == null) continue;

      final device = controller.deviceForKey(deviceKey);
      if (device == null) continue;

      final row = i ~/ _columns;
      final col = i % _columns;

      final left = col * (_cardWidth + _spacing);
      final top = row * (_cardHeight + _spacing);

      final justAssigned = controller.justAssigned.containsKey(deviceKey);

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(deviceKey),
          left: left,
          top: top,
          width: _cardWidth,
          height: _cardHeight,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: ScanAnimatedGridCard(
            highlight: justAssigned,
            child: ScanDeviceCard(controller: controller, device: device),
          ),
        ),
      );
    }

    return widgets;
  }
}
