import 'dart:typed_data';

import 'package:Technoswitch/config/system_config_limits.dart';
import 'package:Technoswitch/config/structs/struct_bytes.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';

/// Mirrors firmware `st_sounder_cfg_def` (34 bytes, packed).
///
/// `st_adv` is always action, countdown, hold, release. The sounder's group
/// decides which of those bytes are live. There is no ext-out number.
class SounderCfgDef {
  const SounderCfgDef({
    this.sounderNum = 1,
    this.sounderText = SounderDefaults.outputText,
    this.sounderGrp = SounderDefaults.groupGeneralBle,
    this.sounderFunc = SounderDefaults.functionFireSndBle,
    this.sounderZone = 0,
    this.sounderEnable = SounderDefaults.enabledBle ? 1 : 0,
    this.sounderTest = SounderDefaults.testBle ? 1 : 0,
    this.sounderType = SounderDefaults.normalBle ? 0 : 1,
    this.delay = 0,
    this.advAction = 0,
    this.advCountdown = 0,
    this.advHold = 0,
    this.advRelease = 0,
  });

  static const int byteLength = 34;
  static const int sounderGroupGeneral = 1;
  static const int sounderGroupZone = 2;
  static const int sounderGroupExtOut = 3;

  final int sounderNum;
  final String sounderText;
  final int sounderGrp;
  final int sounderFunc;
  final int sounderZone;
  final int sounderEnable;
  final int sounderTest;
  final int sounderType;
  final int delay;
  final int advAction;
  final int advCountdown;
  final int advHold;
  final int advRelease;

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
      sounderEnable: bytes[offset + 25],
      sounderTest: bytes[offset + 26],
      sounderType: bytes[offset + 27],
      delay: StructBytes.readUint16Le(bytes, offset + 28),
      advAction: bytes[offset + 30],
      advCountdown: bytes[offset + 31],
      advHold: bytes[offset + 32],
      advRelease: bytes[offset + 33],
    );
  }

  factory SounderCfgDef.fromCacheMap(
    Map<String, dynamic> data, {
    required int sounderNum,
  }) {
    final defaults = SounderDefaults.mainSounderEntry(sounderNum - 1);
    final group = (data['group'] as num?)?.toInt() ?? defaults['group'] as int;
    final functionNo =
        (data['functionNo'] as num?)?.toInt() ?? defaults['functionNo'] as int;

    return SounderCfgDef(
      sounderNum: sounderNum,
      sounderText:
          (data['outputText'] as String?) ?? SounderDefaults.outputText,
      sounderGrp: group,
      sounderFunc:
          (data['function'] as num?)?.toInt() ?? defaults['function'] as int,
      sounderZone: group == sounderGroupZone ? functionNo : 0,
      sounderEnable:
          ((data['enabled'] as bool?) ?? defaults['enabled'] as bool) ? 1 : 0,
      sounderTest:
          ((data['test'] as bool?) ?? defaults['test'] as bool) ? 1 : 0,
      sounderType:
          ((data['normal'] as bool?) ?? defaults['normal'] as bool) ? 0 : 1,
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
    buf[25] = sounderEnable & 0xFF;
    buf[26] = sounderTest & 0xFF;
    buf[27] = sounderType & 0xFF;
    StructBytes.writeUint16Le(buf, 28, delay);
    buf[30] = advAction & 0xFF;
    buf[31] = advCountdown & 0xFF;
    buf[32] = advHold & 0xFF;
    buf[33] = advRelease & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'enabled': sounderEnable != 0,
      'test': sounderTest != 0,
      'normal': sounderType == 0,
      'outputText': sounderText,
      'group': sounderGrp,
      'function': sounderFunc,
      'functionNo': sounderGrp == sounderGroupZone ? sounderZone : 0,
    };
  }
}
