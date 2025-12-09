/// Model class to store MCU information including version and byte data
class MCUInfo {
  final String mcuType; // 'MainMCU', 'RfMCU', 'NetMCU'
  final String version;
  final List<int> byteData;
  final List<int> last100Bytes;

  MCUInfo({
    required this.mcuType,
    required this.version,
    required this.byteData,
    required this.last100Bytes,
  });

  @override
  String toString() {
    return 'MCUInfo(mcuType: $mcuType, version: $version, byteDataLength: ${byteData.length})';
  }
}

