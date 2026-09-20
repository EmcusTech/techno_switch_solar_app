import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/panel_properties_defaults.dart';

/// Mirrors firmware `st_panel_properties_def` (70 bytes, packed).
class PanelPropertiesCfgDef {
  const PanelPropertiesCfgDef({
    this.panelNum = PanelPropertiesDefaults.panelNum,
    this.panelName = PanelPropertiesDefaults.panelName,
    this.eventReminderDelay = PanelPropertiesDefaults.eventReminderDelay,
    this.remEnable = PanelPropertiesDefaults.remEnable,
    this.lvlTimeout = PanelPropertiesDefaults.lvlTimeout,
    this.silenceBuzzLvl = PanelPropertiesDefaults.silenceBuzzLvl,
    this.silenceSndrLvl = PanelPropertiesDefaults.silenceSndrLvl,
    this.resetLvl = PanelPropertiesDefaults.resetLvl,
    this.faultLatch = PanelPropertiesDefaults.faultLatch,
    this.serviceDueMonth = PanelPropertiesDefaults.serviceDueMonth,
    this.serviceDueDay = PanelPropertiesDefaults.serviceDueDay,
    this.serviceDueYear = PanelPropertiesDefaults.serviceDueYear,
    this.serviceDueHour = PanelPropertiesDefaults.serviceDueHour,
    this.serviceDueMinute = PanelPropertiesDefaults.serviceDueMinute,
    this.companyName = PanelPropertiesDefaults.companyName,
    this.serviceContact = PanelPropertiesDefaults.serviceContact,
  });

  static const int byteLength = 70;

  final int panelNum;
  final String panelName;
  final int eventReminderDelay;
  final int remEnable;
  final int lvlTimeout;
  final int silenceBuzzLvl;
  final int silenceSndrLvl;
  final int resetLvl;
  final int faultLatch;
  final int serviceDueMonth;
  final int serviceDueDay;
  final int serviceDueYear;
  final int serviceDueHour;
  final int serviceDueMinute;
  final String companyName;
  final String serviceContact;

  factory PanelPropertiesCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'PanelPropertiesCfgDef requires $byteLength bytes at offset $offset',
      );
    }
    return PanelPropertiesCfgDef(
      panelNum: bytes[offset],
      panelName: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.panelNameTextLength,
      ),
      eventReminderDelay: StructBytes.readUint16Le(bytes, offset + 22),
      remEnable: bytes[offset + 24],
      lvlTimeout: StructBytes.readUint16Le(bytes, offset + 25),
      silenceBuzzLvl: bytes[offset + 27],
      silenceSndrLvl: bytes[offset + 28],
      resetLvl: bytes[offset + 29],
      faultLatch: bytes[offset + 30],
      serviceDueMonth: bytes[offset + 31],
      serviceDueDay: bytes[offset + 32],
      serviceDueYear: bytes[offset + 33],
      serviceDueHour: bytes[offset + 34],
      serviceDueMinute: bytes[offset + 35],
      companyName: StructBytes.readFixedText(
        bytes,
        offset + 36,
        SystemConfigLimits.panelNameTextLength,
      ),
      serviceContact: StructBytes.readFixedText(
        bytes,
        offset + 57,
        SystemConfigLimits.contactNumLength,
      ),
    );
  }

  factory PanelPropertiesCfgDef.fromCacheMap(Map<String, dynamic> data) {
    return PanelPropertiesCfgDef(
      panelNum:
          (data['panelNum'] as num?)?.toInt() ??
          (data['panelId'] as num?)?.toInt() ??
          PanelPropertiesDefaults.panelNum,
      panelName:
          (data['panelName'] as String?) ??
          (data[StringConstants.panelname] as String?) ??
          PanelPropertiesDefaults.panelName,
      eventReminderDelay:
          (data['eventReminderDelay'] as num?)?.toInt() ??
          (data['delay'] as num?)?.toInt() ??
          PanelPropertiesDefaults.eventReminderDelay,
      remEnable:
          (data['remEnable'] as num?)?.toInt() ??
          (data['reminder'] as num?)?.toInt() ??
          PanelPropertiesDefaults.remEnable,
      lvlTimeout:
          (data['lvlTimeout'] as num?)?.toInt() ??
          PanelPropertiesDefaults.lvlTimeout,
      silenceBuzzLvl:
          (data['silenceBuzzLvl'] as num?)?.toInt() ??
          (data['silenceBuzzerLevelIndex'] as num?)?.toInt() ??
          PanelPropertiesDefaults.silenceBuzzLvl,
      silenceSndrLvl:
          (data['silenceSndrLvl'] as num?)?.toInt() ??
          (data['silenceSoundersLevelIndex'] as num?)?.toInt() ??
          PanelPropertiesDefaults.silenceSndrLvl,
      resetLvl:
          (data['resetLvl'] as num?)?.toInt() ??
          (data['resetLevelIndex'] as num?)?.toInt() ??
          PanelPropertiesDefaults.resetLvl,
      faultLatch:
          (data['faultLatch'] as num?)?.toInt() ??
          (data['faultLatchingIndex'] as num?)?.toInt() ??
          PanelPropertiesDefaults.faultLatch,
      serviceDueMonth:
          (data['serviceDueMonth'] as num?)?.toInt() ??
          (data['month'] as num?)?.toInt() ??
          PanelPropertiesDefaults.serviceDueMonth,
      serviceDueDay:
          (data['serviceDueDay'] as num?)?.toInt() ??
          (data['day'] as num?)?.toInt() ??
          PanelPropertiesDefaults.serviceDueDay,
      serviceDueYear:
          (data['serviceDueYear'] as num?)?.toInt() ??
          (data['year'] as num?)?.toInt() ??
          PanelPropertiesDefaults.serviceDueYear,
      serviceDueHour:
          (data['serviceDueHour'] as num?)?.toInt() ??
          (data['hour'] as num?)?.toInt() ??
          PanelPropertiesDefaults.serviceDueHour,
      serviceDueMinute:
          (data['serviceDueMinute'] as num?)?.toInt() ??
          (data['minute'] as num?)?.toInt() ??
          PanelPropertiesDefaults.serviceDueMinute,
      companyName:
          (data['companyName'] as String?) ??
          (data['company'] as String?) ??
          PanelPropertiesDefaults.companyName,
      serviceContact:
          (data['serviceContact'] as String?) ??
          (data['contact'] as String?) ??
          PanelPropertiesDefaults.serviceContact,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = panelNum & 0xFF;
    StructBytes.writeFixedText(
      buf,
      1,
      panelName,
      SystemConfigLimits.panelNameTextLength,
    );
    StructBytes.writeUint16Le(buf, 22, eventReminderDelay);
    buf[24] = remEnable & 0xFF;
    StructBytes.writeUint16Le(buf, 25, lvlTimeout);
    buf[27] = silenceBuzzLvl & 0xFF;
    buf[28] = silenceSndrLvl & 0xFF;
    buf[29] = resetLvl & 0xFF;
    buf[30] = faultLatch & 0xFF;
    buf[31] = serviceDueMonth & 0xFF;
    buf[32] = serviceDueDay & 0xFF;
    buf[33] = serviceDueYear & 0xFF;
    buf[34] = serviceDueHour & 0xFF;
    buf[35] = serviceDueMinute & 0xFF;
    StructBytes.writeFixedText(
      buf,
      36,
      companyName,
      SystemConfigLimits.panelNameTextLength,
    );
    StructBytes.writeFixedText(
      buf,
      57,
      serviceContact,
      SystemConfigLimits.contactNumLength,
    );
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    'panelNum': panelNum,
    'panelName': panelName,
    'eventReminderDelay': eventReminderDelay,
    'remEnable': remEnable,
    'lvlTimeout': lvlTimeout,
    'silenceBuzzLvl': silenceBuzzLvl,
    'silenceSndrLvl': silenceSndrLvl,
    'resetLvl': resetLvl,
    'faultLatch': faultLatch,
    'serviceDueMonth': serviceDueMonth,
    'serviceDueDay': serviceDueDay,
    'serviceDueYear': serviceDueYear,
    'serviceDueHour': serviceDueHour,
    'serviceDueMinute': serviceDueMinute,
    'companyName': companyName,
    'serviceContact': serviceContact,
  };
}
