import 'dart:typed_data';

import 'package:Technoswitch/config/structs/ble_module_cfg_def.dart';
import 'package:Technoswitch/config/structs/ext_out_cfg_def.dart';
import 'package:Technoswitch/config/structs/input_cfg_def.dart';
import 'package:Technoswitch/config/structs/panel_access_lvl_cfg_def.dart';
import 'package:Technoswitch/config/structs/panel_properties_cfg_def.dart';
import 'package:Technoswitch/config/structs/relay_cfg_def.dart';
import 'package:Technoswitch/config/structs/sounder_cfg_def.dart';
import 'package:Technoswitch/config/structs/struct_bytes.dart';
import 'package:Technoswitch/config/structs/zone_cfg_def.dart';
import 'package:Technoswitch/config/system_config_limits.dart';

/// Packed `st_system_config_def`.
///
/// `u16_stored_cfg_size` is the total byte length of this struct. [toBytes]
/// always writes that calculated length. `u32_stored_crc` is the CRC-16 of
/// every byte before it.
class SystemConfigDef {
  SystemConfigDef({
    required this.zones,
    required this.inputs,
    required this.relays,
    required this.extOut,
    required this.sounders,
    required this.ble,
    required this.panel,
    required this.accessLevels,
    this.storedCfgSize = byteLength,
    this.storedCrc = 0,
  }) {
    _requireLength(zones, SystemConfigLimits.maxZoneSupport, 'zones');
    _requireLength(inputs, SystemConfigLimits.maxInputSupport, 'inputs');
    _requireLength(relays, SystemConfigLimits.maxRelaySupport, 'relays');
    _requireLength(sounders, SystemConfigLimits.maxSounderSupport, 'sounders');
    _requireLength(
      accessLevels,
      SystemConfigLimits.maxPanelAccCodeNo,
      'accessLevels',
    );
  }

  static const int storedSizeLength = 2;
  static const int crcLength = 4;

  static const int byteLength =
      storedSizeLength +
      (ZoneCfgDef.byteLength * SystemConfigLimits.maxZoneSupport) +
      (InputCfgDef.byteLength * SystemConfigLimits.maxInputSupport) +
      (RelayCfgDef.byteLength * SystemConfigLimits.maxRelaySupport) +
      ExtOutCfgDef.byteLength +
      (SounderCfgDef.byteLength * SystemConfigLimits.maxSounderSupport) +
      BleModuleCfgDef.byteLength +
      PanelPropertiesCfgDef.byteLength +
      (PanelAccessLvlCfgDef.byteLength * SystemConfigLimits.maxPanelAccCodeNo) +
      crcLength;

  final int storedCfgSize;
  final List<ZoneCfgDef> zones;
  final List<InputCfgDef> inputs;
  final List<RelayCfgDef> relays;
  final ExtOutCfgDef extOut;
  final List<SounderCfgDef> sounders;
  final BleModuleCfgDef ble;
  final PanelPropertiesCfgDef panel;
  final List<PanelAccessLvlCfgDef> accessLevels;

  /// CRC-16 value read from the panel, in the low 16 bits of the uint32.
  final int storedCrc;

  factory SystemConfigDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'SystemConfigDef requires $byteLength bytes at offset $offset, got ${bytes.length - offset}',
      );
    }

    var cursor = offset;
    final storedCfgSize = StructBytes.readUint16Le(bytes, cursor);
    cursor += storedSizeLength;

    final zones = <ZoneCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxZoneSupport; i++) {
      zones.add(ZoneCfgDef.fromBytes(bytes, offset: cursor));
      cursor += ZoneCfgDef.byteLength;
    }

    final inputs = <InputCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxInputSupport; i++) {
      inputs.add(InputCfgDef.fromBytes(bytes, offset: cursor));
      cursor += InputCfgDef.byteLength;
    }

    final relays = <RelayCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxRelaySupport; i++) {
      relays.add(RelayCfgDef.fromBytes(bytes, offset: cursor));
      cursor += RelayCfgDef.byteLength;
    }

    final extOut = ExtOutCfgDef.fromBytes(bytes, offset: cursor);
    cursor += ExtOutCfgDef.byteLength;

    final sounders = <SounderCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxSounderSupport; i++) {
      sounders.add(SounderCfgDef.fromBytes(bytes, offset: cursor));
      cursor += SounderCfgDef.byteLength;
    }

    final ble = BleModuleCfgDef.fromBytes(bytes, offset: cursor);
    cursor += BleModuleCfgDef.byteLength;

    final panel = PanelPropertiesCfgDef.fromBytes(bytes, offset: cursor);
    cursor += PanelPropertiesCfgDef.byteLength;

    final accessLevels = <PanelAccessLvlCfgDef>[];
    for (var i = 0; i < SystemConfigLimits.maxPanelAccCodeNo; i++) {
      accessLevels.add(PanelAccessLvlCfgDef.fromBytes(bytes, offset: cursor));
      cursor += PanelAccessLvlCfgDef.byteLength;
    }

    final storedCrc = _readUint32Le(bytes, cursor);
    cursor += crcLength;
    if (cursor != offset + byteLength) {
      throw StateError(
        'SystemConfigDef parsed $cursor bytes, expected ${offset + byteLength}',
      );
    }

    return SystemConfigDef(
      storedCfgSize: storedCfgSize,
      zones: zones,
      inputs: inputs,
      relays: relays,
      extOut: extOut,
      sounders: sounders,
      ble: ble,
      panel: panel,
      accessLevels: accessLevels,
      storedCrc: storedCrc,
    );
  }

  /// Whole struct. The leading size is [byteLength]. [u32_stored_crc] is the
  /// CRC-16/CCITT-FALSE of every preceding byte, stored little-endian.
  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    var cursor = 0;
    StructBytes.writeUint16Le(buf, cursor, byteLength);
    cursor += storedSizeLength;

    for (final zone in zones) {
      cursor = _writeBlock(buf, cursor, zone.toBytes());
    }
    for (final input in inputs) {
      cursor = _writeBlock(buf, cursor, input.toBytes());
    }
    for (final relay in relays) {
      cursor = _writeBlock(buf, cursor, relay.toBytes());
    }
    cursor = _writeBlock(buf, cursor, extOut.toBytes());
    for (final sounder in sounders) {
      cursor = _writeBlock(buf, cursor, sounder.toBytes());
    }
    cursor = _writeBlock(buf, cursor, ble.toBytes());
    cursor = _writeBlock(buf, cursor, panel.toBytes());
    for (final access in accessLevels) {
      cursor = _writeBlock(buf, cursor, access.toBytes());
    }

    final crc = crc16Ccitt(Uint8List.sublistView(buf, 0, cursor));
    _writeUint32Le(buf, cursor, crc);
    cursor += crcLength;
    if (cursor != byteLength) {
      throw StateError(
        'SystemConfigDef wrote $cursor bytes, expected $byteLength',
      );
    }
    return buf;
  }

  /// CRC-16/CCITT-FALSE: polynomial 0x1021, init 0xFFFF, no reflection.
  static int crc16Ccitt(List<int> data) {
    const poly = 0x1021;
    const mask = 0xFFFF;
    var crc = mask;
    for (final byte in data) {
      crc ^= (byte << 8) & mask;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & mask;
        } else {
          crc = (crc << 1) & mask;
        }
      }
    }
    return crc & mask;
  }

  static int readStoredCrc(Uint8List configBytes) {
    return _readUint32Le(configBytes, byteLength - crcLength);
  }

  static bool hasMatchingCrc(Uint8List configBytes) {
    if (configBytes.length < byteLength) return false;
    final calculated = crc16Ccitt(
      Uint8List.sublistView(configBytes, 0, byteLength - crcLength),
    );
    print('calculated: $calculated');
    return calculated == (readStoredCrc(configBytes) & 0xFFFF);
  }

  static int _writeBlock(Uint8List buf, int offset, Uint8List block) {
    buf.setRange(offset, offset + block.length, block);
    return offset + block.length;
  }

  static int _readUint32Le(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static void _writeUint32Le(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }

  static void _requireLength(List<Object> values, int expected, String name) {
    if (values.length != expected) {
      throw ArgumentError('$name length ${values.length}, expected $expected');
    }
  }
}
