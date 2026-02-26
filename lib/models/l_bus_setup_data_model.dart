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
    this.enabled = 'No',
    this.idLed = 'No',
    this.product = 'None',
    this.deviceText = '',
    this.id = 0,
    this.revision = 0,
    this.productRev = '',
    this.hardware = '—',
    this.firmware = '—',
    this.date = '',
    this.protocol = 0,
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

  static LBusSetupData fromPayload(
    List<int> payload, {
    required String Function(List<int> payload, {int startIndex}) extractString,
  }) {
    if (payload.length < 20) return const LBusSetupData();

    String safeExtract(int startIndex) {
      try {
        return extractString(payload, startIndex: startIndex);
      } catch (_) {
        return '';
      }
    }

    final enabled = payload[14] == 0x01 ? 'Yes' : 'No';
    final idLed = payload[15] == 0x01 ? 'Yes' : 'No';
    final id = payload.length > 16 ? payload[16] : 0;
    final revision = payload.length > 17 ? payload[17] : 0;
    final product = safeExtract(18);
    final deviceText = safeExtract(30);
    final productRev = safeExtract(53);
    final hardware =
        payload.length > 70
            ? [payload[67], payload[68], payload[69], payload[70]].join('.')
            : '—';
    final firmware =
        payload.length > 74
            ? [payload[71], payload[72], payload[73], payload[74]].join('.')
            : '—';
    final year = payload.length > 76 ? (payload[75] << 8) | payload[76] : 0;
    final month = payload.length > 77 ? payload[77] : 0;
    final day = payload.length > 78 ? payload[78] : 0;
    final date =
        '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';
    final protocol = payload.length > 80 ? payload[80] : 0;

    return LBusSetupData(
      enabled: enabled,
      idLed: idLed,
      product: product.isEmpty ? 'None' : product,
      deviceText: deviceText,
      id: id,
      revision: revision,
      productRev: productRev,
      hardware: hardware,
      firmware: firmware,
      date: date,
      protocol: protocol,
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
    enabled: json['enabled'] as String? ?? 'No',
    idLed: json['idLed'] as String? ?? 'No',
    product: json['product'] as String? ?? 'None',
    deviceText: json['deviceText'] as String? ?? '',
    id: json['id'] as int? ?? 0,
    revision: json['revision'] as int? ?? 0,
    productRev: json['productRev'] as String? ?? '',
    hardware: json['hardware'] as String? ?? '—',
    firmware: json['firmware'] as String? ?? '—',
    date: json['date'] as String? ?? '',
    protocol: json['protocol'] as int? ?? 0,
  );
}
