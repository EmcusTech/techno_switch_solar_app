import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/relay_defaults.dart';

/// Mirrors firmware `st_relay_cfg_def` (28 bytes, packed).
class RelayCfgDef {
  const RelayCfgDef({
    this.relayNum = 1,
    this.relayText = RelayDefaults.outputText,
    this.relayGrp = RelayDefaults.groupBle,
    this.relayFunc = RelayDefaults.functionBle,
    this.relayZone = 0,
    this.relayExtOut = 0,
    this.relayEnable = RelayDefaults.enabledBle ? 1 : 0,
    this.relayTest = RelayDefaults.testBle ? 1 : 0,
  });

  static const int byteLength = 28;
  static const int relayGroupZone = 2;
  static const int relayGroupExtOut = 3;

  final int relayNum;
  final String relayText;
  final int relayGrp;
  final int relayFunc;
  final int relayZone;
  final int relayExtOut;
  final int relayEnable;
  final int relayTest;

  factory RelayCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError('RelayCfgDef requires $byteLength bytes at offset $offset');
    }
    return RelayCfgDef(
      relayNum: bytes[offset],
      relayText: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.relayTextLength,
      ),
      relayGrp: bytes[offset + 22],
      relayFunc: bytes[offset + 23],
      relayZone: bytes[offset + 24],
      relayExtOut: bytes[offset + 25],
      relayEnable: bytes[offset + 26],
      relayTest: bytes[offset + 27],
    );
  }

  factory RelayCfgDef.fromCacheMap(
    Map<String, dynamic> data, {
    required int relayNum,
  }) {
    final group = (data['group'] as num?)?.toInt() ?? RelayDefaults.groupBle;
    final dynamicRaw =
        data[StringConstants.outputtext] ??
        data['dynamicText'] ??
        RelayDefaults.zoneNumberForRelay(relayNum - 1);
    final dynamicValue = int.tryParse(dynamicRaw.toString()) ?? 0;

    var relayZone = 0;
    var relayExtOut = 0;
    if (group == relayGroupZone) {
      relayZone = dynamicValue;
    } else if (group == relayGroupExtOut) {
      relayExtOut = dynamicValue;
    }

    return RelayCfgDef(
      relayNum: relayNum,
      relayText: (data['outputText'] as String?) ?? RelayDefaults.outputText,
      relayGrp: group,
      relayFunc: (data['function'] as num?)?.toInt() ?? RelayDefaults.functionBle,
      relayZone: relayZone,
      relayExtOut: relayExtOut,
      relayEnable:
          ((data['enabled'] as bool?) ?? RelayDefaults.enabledBle) ? 1 : 0,
      relayTest: ((data['test'] as bool?) ?? RelayDefaults.testBle) ? 1 : 0,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = relayNum & 0xFF;
    StructBytes.writeFixedText(
      buf,
      1,
      relayText,
      SystemConfigLimits.relayTextLength,
    );
    buf[22] = relayGrp & 0xFF;
    buf[23] = relayFunc & 0xFF;
    buf[24] = relayZone & 0xFF;
    buf[25] = relayExtOut & 0xFF;
    buf[26] = relayEnable & 0xFF;
    buf[27] = relayTest & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() {
    final dynamicValue =
        relayGrp == relayGroupZone
            ? relayZone
            : relayGrp == relayGroupExtOut
            ? relayExtOut
            : 0;

    return {
      'relayNum': relayNum,
      'outputText': relayText,
      'group': relayGrp,
      'function': relayFunc,
      StringConstants.outputtext: dynamicValue.toString(),
      'enabled': relayEnable != 0,
      'test': relayTest != 0,
    };
  }
}
