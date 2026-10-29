import 'package:flutter/foundation.dart';
import 'package:Technoswitch/ble/ble_manager.dart';
import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';
import 'package:Technoswitch/config/ui/sounder_config_options.dart';

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

  /// Key-value dump of the three 37-byte sounder structs at frame byte 13.
  static void printStructs(List<int> frame, {required String label}) {
    if (!kDebugMode) return;
    const count = 3;
    final end =
        ConfigSetupPayload.structOffset + (SounderCfgDef.byteLength * count);
    if (frame.length < end) return;
    final bytes = Uint8List.fromList(frame);
    for (var i = 0; i < count; i++) {
      final config = SounderCfgDef.fromBytes(
        bytes,
        offset: ConfigSetupPayload.structOffset + (i * SounderCfgDef.byteLength),
      );
      debugPrint(_formatSounder(label, i + 1, config));
    }
  }

  static String _formatSounder(String label, int index, SounderCfgDef config) {
    final groupName = SounderConfigOptions.groupLabel(config.sounderGrp);
    final functionName = SounderConfigOptions.functionLabel(
      config.sounderGrp,
      config.sounderFunc,
    );
    final typeName =
        config.sounderType == 0
            ? SounderConfigOptions.typeLabel(true)
            : SounderConfigOptions.typeLabel(false);
    final lines = <String>[
      '$label sounder-$index',
      '  sounderNum: ${config.sounderNum}',
      '  sounderText: ${config.sounderText}',
      '  group: ${config.sounderGrp} $groupName',
      '  function: ${config.sounderFunc} $functionName',
      '  zone: ${config.sounderZone}',
      '  extOut: ${config.sounderExtOut}',
      '  enable: ${config.sounderEnable}',
      '  test: ${config.sounderTest}',
      '  type: ${config.sounderType} $typeName',
      '  delay: ${config.delay}',
      ..._unionLines(config),
    ];
    return lines.join('\n');
  }

  static List<String> _unionLines(SounderCfgDef config) {
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      return [
        '  union.function: ${config.unionFunction}',
        '  union.zone: ${config.unionZone}',
        '  union.enable: ${config.unionEnabled}',
        '  union.test: ${config.unionTest}',
        '  union.action: ${config.unionAction}',
      ];
    }
    if (config.sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      return [
        '  union.function: ${config.unionFunction}',
        '  union.enable: ${config.unionEnabled}',
        '  union.test: ${config.unionTest}',
        '  union.countdown: ${config.unionCountdown}',
        '  union.hold: ${config.unionHold}',
        '  union.release: ${config.unionRelease}',
      ];
    }
    return [
      '  union.function: ${config.unionFunction}',
      '  union.enable: ${config.unionEnabled}',
      '  union.test: ${config.unionTest}',
      '  union.action: ${config.unionAction}',
    ];
  }
}
