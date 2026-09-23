import 'package:techno_switch_solar_app/config/ble/panel_access_lvl_setup_payload.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class AccessCodeSetupData {
  final int accessCodeNo;
  final int accessLevel;
  final String accessLevelName;
  final String accessCode;

  const AccessCodeSetupData({
    this.accessCodeNo = 1,
    this.accessLevel = 0,
    this.accessLevelName = StringConstants.notUsed,
    this.accessCode = '',
  });

  static const List<String> accessLevelNames = [
    StringConstants.notUsed,
    StringConstants.untrainedUser,
    StringConstants.authorisedUser,
    StringConstants.commissioning,
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
    return PanelAccessLvlSetupPayload.readSetupDataFromPacket(payload);
  }

  Map<String, dynamic> toJson() => {
    StringConstants.accesscodeno: accessCodeNo,
    'accessLevel': accessLevel,
    StringConstants.accesslevelname: accessLevelName,
    'accessCode': accessCode,
  };

  static AccessCodeSetupData fromJson(Map<String, dynamic> json) {
    return AccessCodeSetupData(
      accessCodeNo: json[StringConstants.accesscodeno] as int? ?? 1,
      accessLevel: json['accessLevel'] as int? ?? 0,
      accessLevelName: json[StringConstants.accesslevelname] as String? ?? StringConstants.notUsed,
      accessCode: json['accessCode'] as String? ?? '',
    );
  }
}
