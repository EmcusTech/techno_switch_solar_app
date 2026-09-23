import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/sounder_defaults.dart';

/// Mirrors firmware `st_sounder_cfg_def` (29 bytes, packed).
class SounderCfgDef {
  const SounderCfgDef({
    this.sounderNum = 1,
    this.sounderText = SounderDefaults.outputText,
    this.sounderGrp = SounderDefaults.groupGeneralBle,
    this.sounderFunc = SounderDefaults.functionFireSndBle,
    this.sounderZone = 0,
    this.sounderExtOut = 0,
    this.sounderEnable = SounderDefaults.enabledBle ? 1 : 0,
    this.sounderTest = SounderDefaults.testBle ? 1 : 0,
    this.sounderType = SounderDefaults.normalBle ? 1 : 0,
  });

  static const int byteLength = 29;
  static const int sounderGroupZone = 2;
  static const int sounderGroupExtOut = 3;

  final int sounderNum;
  final String sounderText;
  final int sounderGrp;
  final int sounderFunc;
  final int sounderZone;
  final int sounderExtOut;
  final int sounderEnable;
  final int sounderTest;
  final int sounderType;

  factory SounderCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'SounderCfgDef requires $byteLength bytes at offset $offset',
      );
    }
    return SounderCfgDef(
      sounderNum: bytes[offset],
      sounderText: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.sounderTextLength,
      ),
      sounderGrp: bytes[offset + 22],
      sounderFunc: bytes[offset + 23],
      sounderZone: bytes[offset + 24],
      sounderExtOut: bytes[offset + 25],
      sounderEnable: bytes[offset + 26],
      sounderTest: bytes[offset + 27],
      sounderType: bytes[offset + 28],
    );
  }

  factory SounderCfgDef.fromCacheMap(
    Map<String, dynamic> data, {
    required int sounderNum,
  }) {
    final defaults = SounderDefaults.mainSounderEntry(sounderNum - 1);
    final group =
        (data['group'] as num?)?.toInt() ?? defaults['group'] as int;
    final functionNo =
        (data['functionNo'] as num?)?.toInt() ??
        defaults['functionNo'] as int;

    var sounderZone = 0;
    var sounderExtOut = 0;
    if (group == sounderGroupZone) {
      sounderZone = functionNo;
    } else if (group == sounderGroupExtOut) {
      sounderExtOut = functionNo;
    }

    return SounderCfgDef(
      sounderNum: sounderNum,
      sounderText:
          (data['outputText'] as String?) ?? SounderDefaults.outputText,
      sounderGrp: group,
      sounderFunc:
          (data['function'] as num?)?.toInt() ?? defaults['function'] as int,
      sounderZone: sounderZone,
      sounderExtOut: sounderExtOut,
      sounderEnable:
          ((data['enabled'] as bool?) ?? defaults['enabled'] as bool) ? 1 : 0,
      sounderTest:
          ((data['test'] as bool?) ?? defaults['test'] as bool) ? 1 : 0,
      sounderType:
          ((data['normal'] as bool?) ?? defaults['normal'] as bool) ? 1 : 0,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = sounderNum & 0xFF;
    StructBytes.writeFixedText(
      buf,
      1,
      sounderText,
      SystemConfigLimits.sounderTextLength,
    );
    buf[22] = sounderGrp & 0xFF;
    buf[23] = sounderFunc & 0xFF;
    buf[24] = sounderZone & 0xFF;
    buf[25] = sounderExtOut & 0xFF;
    buf[26] = sounderEnable & 0xFF;
    buf[27] = sounderTest & 0xFF;
    buf[28] = sounderType & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() {
    final functionNo =
        sounderGrp == sounderGroupZone
            ? sounderZone
            : sounderGrp == sounderGroupExtOut
            ? sounderExtOut
            : 0;

    return {
      'enabled': sounderEnable != 0,
      'test': sounderTest != 0,
      'normal': sounderType != 0,
      'outputText': sounderText,
      'group': sounderGrp,
      'function': sounderFunc,
      'functionNo': functionNo,
    };
  }
}
