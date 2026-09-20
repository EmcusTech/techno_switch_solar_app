import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/ext_out_defaults.dart';

/// Mirrors firmware `st_ext_out_cfg_def` (11 bytes, packed).
class ExtOutCfgDef {
  const ExtOutCfgDef({
    this.extOutEnable = ExtOutDefaults.enabledBle,
    this.extOutType = ExtOutDefaults.actuatorTypeBle,
    this.extOutFunc = ExtOutDefaults.functionBle,
    this.countdownAuto = ExtOutDefaults.countdownAutoBle,
    this.countdownMan = ExtOutDefaults.countdownManBle,
    this.releaseTime = ExtOutDefaults.releaseTimeBle,
    this.resetDelay = ExtOutDefaults.resetDelayBle,
    this.resetInCount = ExtOutDefaults.resetAllowedBle,
    this.holdCount = ExtOutDefaults.holdModeBle,
    this.action = ExtOutDefaults.actionBle,
  });

  static const int byteLength = 11;

  final int extOutEnable;
  final int extOutType;
  final int extOutFunc;
  final int countdownAuto;
  final int countdownMan;
  final int releaseTime;
  final int resetDelay;
  final int resetInCount;
  final int holdCount;
  final int action;

  factory ExtOutCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError('ExtOutCfgDef requires $byteLength bytes at offset $offset');
    }
    return ExtOutCfgDef(
      extOutEnable: bytes[offset],
      extOutType: bytes[offset + 1],
      extOutFunc: bytes[offset + 2],
      countdownAuto: bytes[offset + 3],
      countdownMan: bytes[offset + 4],
      releaseTime: StructBytes.readUint16Le(bytes, offset + 5),
      resetDelay: bytes[offset + 7],
      resetInCount: bytes[offset + 8],
      holdCount: bytes[offset + 9],
      action: bytes[offset + 10],
    );
  }

  factory ExtOutCfgDef.fromCacheMap(Map<String, dynamic> data) {
    return ExtOutCfgDef(
      extOutEnable:
          (data['enabled'] as num?)?.toInt() ?? ExtOutDefaults.enabledBle,
      extOutType:
          (data[StringConstants.actuatortype] as num?)?.toInt() ??
          ExtOutDefaults.actuatorTypeBle,
      extOutFunc:
          (data['function'] as num?)?.toInt() ?? ExtOutDefaults.functionBle,
      countdownAuto:
          (data['countdownAuto'] as num?)?.toInt() ??
          ExtOutDefaults.countdownAutoBle,
      countdownMan:
          (data['countdownMan'] as num?)?.toInt() ??
          ExtOutDefaults.countdownManBle,
      releaseTime:
          (data['releaseTime'] as num?)?.toInt() ??
          ExtOutDefaults.releaseTimeBle,
      resetDelay:
          (data[StringConstants.resetdelay] as num?)?.toInt() ??
          ExtOutDefaults.resetDelayBle,
      resetInCount:
          (data[StringConstants.resetallowed] as num?)?.toInt() ??
          ExtOutDefaults.resetAllowedBle,
      holdCount:
          (data[StringConstants.holdmode] as num?)?.toInt() ??
          ExtOutDefaults.holdModeBle,
      action: (data['action'] as num?)?.toInt() ?? ExtOutDefaults.actionBle,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = extOutEnable & 0xFF;
    buf[1] = extOutType & 0xFF;
    buf[2] = extOutFunc & 0xFF;
    buf[3] = countdownAuto & 0xFF;
    buf[4] = countdownMan & 0xFF;
    StructBytes.writeUint16Le(buf, 5, releaseTime);
    buf[7] = resetDelay & 0xFF;
    buf[8] = resetInCount & 0xFF;
    buf[9] = holdCount & 0xFF;
    buf[10] = action & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    'enabled': extOutEnable,
    StringConstants.actuatortype: extOutType,
    'function': extOutFunc,
    'countdownAuto': countdownAuto,
    'countdownMan': countdownMan,
    'releaseTime': releaseTime,
    StringConstants.resetdelay: resetDelay,
    StringConstants.resetallowed: resetInCount,
    StringConstants.holdmode: holdCount,
    'action': action,
  };
}
