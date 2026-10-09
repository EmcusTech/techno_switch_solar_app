import 'dart:typed_data';

import 'package:Technoswitch/config/system_config_limits.dart';
import 'package:Technoswitch/config/structs/struct_bytes.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';

/// Mirrors firmware `st_sounder_cfg_def` (37 bytes, packed).
///
/// The last 6 bytes are `un_sounder_group_def`. Only the member selected by
/// [sounderGrp] is live: general (4), zone (5), or ext-out (6).
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
    this.sounderType = SounderDefaults.normalBle ? 0 : 1,
    this.delay = 0,
    this.unionFunction = 0,
    this.unionZone = 0,
    this.unionEnabled = 0,
    this.unionTest = 0,
    this.unionAction = 0,
    this.unionCountdown = 0,
    this.unionHold = 0,
    this.unionRelease = 0,
  });

  static const int byteLength = 37;
  static const int sounderGroupGeneral = 1;
  static const int sounderGroupZone = 2;
  static const int sounderGroupExtOut = 3;
  static const int unionLength = 6;

  final int sounderNum;
  final String sounderText;
  final int sounderGrp;
  final int sounderFunc;
  final int sounderZone;
  final int sounderExtOut;
  final int sounderEnable;
  final int sounderTest;
  final int sounderType;
  final int delay;
  final int unionFunction;
  final int unionZone;
  final int unionEnabled;
  final int unionTest;
  final int unionAction;
  final int unionCountdown;
  final int unionHold;
  final int unionRelease;

  factory SounderCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'SounderCfgDef requires $byteLength bytes at offset $offset',
      );
    }
    final group = bytes[offset + 22];
    final union = _readUnion(bytes, offset + 31, group);
    return SounderCfgDef(
      sounderNum: bytes[offset],
      sounderText: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.sounderTextLength,
      ),
      sounderGrp: group,
      sounderFunc: bytes[offset + 23],
      sounderZone: bytes[offset + 24],
      sounderExtOut: bytes[offset + 25],
      sounderEnable: bytes[offset + 26],
      sounderTest: bytes[offset + 27],
      sounderType: bytes[offset + 28],
      delay: StructBytes.readUint16Le(bytes, offset + 29),
      unionFunction: union.function,
      unionZone: union.zone,
      unionEnabled: union.enabled,
      unionTest: union.test,
      unionAction: union.action,
      unionCountdown: union.countdown,
      unionHold: union.hold,
      unionRelease: union.release,
    );
  }

  static _SounderUnion _readUnion(Uint8List bytes, int base, int group) {
    if (group == sounderGroupZone) {
      return _SounderUnion(
        function: bytes[base],
        zone: bytes[base + 1],
        enabled: bytes[base + 2],
        test: bytes[base + 3],
        action: bytes[base + 4],
      );
    }
    if (group == sounderGroupExtOut) {
      return _SounderUnion(
        function: bytes[base],
        enabled: bytes[base + 1],
        test: bytes[base + 2],
        countdown: bytes[base + 3],
        hold: bytes[base + 4],
        release: bytes[base + 5],
      );
    }
    return _SounderUnion(
      function: bytes[base],
      enabled: bytes[base + 1],
      test: bytes[base + 2],
      action: bytes[base + 3],
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
    buf[25] = sounderExtOut & 0xFF;
    buf[26] = sounderEnable & 0xFF;
    buf[27] = sounderTest & 0xFF;
    buf[28] = sounderType & 0xFF;
    StructBytes.writeUint16Le(buf, 29, delay);
    final union = Uint8List(unionLength);
    if (sounderGrp == sounderGroupZone) {
      union[0] = unionFunction & 0xFF;
      union[1] = unionZone & 0xFF;
      union[2] = unionEnabled & 0xFF;
      union[3] = unionTest & 0xFF;
      union[4] = unionAction & 0xFF;
    } else if (sounderGrp == sounderGroupExtOut) {
      union[0] = unionFunction & 0xFF;
      union[1] = unionEnabled & 0xFF;
      union[2] = unionTest & 0xFF;
      union[3] = unionCountdown & 0xFF;
      union[4] = unionHold & 0xFF;
      union[5] = unionRelease & 0xFF;
    } else {
      union[0] = unionFunction & 0xFF;
      union[1] = unionEnabled & 0xFF;
      union[2] = unionTest & 0xFF;
      union[3] = unionAction & 0xFF;
    }
    buf.setRange(31, 37, union);
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
      'normal': sounderType == 0,
      'outputText': sounderText,
      'group': sounderGrp,
      'function': sounderFunc,
      'functionNo': functionNo,
    };
  }
}

class _SounderUnion {
  const _SounderUnion({
    this.function = 0,
    this.zone = 0,
    this.enabled = 0,
    this.test = 0,
    this.action = 0,
    this.countdown = 0,
    this.hold = 0,
    this.release = 0,
  });

  final int function;
  final int zone;
  final int enabled;
  final int test;
  final int action;
  final int countdown;
  final int hold;
  final int release;
}
