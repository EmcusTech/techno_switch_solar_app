import 'dart:convert';

import 'package:techno_switch_solar_app/utils/modes/l_bus_payload_config.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/l_bus_defaults.dart';

class LBusSetupData {
  final String enabled;
  final String idLed;
  final String product;
  final String deviceText;
  final int id;
  final int revision;
  final String productRev;
  final String hardware;
  final String firmware;
  final String date;
  final int protocol;

  const LBusSetupData({
    this.enabled = LBusDefaults.enabledLabel,
    this.idLed = LBusDefaults.idLedLabel,
    this.product = LBusDefaults.productLabel,
    this.deviceText = LBusDefaults.deviceText,
    this.id = LBusDefaults.id,
    this.revision = LBusDefaults.revision,
    this.productRev = LBusDefaults.productRev,
    this.hardware = LBusDefaults.hardware,
    this.firmware = LBusDefaults.firmware,
    this.date = LBusDefaults.date,
    this.protocol = LBusDefaults.protocol,
  });

  LBusSetupData copyWith({
    String? enabled,
    String? idLed,
    String? product,
    String? deviceText,
    int? id,
    int? revision,
    String? productRev,
    String? hardware,
    String? firmware,
    String? date,
    int? protocol,
  }) {
    return LBusSetupData(
      enabled: enabled ?? this.enabled,
      idLed: idLed ?? this.idLed,
      product: product ?? this.product,
      deviceText: deviceText ?? this.deviceText,
      id: id ?? this.id,
      revision: revision ?? this.revision,
      productRev: productRev ?? this.productRev,
      hardware: hardware ?? this.hardware,
      firmware: firmware ?? this.firmware,
      date: date ?? this.date,
      protocol: protocol ?? this.protocol,
    );
  }

  static LBusSetupData fromPayload(List<int> payload) {
    if (payload.length < 24) return const LBusSetupData();

    final statusConfig = LBusRepeaterStatusCodec.decode(
      payload[LBusPayloadIndices.repeaterStatus],
    );

    String deviceText = '';
    if (payload.length > LBusPayloadIndices.deviceTextStart) {
      final length = payload[LBusPayloadIndices.deviceTextLength];
      final endIndex = LBusPayloadIndices.deviceTextStart + length;
      if (endIndex <= payload.length && length > 0) {
        try {
          deviceText = utf8.decode(
            payload.sublist(LBusPayloadIndices.deviceTextStart, endIndex),
          );
        } catch (_) {}
      }
    }

    final product =
        payload.length > 14 && payload[14] == 0x16 ? 'Rhino103R' : 'None';

    return LBusSetupData(
      enabled: statusConfig.enable == LBusRepeaterEnable.enabled ? 'Yes' : 'No',
      idLed: statusConfig.idLed == LBusIdLed.on ? 'Yes' : 'No',
      product: product,
      deviceText: deviceText,
    );
  }

  static LBusSetupData mergeFromEnabledBusPayload(
    LBusSetupData existing,
    List<int> payload,
  ) {
    if (payload.length < 44) return existing;
    String productRev = '';
    if (payload.length > LBusPayloadIndices.enabledBusDataProductRevStart + 1) {
      final length = payload[LBusPayloadIndices.enabledBusDataProductRevStart];
      final start = LBusPayloadIndices.enabledBusDataProductRevStart + 1;
      final end = start + length;
      if (end <= payload.length && length > 0) {
        try {
          productRev = utf8.decode(payload.sublist(start, end));
        } catch (_) {}
      }
    }
    final hardware = [
      payload[LBusPayloadIndices.enabledBusDataHardwareStart],
      payload[LBusPayloadIndices.enabledBusDataHardwareStart + 1],
      payload[LBusPayloadIndices.enabledBusDataHardwareStart + 2],
      payload[LBusPayloadIndices.enabledBusDataHardwareStart + 3],
    ].join('.');
    final firmware = [
      payload[LBusPayloadIndices.enabledBusDataFirmwareStart],
      payload[LBusPayloadIndices.enabledBusDataFirmwareStart + 1],
      payload[LBusPayloadIndices.enabledBusDataFirmwareStart + 2],
      payload[LBusPayloadIndices.enabledBusDataFirmwareStart + 3],
    ].join('.');
    final year =
        (payload[LBusPayloadIndices.enabledBusDataDateYearHi] << 8) |
        payload[LBusPayloadIndices.enabledBusDataDateYearLo];
    final month = payload[LBusPayloadIndices.enabledBusDataDateMonth];
    final day = payload[LBusPayloadIndices.enabledBusDataDateDay];
    final date =
        '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';

    return existing.copyWith(
      id: payload[LBusPayloadIndices.enabledBusDataId],
      revision: payload[LBusPayloadIndices.enabledBusDataRevision],
      productRev: productRev,
      hardware: hardware,
      firmware: firmware,
      date: date,
      protocol: payload[LBusPayloadIndices.enabledBusDataProtocol],
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'idLed': idLed,
    'product': product,
    'deviceText': deviceText,
    'id': id,
    'revision': revision,
    'productRev': productRev,
    'hardware': hardware,
    'firmware': firmware,
    'date': date,
    'protocol': protocol,
  };

  static LBusSetupData fromJson(Map<String, dynamic> json) => LBusSetupData(
    enabled: json['enabled'] as String? ?? LBusDefaults.enabledLabel,
    idLed: json['idLed'] as String? ?? LBusDefaults.idLedLabel,
    product: json['product'] as String? ?? LBusDefaults.productLabel,
    deviceText: json['deviceText'] as String? ?? LBusDefaults.deviceText,
    id: json['id'] as int? ?? LBusDefaults.id,
    revision: json['revision'] as int? ?? LBusDefaults.revision,
    productRev: json['productRev'] as String? ?? LBusDefaults.productRev,
    hardware: json['hardware'] as String? ?? LBusDefaults.hardware,
    firmware: json['firmware'] as String? ?? LBusDefaults.firmware,
    date: json['date'] as String? ?? LBusDefaults.date,
    protocol: json['protocol'] as int? ?? LBusDefaults.protocol,
  );
}
