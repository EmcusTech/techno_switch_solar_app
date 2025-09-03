class NetPacketDataModel {
  //ids
  final int uniqueId;
  final int uniqueIdChecksum;
  // module info
  final int moduleType;
  final int moduleRevision;
  final int moduleName;
  //module hardware info
  final int moduleHardwareMajorRevision;
  final int moduleHardwareMinorRevision;
  final int moduleHardwareOption;
  final int moduleHardwareVersion;
  //module software info
  final int moduleSoftwareMajorRevision;
  final int moduleSoftwareMinorRevision;
  final int moduleSoftwareRelease;
  final int moduleSoftwareBuild;
  final int moduleSoftwareReleaseYear;
  final int moduleSoftwareReleaseMonth;
  final int moduleSoftwareReleaseDay;

  final int moduleSoftwareProtocolRevision;

  NetPacketDataModel({
    required this.uniqueId,
    required this.uniqueIdChecksum,
    required this.moduleType,
    required this.moduleRevision,
    required this.moduleName,
    required this.moduleHardwareMajorRevision,
    required this.moduleHardwareMinorRevision,
    required this.moduleHardwareOption,
    required this.moduleHardwareVersion,
    required this.moduleSoftwareMajorRevision,
    required this.moduleSoftwareMinorRevision,
    required this.moduleSoftwareRelease,
    required this.moduleSoftwareBuild,
    required this.moduleSoftwareReleaseYear,
    required this.moduleSoftwareReleaseMonth,
    required this.moduleSoftwareReleaseDay,
    required this.moduleSoftwareProtocolRevision,
  });
}
