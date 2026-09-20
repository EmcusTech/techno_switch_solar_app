import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Mirrors firmware `st_panel_access_lvl_def` (31 bytes, packed).
class PanelAccessLvlCfgDef {
  const PanelAccessLvlCfgDef({
    this.accessCodeNo = 1,
    this.accessLevel = 0,
    this.accessLevelName = StringConstants.notUsed,
    this.accessCode = '',
  });

  static const int byteLength = 31;

  final int accessCodeNo;
  final int accessLevel;
  final String accessLevelName;
  final String accessCode;

  factory PanelAccessLvlCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'PanelAccessLvlCfgDef requires $byteLength bytes at offset $offset',
      );
    }
    return PanelAccessLvlCfgDef(
      accessCodeNo: bytes[offset],
      accessLevel: bytes[offset + 1],
      accessLevelName: StructBytes.readFixedText(
        bytes,
        offset + 2,
        SystemConfigLimits.panelAccLvlNameLength,
      ),
      accessCode: StructBytes.readFixedText(
        bytes,
        offset + 23,
        SystemConfigLimits.panelAccCodeLength,
      ),
    );
  }

  factory PanelAccessLvlCfgDef.fromCacheMap(Map<String, dynamic> data) {
    return PanelAccessLvlCfgDef(
      accessCodeNo:
          (data[StringConstants.accesscodeno] as num?)?.toInt() ??
          (data['accessCodeNo'] as num?)?.toInt() ??
          1,
      accessLevel: (data['accessLevel'] as num?)?.toInt() ?? 0,
      accessLevelName:
          (data[StringConstants.accesslevelname] as String?) ??
          (data['accessLevelName'] as String?) ??
          StringConstants.notUsed,
      accessCode: (data['accessCode'] as String?) ?? '',
    );
  }

  factory PanelAccessLvlCfgDef.fromSetupData(AccessCodeSetupData data) {
    return PanelAccessLvlCfgDef(
      accessCodeNo: data.accessCodeNo,
      accessLevel: data.accessLevel,
      accessLevelName: data.accessLevelName,
      accessCode: data.accessCode,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = accessCodeNo & 0xFF;
    buf[1] = accessLevel & 0xFF;
    StructBytes.writeFixedText(
      buf,
      2,
      accessLevelName,
      SystemConfigLimits.panelAccLvlNameLength,
    );
    StructBytes.writeFixedText(
      buf,
      23,
      accessCode,
      SystemConfigLimits.panelAccCodeLength,
    );
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    StringConstants.accesscodeno: accessCodeNo,
    'accessLevel': accessLevel,
    StringConstants.accesslevelname: accessLevelName,
    'accessCode': accessCode,
  };

  AccessCodeSetupData toSetupData() {
    return AccessCodeSetupData(
      accessCodeNo: accessCodeNo,
      accessLevel: accessLevel,
      accessLevelName: accessLevelName,
      accessCode: accessCode,
    );
  }
}
