class SiteModel {
  final int? id;
  final String siteName;
  final String installerName;
  final String companyName;
  final String saqccRegNumber;
  final String buildingName;
  final String installerContactNumber;
  final String installerEmail;
  final String siteDescription;
  final DateTime createdAt;
  final DateTime updatedAt;

  SiteModel({
    this.id,
    required this.siteName,
    required this.installerName,
    required this.companyName,
    required this.saqccRegNumber,
    required this.buildingName,
    required this.installerContactNumber,
    required this.installerEmail,
    required this.siteDescription,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Site object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_name': siteName,
      'installer_name': installerName,
      'company_name': companyName,
      'saqcc_reg_number': saqccRegNumber,
      'building_name': buildingName,
      'installer_contact_number': installerContactNumber,
      'installer_email': installerEmail,
      'site_description': siteDescription,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Convert Map from database to Site object
  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: map['id']?.toInt(),
      siteName: map['site_name'] ?? '',
      installerName: map['installer_name'] ?? '',
      companyName: map['company_name'] ?? '',
      saqccRegNumber: map['saqcc_reg_number'] ?? '',
      buildingName: map['building_name'] ?? '',
      installerContactNumber: map['installer_contact_number'] ?? '',
      installerEmail: map['installer_email'] ?? '',
      siteDescription: map['site_description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Create a copy with updated fields
  SiteModel copyWith({
    int? id,
    String? siteName,
    String? installerName,
    String? companyName,
    String? saqccRegNumber,
    String? buildingName,
    String? installerContactNumber,
    String? installerEmail,
    String? siteDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      installerName: installerName ?? this.installerName,
      companyName: companyName ?? this.companyName,
      saqccRegNumber: saqccRegNumber ?? this.saqccRegNumber,
      buildingName: buildingName ?? this.buildingName,
      installerContactNumber:
          installerContactNumber ?? this.installerContactNumber,
      installerEmail: installerEmail ?? this.installerEmail,
      siteDescription: siteDescription ?? this.siteDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SiteModel{id: $id, siteName: $siteName, installerName: $installerName, companyName: $companyName, saqccRegNumber: $saqccRegNumber, buildingName: $buildingName, installerContactNumber: $installerContactNumber, installerEmail: $installerEmail, siteDescription: $siteDescription, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          siteName == other.siteName &&
          installerName == other.installerName &&
          companyName == other.companyName &&
          saqccRegNumber == other.saqccRegNumber &&
          buildingName == other.buildingName &&
          installerContactNumber == other.installerContactNumber &&
          installerEmail == other.installerEmail &&
          siteDescription == other.siteDescription;

  @override
  int get hashCode =>
      id.hashCode ^
      siteName.hashCode ^
      installerName.hashCode ^
      companyName.hashCode ^
      saqccRegNumber.hashCode ^
      buildingName.hashCode ^
      installerContactNumber.hashCode ^
      installerEmail.hashCode ^
      siteDescription.hashCode;
}
