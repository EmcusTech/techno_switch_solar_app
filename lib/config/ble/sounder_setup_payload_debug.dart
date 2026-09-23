import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';

/// Debug helpers for inspecting SETUP_SOUNDER 216-byte apply frames.
abstract final class SounderSetupPayloadDebug {
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

  /// Builds all three apply packets without sending them (does not advance TX counter).
  static void printApplyFrames(BleManager manager) {
    if (!kDebugMode) return;
    for (final sounderNum in [1, 2, 3]) {
      final packet = manager.buildSounderSetupApplyPacket(
        sounderNum,
        previewOnly: true,
      );
      debugPrint(
        'SETUP_SOUNDER APPLY S$sounderNum 216-byte frame (preview):\n'
        '${formatHexDump(packet)}',
      );
      debugPrint(
        'SETUP_SOUNDER APPLY S$sounderNum struct bytes [13..41]: '
        '${packet.sublist(13, 42).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
    }
  }

  static void printFrame(
    List<int> packet, {
    String label = 'SETUP_SOUNDER APPLY',
  }) {
    if (!kDebugMode) return;
    debugPrint('$label 216-byte frame:\n${formatHexDump(packet)}');
  }
}
