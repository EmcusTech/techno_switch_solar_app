import 'dart:async';
import 'dart:math' as math;

import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/features/scan/widgets/windows/windows_scan_device_card.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/scan/controllers/scan_controller.dart';
import 'package:Technoswitch/features/scan/widgets/scan_animated_grid_card.dart';

class WindowsScanDeviceGrid extends StatefulWidget {
  const WindowsScanDeviceGrid({super.key, required this.controller});

  final ScanController controller;

  @override
  State<WindowsScanDeviceGrid> createState() => _WindowsScanDeviceGridState();
}

class _WindowsScanDeviceGridState extends State<WindowsScanDeviceGrid> {
  static const double _cardWidth = 120;
  static const double _cardHeight = 140;

  /// Outermost green ring sits inside the 340 radar. Cards stay past this.
  static const double _ringRadius = 150;
  static const double _edgeInset = 20;
  static const double _bottomInset = 120;

  final Map<String, Offset> _positions = {};
  Size? _layoutSize;

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

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size.width > 0 && size.height > 0) {
            _syncPositions(entries, size);
          }
          return Stack(children: _buildSlotWidgets(entries));
        },
      ),
    );
  }

  List<Widget> _buildSlotWidgets(List<_ScanGridEntry> entries) {
    final widgets = <Widget>[];

    for (final entry in entries) {
      final spot = _positions[entry.key];
      if (spot == null) continue;

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(entry.key),
          left: spot.dx,
          top: spot.dy,
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

  /// Each device keeps its place around the radar. RSSI updates do not move
  /// it. A window resize slides that place with the new center, then pulls
  /// any card that would leave the view back inside.
  void _syncPositions(List<_ScanGridEntry> entries, Size size) {
    final live = entries.map((entry) => entry.key).toSet();
    _positions.removeWhere((key, _) => !live.contains(key));
    final center = Offset(size.width / 2, size.height / 2);
    final previous = _layoutSize;
    if (previous != null && previous != size) {
      final oldCenter = Offset(previous.width / 2, previous.height / 2);
      final delta = center - oldCenter;
      for (final key in _positions.keys.toList()) {
        _positions[key] = _keepOnScreen(
          _positions[key]! + delta,
          center,
          size,
        );
      }
    }
    _layoutSize = size;
    for (final entry in entries) {
      _positions.putIfAbsent(
        entry.key,
        () => _pickSpot(entry.key, center, size),
      );
    }
  }

  double get _clearRadius =>
      _ringRadius +
      math.sqrt(_cardWidth * _cardWidth + _cardHeight * _cardHeight) / 2 +
      12;

  Offset _pickSpot(String key, Offset center, Size size) {
    final random = math.Random(key.hashCode);

    for (var attempt = 0; attempt < 36; attempt++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = _clearRadius + random.nextDouble() * 70 + attempt * 26;
      final spot = _spotAt(center, angle, radius);
      if (_fits(spot, center, size)) return spot;
    }

    final fallbackAngle = (key.hashCode.abs() % 360) * math.pi / 180;
    return _keepOnScreen(
      _spotAt(center, fallbackAngle, _clearRadius + _positions.length * 24),
      center,
      size,
    );
  }

  /// Pulls a card inside the view and back out of the radar ring.
  Offset _keepOnScreen(Offset spot, Offset center, Size size) {
    final maxX = math.max(_edgeInset, size.width - _edgeInset - _cardWidth);
    final maxY = math.max(
      _edgeInset,
      size.height - _bottomInset - _cardHeight,
    );
    var kept = Offset(
      spot.dx.clamp(_edgeInset, maxX),
      spot.dy.clamp(_edgeInset, maxY),
    );
    final rect = Rect.fromLTWH(kept.dx, kept.dy, _cardWidth, _cardHeight);
    if (!_hitsRing(rect, center)) return kept;

    var away =
        Offset(kept.dx + _cardWidth / 2, kept.dy + _cardHeight / 2) - center;
    if (away.distance < 1) away = const Offset(1, 0);
    final pushed = center + away / away.distance * _clearRadius;
    kept = Offset(pushed.dx - _cardWidth / 2, pushed.dy - _cardHeight / 2);
    return Offset(
      kept.dx.clamp(_edgeInset, maxX),
      kept.dy.clamp(_edgeInset, maxY),
    );
  }

  Offset _spotAt(Offset center, double angle, double radius) {
    return Offset(
      center.dx + math.cos(angle) * radius - _cardWidth / 2,
      center.dy + math.sin(angle) * radius - _cardHeight / 2,
    );
  }

  bool _fits(Offset spot, Offset center, Size size) {
    if (spot.dx < _edgeInset || spot.dy < _edgeInset) return false;
    if (spot.dx + _cardWidth > size.width - _edgeInset) return false;
    if (spot.dy + _cardHeight > size.height - _bottomInset) return false;
    final rect = Rect.fromLTWH(spot.dx, spot.dy, _cardWidth, _cardHeight);
    if (_hitsRing(rect, center)) return false;
    for (final taken in _positions.values) {
      final other = Rect.fromLTWH(taken.dx, taken.dy, _cardWidth, _cardHeight);
      if (rect.inflate(8).overlaps(other)) return false;
    }
    return true;
  }

  bool _hitsRing(Rect rect, Offset center) {
    final closestX = center.dx.clamp(rect.left, rect.right);
    final closestY = center.dy.clamp(rect.top, rect.bottom);
    final dx = center.dx - closestX;
    final dy = center.dy - closestY;
    return dx * dx + dy * dy < _ringRadius * _ringRadius;
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
