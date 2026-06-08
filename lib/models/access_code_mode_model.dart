import 'dart:convert';

class AccessCodeSetupData {
  final int accessCodeNo;
  final int accessLevel;
  final String accessLevelName;
  final String accessCode;

  const AccessCodeSetupData({
    this.accessCodeNo = 1,
    this.accessLevel = 0,
    this.accessLevelName = 'Not Used',
    this.accessCode = '',
  });

  static const List<String> accessLevelNames = [
    'Not Used',
    'Untrained User',
    'Authorised User',
    'Commissioning',
  ];

  AccessCodeSetupData copyWith({
    int? accessCodeNo,
    int? accessLevel,
    String? accessLevelName,
    String? accessCode,
  }) {
    return AccessCodeSetupData(
      accessCodeNo: accessCodeNo ?? this.accessCodeNo,
      accessLevel: accessLevel ?? this.accessLevel,
      accessLevelName: accessLevelName ?? this.accessLevelName,
      accessCode: accessCode ?? this.accessCode,
    );
  }

  static AccessCodeSetupData fromPayload(List<int> payload) {
    if (payload.length < 16) {
      return const AccessCodeSetupData();
    }

    final accessCodeNo = payload[13];
    final level = payload[14];

    String code = '';

    final length = payload[15];

    final start = 16;
    final end = start + length;

    if (length > 0 && end <= payload.length) {
      try {
        code = utf8.decode(payload.sublist(start, end));
      } catch (_) {}
    }

    final levelName =
        (level >= 0 && level < accessLevelNames.length)
            ? accessLevelNames[level]
            : accessLevelNames.first;

    return AccessCodeSetupData(
      accessCodeNo: accessCodeNo,
      accessLevel: level,
      accessLevelName: levelName,
      accessCode: code,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessCodeNo': accessCodeNo,
    'accessLevel': accessLevel,
    'accessLevelName': accessLevelName,
    'accessCode': accessCode,
  };

  static AccessCodeSetupData fromJson(Map<String, dynamic> json) {
    return AccessCodeSetupData(
      accessCodeNo: json['accessCodeNo'] as int? ?? 1,
      accessLevel: json['accessLevel'] as int? ?? 0,
      accessLevelName: json['accessLevelName'] as String? ?? 'Not Used',
      accessCode: json['accessCode'] as String? ?? '',
    );
  }
}
