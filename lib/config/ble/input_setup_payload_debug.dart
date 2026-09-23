import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';

/// Debug helpers for inspecting SETUP_INPUT 216-byte apply frames.
abstract final class InputSetupPayloadDebug {
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

  /// Builds the next apply packet without sending it (does not advance TX counter).
  static void printApplyFrame(BleManager manager) {
    if (!kDebugMode) return;
    final packet = manager.buildInputSetupApplyPacket(previewOnly: true);
    debugPrint('SETUP_INPUT APPLY 216-byte frame (preview):\n${formatHexDump(packet)}');
    debugPrint(
      'SETUP_INPUT APPLY one-liner: '
      '${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
  }

  static void printFrame(List<int> packet, {String label = 'SETUP_INPUT APPLY'}) {
    if (!kDebugMode) return;
    debugPrint('$label 216-byte frame:\n${formatHexDump(packet)}');
  }
}
