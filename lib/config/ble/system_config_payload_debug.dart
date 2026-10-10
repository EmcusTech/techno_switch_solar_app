import 'dart:typed_data';

import 'package:Technoswitch/ble/ble_manager.dart';
import 'package:Technoswitch/config/ble/system_config_payload.dart';
import 'package:Technoswitch/config/structs/ble_module_cfg_def.dart';
import 'package:Technoswitch/config/structs/ext_out_cfg_def.dart';
import 'package:Technoswitch/config/structs/input_cfg_def.dart';
import 'package:Technoswitch/config/structs/panel_access_lvl_cfg_def.dart';
import 'package:Technoswitch/config/structs/panel_properties_cfg_def.dart';
import 'package:Technoswitch/config/structs/relay_cfg_def.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';
import 'package:Technoswitch/config/structs/system_config_def.dart';
import 'package:Technoswitch/config/structs/zone_cfg_def.dart';
import 'package:Technoswitch/config/system_config_limits.dart';

abstract final class SystemConfigPayloadDebug {
  static void printPushFrames(BleManager manager) {
    final config = SystemConfigPayload.fromBleProcess(manager.bleProcess);
    final bytes = config.toBytes();
    final chunks = SystemConfigPayload.pushChunks(bytes);
    print(
      'TX/RX: TRANSMIT: system-config-apply size ${SystemConfigDef.byteLength} in ${chunks.length} chunks',
    );
    for (var i = 0; i < chunks.length; i++) {
      final frame = manager.buildSystemConfigPushFrame(
        sequence: i,
        chunk: chunks[i],
        previewOnly: true,
        txCount: manager.u8TxPktCnt + 1 + i,
      );
      _printFrame('TRANSMIT', 'system-config-apply-$i', frame);
    }
    final endFrame = manager.buildSystemConfigApplyEndFrame(
      previewOnly: true,
      txCount: manager.u8TxPktCnt + 1 + chunks.length,
    );
    _printFrame('TRANSMIT', 'system-config-apply-end', endFrame);
    printSentStructs(chunks);
  }

  /// Prints each struct inside the config blob that was pushed.
  static void printSentStructs(List<Uint8List> chunks) {
    final bytes = _join(chunks);
    print('TX/RX: TRANSMIT: system-config sent structs ${bytes.length} bytes');
    var offset = 0;
    offset = _printSlice(
      bytes,
      offset,
      SystemConfigDef.storedSizeLength,
      'stored-cfg-size',
    );
    for (var i = 0; i < SystemConfigLimits.maxZoneSupport; i++) {
      offset = _printSlice(
        bytes,
        offset,
        ZoneCfgDef.byteLength,
        'zone-${i + 1}',
      );
    }
    for (var i = 0; i < SystemConfigLimits.maxInputSupport; i++) {
      offset = _printSlice(
        bytes,
        offset,
        InputCfgDef.byteLength,
        'input-${i + 1}',
      );
    }
    for (var i = 0; i < SystemConfigLimits.maxRelaySupport; i++) {
      offset = _printSlice(
        bytes,
        offset,
        RelayCfgDef.byteLength,
        'relay-${i + 1}',
      );
    }
    offset = _printSlice(bytes, offset, ExtOutCfgDef.byteLength, 'ext-out');
    for (var i = 0; i < SystemConfigLimits.maxSounderSupport; i++) {
      offset = _printSlice(
        bytes,
        offset,
        SounderCfgDef.byteLength,
        'sounder-${i + 1}',
      );
    }
    offset = _printSlice(
      bytes,
      offset,
      BleModuleCfgDef.byteLength,
      'ble-module',
    );
    offset = _printSlice(
      bytes,
      offset,
      PanelPropertiesCfgDef.byteLength,
      'panel-properties',
    );
    for (var i = 0; i < SystemConfigLimits.maxPanelAccCodeNo; i++) {
      offset = _printSlice(
        bytes,
        offset,
        PanelAccessLvlCfgDef.byteLength,
        'access-code-${i + 1}',
      );
    }
    _printSlice(bytes, offset, SystemConfigDef.crcLength, 'stored-crc');
  }

  static Uint8List _join(List<Uint8List> chunks) {
    final total = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final bytes = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  static int _printSlice(Uint8List bytes, int offset, int length, String name) {
    final end = offset + length;
    if (end > bytes.length) {
      print(
        'TX/RX: TRANSMIT: system-config $name struct: missing ${end - bytes.length} bytes at $offset',
      );
      return bytes.length;
    }
    _printFrame(
      'TRANSMIT',
      'system-config $name struct',
      bytes.sublist(offset, end),
    );
    return end;
  }

  static void printFrame(List<int> frame, String name) {
    _printFrame('TRANSMIT', name, frame);
  }

  static void _printFrame(String direction, String name, List<int> frame) {
    final hex = frame
        .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    print('TX/RX: $direction: $name packet: $hex');
  }
}
