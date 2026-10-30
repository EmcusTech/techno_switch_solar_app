import 'dart:async';

import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_device_card.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/scan/controllers/scan_controller.dart';
import 'package:Technoswitch/features/scan/widgets/scan_animated_grid_card.dart';

class WindowsScanDeviceGrid extends StatefulWidget {
  const WindowsScanDeviceGrid({
    super.key,
    required this.controller,
    required this.topOffset,
    required this.radarSize,
  });

  final ScanController controller;
  final double topOffset;
  final double radarSize;

  @override
  State<WindowsScanDeviceGrid> createState() => _WindowsScanDeviceGridState();
}

class _WindowsScanDeviceGridState extends State<WindowsScanDeviceGrid> {
  static const int _columns = 3;
  static const double _spacing = 12;
  static const double _cardWidth = 120;
  static const double _cardHeight = 140;

  /// A new leader must stay ahead this long before the highlight moves.
  static const Duration _switchAfter = Duration(seconds: 5);

  /// A lead of this many dBm moves the highlight immediately.
  static const int _immediateLeadDb = 8;

  String? _highlightedKey;
  String? _pendingKey;
  Timer? _pendingTimer;

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesBySlot();
    _syncHighlight(entries);

    return Positioned(
      top: widget.topOffset,
      left: 120,
      width: widget.radarSize,
      height: widget.radarSize,
      child: Stack(children: _buildSlotWidgets(entries)),
    );
  }

  List<Widget> _buildSlotWidgets(List<_ScanGridEntry> entries) {
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
            highlight: widget.controller.justAssigned.containsKey(entry.key),
            child: WindowsScanDeviceCard(
              controller: widget.controller,
              device: entry.device,
              closest: entry.key == _highlightedKey,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Discovery order. RSSI updates do not move a card to another cell.
  List<_ScanGridEntry> _entriesBySlot() {
    final entries = <_ScanGridEntry>[];
    final slots = widget.controller.slotToDevice.keys.toList()..sort();
    for (final slot in slots) {
      final deviceKey = widget.controller.slotToDevice[slot];
      if (deviceKey == null) continue;
      final device = widget.controller.deviceForKey(deviceKey);
      if (device == null) continue;
      entries.add(_ScanGridEntry(key: deviceKey, device: device));
    }
    return entries;
  }

  void _syncHighlight(List<_ScanGridEntry> entries) {
    final leader = _strongest(entries);
    if (leader == null) {
      _highlightedKey = null;
      _clearPending();
      return;
    }

    final current = _entryFor(_highlightedKey, entries);
    if (current == null) {
      _highlightedKey = leader.key;
      _clearPending();
      return;
    }
    if (leader.key == current.key) {
      _clearPending();
      return;
    }

    final lead = leader.device.rssi - current.device.rssi;
    if (current.device.rssi == 0 || lead >= _immediateLeadDb) {
      _highlightedKey = leader.key;
      _clearPending();
      return;
    }

    if (_pendingKey == leader.key) return;
    _pendingKey = leader.key;
    _pendingTimer?.cancel();
    _pendingTimer = Timer(_switchAfter, () {
      if (!mounted) return;
      setState(() {
        _highlightedKey = _pendingKey;
        _pendingKey = null;
        _pendingTimer = null;
      });
    });
  }

  _ScanGridEntry? _strongest(List<_ScanGridEntry> entries) {
    _ScanGridEntry? leader;
    for (final entry in entries) {
      if (entry.device.rssi == 0) continue;
      if (leader == null || entry.device.rssi > leader.device.rssi) {
        leader = entry;
      }
    }
    return leader;
  }

  _ScanGridEntry? _entryFor(String? key, List<_ScanGridEntry> entries) {
    if (key == null) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  void _clearPending() {
    _pendingKey = null;
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }
}

class _ScanGridEntry {
  const _ScanGridEntry({required this.key, required this.device});

  final String key;
  final DiscoveredDevice device;
}
