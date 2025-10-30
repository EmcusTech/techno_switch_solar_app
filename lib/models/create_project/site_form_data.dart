class SiteFormData {
  String siteName;
  String installerName;
  String companyName;
  String saqccRegNumber;
  String buildingName;
  String installerContactNumber;
  String installerEmail;
  String siteDescription;

  SiteFormData({
    this.siteName = '',
    this.installerName = '',
    this.companyName = '',
    this.saqccRegNumber = '',
    this.buildingName = '',
    this.installerContactNumber = '',
    this.installerEmail = '',
    this.siteDescription = '',
  });

  SiteFormData copyWith({
    String? siteName,
    String? installerName,
    String? companyName,
    String? saqccRegNumber,
    String? buildingName,
    String? installerContactNumber,
    String? installerEmail,
    String? siteDescription,
  }) {
    return SiteFormData(
      siteName: siteName ?? this.siteName,
      installerName: installerName ?? this.installerName,
      companyName: companyName ?? this.companyName,
      saqccRegNumber: saqccRegNumber ?? this.saqccRegNumber,
      buildingName: buildingName ?? this.buildingName,
      installerContactNumber:
          installerContactNumber ?? this.installerContactNumber,
      installerEmail: installerEmail ?? this.installerEmail,
      siteDescription: siteDescription ?? this.siteDescription,
    );
  }
}
