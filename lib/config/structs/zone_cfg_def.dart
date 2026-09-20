import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/zone_defaults.dart';

/// Mirrors firmware `st_zone_cfg_def` (27 bytes, packed).
class ZoneCfgDef {
  const ZoneCfgDef({
    this.zoneNum = 1,
    this.zoneText = ZoneDefaults.text,
    this.zoneType = ZoneDefaults.typeBle,
    this.zoneEnable = ZoneDefaults.enabledBle ? 1 : 0,
    this.zoneTest = ZoneDefaults.testBle ? 1 : 0,
    this.zoneMode = ZoneDefaults.detectionModeBle,
    this.verifyTime = 0,
  });

  static const int byteLength = 27;

  final int zoneNum;
  final String zoneText;
  final int zoneType;
  final int zoneEnable;
  final int zoneTest;
  final int zoneMode;
  final int verifyTime;

  factory ZoneCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError('ZoneCfgDef requires $byteLength bytes at offset $offset');
    }
    return ZoneCfgDef(
      zoneNum: bytes[offset],
      zoneText: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.zoneTextLength,
      ),
      zoneType: bytes[offset + 22],
      zoneEnable: bytes[offset + 23],
      zoneTest: bytes[offset + 24],
      zoneMode: bytes[offset + 25],
      verifyTime: bytes[offset + 26],
    );
  }

  factory ZoneCfgDef.fromCacheMap(
    Map<String, dynamic> data, {
    required int zoneNum,
  }) {
    final verifyRaw = data['verificationTime'];
    final verifyTime =
        verifyRaw is num
            ? verifyRaw.toInt()
            : int.tryParse(verifyRaw?.toString() ?? '') ??
                int.tryParse(ZoneDefaults.verificationTime) ??
                0;

    return ZoneCfgDef(
      zoneNum: zoneNum,
      zoneText: (data['text'] as String?) ?? ZoneDefaults.text,
      zoneType: (data['type'] as num?)?.toInt() ?? ZoneDefaults.typeBle,
      zoneEnable:
          ((data['enabled'] as bool?) ?? ZoneDefaults.enabledBle) ? 1 : 0,
      zoneTest: ((data['test'] as bool?) ?? ZoneDefaults.testBle) ? 1 : 0,
      zoneMode:
          (data['detectionMode'] as num?)?.toInt() ??
          ZoneDefaults.detectionModeBle,
      verifyTime: verifyTime,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = zoneNum & 0xFF;
    StructBytes.writeFixedText(
      buf,
      1,
      zoneText,
      SystemConfigLimits.zoneTextLength,
    );
    buf[22] = zoneType & 0xFF;
    buf[23] = zoneEnable & 0xFF;
    buf[24] = zoneTest & 0xFF;
    buf[25] = zoneMode & 0xFF;
    buf[26] = verifyTime & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    'zoneNum': zoneNum,
    'text': zoneText,
    'type': zoneType,
    'enabled': zoneEnable != 0,
    'test': zoneTest != 0,
    'detectionMode': zoneMode,
    'verificationTime': verifyTime.toString(),
  };
}
