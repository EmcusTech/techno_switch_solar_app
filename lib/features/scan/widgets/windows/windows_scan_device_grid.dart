import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_device_card.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/scan/controllers/scan_controller.dart';
import 'package:Technoswitch/features/scan/widgets/scan_animated_grid_card.dart';

class WindowsScanDeviceGrid extends StatelessWidget {
  const WindowsScanDeviceGrid({
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
  static final double _cardWidth = 120;
  static final double _cardHeight = 140;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 120,
      width: radarSize,
      height: radarSize,
      child: Stack(children: _buildSlotWidgets()),
    );
  }

  List<Widget> _buildSlotWidgets() {
    final entries = _entriesByProximity();
    final closestRssi = _closestRssi(entries);
    final widgets = <Widget>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = i ~/ _columns;
      final col = i % _columns;

      final left = col * (_cardWidth + _spacing);
      final top = row * (_cardHeight + _spacing);

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(entry.key),
          left: left,
          top: top,
          width: _cardWidth,
          height: _cardHeight,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: ScanAnimatedGridCard(
            highlight: controller.justAssigned.containsKey(entry.key),
            child: WindowsScanDeviceCard(
              controller: controller,
              device: entry.device,
              closest: closestRssi != null && entry.device.rssi == closestRssi,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Nearest panel first. A missing RSSI of `0` stays at the end.
  List<_ScanGridEntry> _entriesByProximity() {
    final entries = <_ScanGridEntry>[];
    final slots = controller.slotToDevice.keys.toList()..sort();
    for (final slot in slots) {
      final deviceKey = controller.slotToDevice[slot];
      if (deviceKey == null) continue;
      final device = controller.deviceForKey(deviceKey);
      if (device == null) continue;
      entries.add(_ScanGridEntry(slot: slot, key: deviceKey, device: device));
    }
    entries.sort((a, b) {
      final aMissing = a.device.rssi == 0;
      final bMissing = b.device.rssi == 0;
      if (aMissing != bMissing) return aMissing ? 1 : -1;
      final byRssi = b.device.rssi.compareTo(a.device.rssi);
      if (byRssi != 0) return byRssi;
      return a.slot.compareTo(b.slot);
    });
    return entries;
  }

  int? _closestRssi(List<_ScanGridEntry> entries) {
    int? closest;
    for (final entry in entries) {
      if (entry.device.rssi == 0) continue;
      if (closest == null || entry.device.rssi > closest) {
        closest = entry.device.rssi;
      }
    }
    return closest;
  }
}

class _ScanGridEntry {
  const _ScanGridEntry({
    required this.slot,
    required this.key,
    required this.device,
  });

  final int slot;
  final String key;
  final DiscoveredDevice device;
}
