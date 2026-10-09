import 'package:flutter/foundation.dart';
import 'package:Technoswitch/ble/ble_manager.dart';

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

  /// Builds the combined apply packet without sending it.
  static void printApplyFrames(BleManager manager) {
    if (!kDebugMode) return;
    final packet = manager.buildSounderSetupApplyPacket(previewOnly: true);
    final hex = packet
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    print('TX/RX: TRANSMIT: sounder-apply packet: $hex');
    print(
      'SETUP_SOUNDER APPLY struct bytes [13..123]: '
      '${packet.sublist(13, 124).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
  }

  static void printFrame(
    List<int> packet, {
    String label = 'SETUP_SOUNDER APPLY',
  }) {
    if (!kDebugMode) return;
    debugPrint('$label 216-byte frame:\n${formatHexDump(packet)}');
  }
}
