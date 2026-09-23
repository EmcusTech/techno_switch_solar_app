import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/config/system_config_limits.dart';

/// Debug helpers for inspecting SETUP_ACCESS_CODE 216-byte apply frames.
abstract final class PanelAccessLvlSetupPayloadDebug {
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

  static void printApplyFrame(
    BleManager manager,
    int accessCodeNo, {
    bool previewOnly = true,
  }) {
    if (!kDebugMode) return;
    final packet = manager.buildAccessCodeSetupApplyPacket(
      accessCodeNo,
      previewOnly: previewOnly,
    );
    debugPrint(
      'SETUP_ACCESS APPLY #$accessCodeNo 216-byte frame (preview):\n'
      '${formatHexDump(packet)}',
    );
  }

  static void printApplyFrames(BleManager manager) {
    if (!kDebugMode) return;
    for (var slot = 1; slot <= SystemConfigLimits.maxPanelAccCodeNo; slot++) {
      printApplyFrame(manager, slot);
    }
  }

  static void printFrame(
    List<int> packet, {
    String label = 'SETUP_ACCESS APPLY',
  }) {
    if (!kDebugMode) return;
    debugPrint('$label 216-byte frame:\n${formatHexDump(packet)}');
  }
}
