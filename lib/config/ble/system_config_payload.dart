import 'dart:typed_data';

import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/config/ble/ext_out_setup_payload.dart';
import 'package:Technoswitch/config/ble/input_setup_payload.dart';
import 'package:Technoswitch/config/ble/panel_access_lvl_setup_payload.dart';
import 'package:Technoswitch/config/ble/panel_properties_setup_payload.dart';
import 'package:Technoswitch/config/ble/relay_setup_payload.dart';
import 'package:Technoswitch/config/ble/sounder_setup_payload.dart';
import 'package:Technoswitch/config/ble/zone_setup_payload.dart';
import 'package:Technoswitch/config/structs/ble_module_cfg_def.dart';
import 'package:Technoswitch/config/structs/input_cfg_def.dart';
import 'package:Technoswitch/config/structs/struct_bytes.dart';
import 'package:Technoswitch/config/structs/system_config_def.dart';
import 'package:Technoswitch/config/system_config_limits.dart';

/// Which block of the stored system-config image a partial transfer changed.
enum SystemConfigImageSection {
  zones,
  input,
  relays,
  extOut,
  sounders,
  panel,
  access,
}

/// Chunked `st_system_config_def` frames for command `0x1F`.
///
/// Pull (panel → app): info request has marker 1 at [13]. Each chunk request
/// has marker 0 at [13], sequence at [14–15], and size at [16–17]. The reply
/// carries raw config bytes at [13] with no sequence or size. A full reply
/// chunk is however many config bytes fit in the negotiated MTU.
///
/// Push (app → panel): sequence at [13–14], size at [15–16], config bytes at
/// [17]. A full push chunk is the MTU room minus those 4 bytes. The last
/// chunk of either direction is only the remainder.
abstract final class SystemConfigPayload {
  static const int commandOffset = 12;

  static const int infoRequestMarker = 1;
  static const int chunkRequestMarker = 0;

  static const int infoCountOffset = 13;
  static const int infoSizeOffset = 15;

  static const int pullMarkerOffset = 13;
  static const int pullSequenceOffset = 14;
  static const int pullSizeOffset = 16;
  static const int pullDataOffset = 13;

  static const int pushSequenceOffset = 13;
  static const int pushSizeOffset = 15;
  static const int pushDataOffset = 17;

  /// Sequence and size that sit in front of an upload slice.
  static const int pushChunkHeaderBytes = 4;

  static SystemConfigDef fromBleProcess(BleProcess process) {
    final retained = process.retainedSystemConfig;
    return SystemConfigDef(
      zones: [
        for (var i = 0; i < SystemConfigLimits.maxZoneSupport; i++)
          ZoneSetupPayload.fromBleProcess(process, i),
      ],
      inputs: [
        for (var i = 0; i < SystemConfigLimits.maxInputSupport; i++)
          i == 0
              ? InputSetupPayload.fromBleProcess(process)
              : (retained != null && i < retained.inputs.length
                  ? retained.inputs[i]
                  : const InputCfgDef()),
      ],
      relays: [
        for (var i = 0; i < SystemConfigLimits.maxRelaySupport; i++)
          RelaySetupPayload.fromBleProcess(process, i),
      ],
      extOut: ExtOutSetupPayload.fromBleProcess(process),
      sounders: [
        for (var i = 0; i < SystemConfigLimits.maxSounderSupport; i++)
          SounderSetupPayload.fromBleProcess(process, i),
      ],
      ble: retained?.ble ?? const BleModuleCfgDef(),
      panel: PanelPropertiesSetupPayload.fromBleProcess(process),
      accessLevels: [
        for (var i = 0; i < SystemConfigLimits.maxPanelAccCodeNo; i++)
          PanelAccessLvlSetupPayload.fromBleManager(process.bleManager, i),
      ],
    );
  }

  /// Writes the live bytes for [section] into a copy of [image] and recomputes
  /// the trailing CRC. Every other byte stays as it was stored.
  static Uint8List spliceLiveSection(
    Uint8List image,
    BleProcess process,
    SystemConfigImageSection section,
  ) {
    final bytes = Uint8List.fromList(
      image.sublist(0, SystemConfigDef.byteLength),
    );
    switch (section) {
      case SystemConfigImageSection.zones:
        _writeEach(
          bytes,
          SystemConfigDef.zonesOffset,
          SystemConfigLimits.maxZoneSupport,
          (index) => ZoneSetupPayload.fromBleProcess(process, index).toBytes(),
        );
      case SystemConfigImageSection.input:
        _writeBlock(
          bytes,
          SystemConfigDef.inputsOffset,
          InputSetupPayload.fromBleProcess(process).toBytes(),
        );
      case SystemConfigImageSection.relays:
        _writeEach(
          bytes,
          SystemConfigDef.relaysOffset,
          SystemConfigLimits.maxRelaySupport,
          (index) => RelaySetupPayload.fromBleProcess(process, index).toBytes(),
        );
      case SystemConfigImageSection.extOut:
        _writeBlock(
          bytes,
          SystemConfigDef.extOutOffset,
          ExtOutSetupPayload.fromBleProcess(process).toBytes(),
        );
      case SystemConfigImageSection.sounders:
        _writeEach(
          bytes,
          SystemConfigDef.soundersOffset,
          SystemConfigLimits.maxSounderSupport,
          (index) =>
              SounderSetupPayload.fromBleProcess(process, index).toBytes(),
        );
      case SystemConfigImageSection.panel:
        _writeBlock(
          bytes,
          SystemConfigDef.panelOffset,
          PanelPropertiesSetupPayload.fromBleProcess(process).toBytes(),
        );
      case SystemConfigImageSection.access:
        _writeEach(
          bytes,
          SystemConfigDef.accessOffset,
          SystemConfigLimits.maxPanelAccCodeNo,
          (index) =>
              PanelAccessLvlSetupPayload.fromBleManager(
                process.bleManager,
                index,
              ).toBytes(),
        );
    }
    return SystemConfigDef.withStoredCrc(bytes);
  }

  static void _writeEach(
    Uint8List bytes,
    int offset,
    int count,
    Uint8List Function(int index) blockAt,
  ) {
    var cursor = offset;
    for (var index = 0; index < count; index++) {
      final block = blockAt(index);
      _writeBlock(bytes, cursor, block);
      cursor += block.length;
    }
  }

  static void _writeBlock(Uint8List bytes, int offset, Uint8List block) {
    bytes.setRange(offset, offset + block.length, block);
  }

  static void applyToBleProcess(SystemConfigDef config, BleProcess process) {
    process.retainedSystemConfig = config;
    for (var i = 0; i < config.zones.length; i++) {
      ZoneSetupPayload.applyToBleProcess(config.zones[i], process, i);
    }
    if (config.inputs.isNotEmpty) {
      InputSetupPayload.applyToBleProcess(config.inputs.first, process);
    }
    for (var i = 0; i < config.relays.length; i++) {
      RelaySetupPayload.applyToBleProcess(config.relays[i], process, i);
    }
    ExtOutSetupPayload.applyToBleProcess(config.extOut, process);
    for (var i = 0; i < config.sounders.length; i++) {
      SounderSetupPayload.applyToBleProcess(config.sounders[i], process, i);
    }
    PanelPropertiesSetupPayload.applyToBleProcess(config.panel, process);
    for (var i = 0; i < config.accessLevels.length; i++) {
      PanelAccessLvlSetupPayload.applyToBleManager(
        process.bleManager,
        i,
        config.accessLevels[i],
      );
    }
  }

  /// Command data for a variable-length frame. Marker 1, no padding.
  static Uint8List infoRequestBody() {
    return Uint8List.fromList(<int>[infoRequestMarker]);
  }

  /// Command data: marker 0, sequence, size. The reply data is separate.
  static Uint8List pullChunkRequestBody({
    required int sequence,
    required int size,
  }) {
    final body = Uint8List(5);
    body[0] = chunkRequestMarker;
    StructBytes.writeUint16Le(body, 1, sequence);
    StructBytes.writeUint16Le(body, 3, size);
    return body;
  }

  /// Command data: sequence, size, then the config slice.
  static Uint8List pushChunkBody({
    required int sequence,
    required Uint8List chunk,
  }) {
    final body = Uint8List(4 + chunk.length);
    StructBytes.writeUint16Le(body, 0, sequence);
    StructBytes.writeUint16Le(body, 2, chunk.length);
    body.setRange(4, body.length, chunk);
    return body;
  }

  static void writeInfoRequest(Uint8List packet) {
    packet[infoCountOffset] = infoRequestMarker;
  }

  static void writePullChunkRequest(
    Uint8List packet, {
    required int sequence,
    required int size,
  }) {
    packet[pullMarkerOffset] = chunkRequestMarker;
    StructBytes.writeUint16Le(packet, pullSequenceOffset, sequence);
    StructBytes.writeUint16Le(packet, pullSizeOffset, size);
  }

  static void writePushChunk(
    Uint8List packet, {
    required int sequence,
    required Uint8List chunk,
  }) {
    StructBytes.writeUint16Le(packet, pushSequenceOffset, sequence);
    StructBytes.writeUint16Le(packet, pushSizeOffset, chunk.length);
    packet.setRange(pushDataOffset, pushDataOffset + chunk.length, chunk);
  }

  static ({int chunkCount, int totalSize}) readInfo(List<int> payload) {
    final bytes = Uint8List.fromList(payload);
    if (bytes.length < infoSizeOffset + 2) {
      throw RangeError(
        'System config info reply needs ${infoSizeOffset + 2} bytes, got ${bytes.length}',
      );
    }
    return (
      chunkCount: StructBytes.readUint16Le(bytes, infoCountOffset),
      totalSize: StructBytes.readUint16Le(bytes, infoSizeOffset),
    );
  }

  static Uint8List readPullChunk(List<int> payload, int size) {
    final bytes = Uint8List.fromList(payload);
    final end = pullDataOffset + size;
    if (size < 0 || bytes.length < end) {
      throw RangeError(
        'System config chunk needs $end bytes, got ${bytes.length}',
      );
    }
    return Uint8List.sublistView(bytes, pullDataOffset, end);
  }

  static int pullChunkSizeFor(
    int totalSize,
    int sequence, {
    required int chunkBytes,
  }) {
    return _chunkSize(totalSize, sequence, chunkBytes);
  }

  /// How many pulls of [chunkBytes] this app will make for [totalSize].
  static int pullStepCount(int totalSize, {required int chunkBytes}) {
    if (totalSize <= 0 || chunkBytes <= 0) return 0;
    return (totalSize + chunkBytes - 1) ~/ chunkBytes;
  }

  static List<Uint8List> pushChunks(
    Uint8List config, {
    required int chunkBytes,
  }) {
    final chunks = <Uint8List>[];
    if (chunkBytes <= 0) return chunks;
    var offset = 0;
    while (offset < config.length) {
      final size = _chunkSize(config.length, chunks.length, chunkBytes);
      chunks.add(Uint8List.sublistView(config, offset, offset + size));
      offset += size;
    }
    return chunks;
  }

  static int _chunkSize(int totalSize, int sequence, int chunkBytes) {
    final offset = sequence * chunkBytes;
    if (offset >= totalSize || totalSize <= 0) return 0;
    final remaining = totalSize - offset;
    return remaining < chunkBytes ? remaining : chunkBytes;
  }
}
