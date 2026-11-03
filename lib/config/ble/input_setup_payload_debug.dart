import 'package:flutter/foundation.dart';
import 'package:Technoswitch/ble/ble_manager.dart';

/// Debug helpers for inspecting variable-length SETUP_INPUT frames.
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
    debugPrint(
      'SETUP_INPUT APPLY frame (preview, ${packet.length} bytes):\n${formatHexDump(packet)}',
    );
    debugPrint(
      'SETUP_INPUT APPLY one-liner (${packet.length} bytes): '
      '${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
  }

  static void printFrame(
    List<int> packet, {
    String label = 'SETUP_INPUT APPLY',
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$label frame (${packet.length} bytes):\n${formatHexDump(packet)}',
    );
  }

  /// One-line log for live input setup BLE TX/RX, including packet size.
  static void logBleFrame(
    String direction,
    String packetName,
    List<int> frame,
  ) {
    print(
      'TX/RX: $direction: $packetName packet (${frame.length} bytes): '
      '${frame.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
  }
}
