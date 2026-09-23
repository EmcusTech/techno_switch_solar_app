import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';

/// Debug helpers for inspecting SETUP_RELAY 216-byte apply frames.
abstract final class RelaySetupPayloadDebug {
  static String formatHexDump(List<int> bytes, {int bytesPerLine = 16}) {
    final lines = <String>[];
    for (var i = 0; i < bytes.length; i += bytesPerLine) {
      final end = (i + bytesPerLine).clamp(0, bytes.length);
      final chunk = bytes.sublist(i, end);
      final hex = chunk
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      lines.add('${i.toString().padLeft(3)}: $hex');
    }
    return lines.join('\n');
  }

  /// Builds all three apply packets without sending (does not advance TX counter).
  static void printApplyFrames(BleManager manager) {
    if (!kDebugMode) return;
    for (final relayNum in [1, 2, 3]) {
      final packet = manager.buildRelaySetupApplyPacket(
        relayNum,
        previewOnly: true,
      );
      debugPrint(
        'SETUP_RELAY APPLY R$relayNum 216-byte frame (preview):\n'
        '${formatHexDump(packet)}',
      );
    }
  }

  static void printFrame(
    List<int> packet, {
    String label = 'SETUP_RELAY APPLY',
  }) {
    if (!kDebugMode) return;
    debugPrint('$label 216-byte frame:\n${formatHexDump(packet)}');
  }
}
