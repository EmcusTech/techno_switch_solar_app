class BleMsdUtils {
  BleMsdUtils._();

  static const int statusNormal = 0;
  static const int statusBootloader = 1;
  static const int statusUpgradeSuccess = 2;

  static int statusByte(List<int> msd) {
    if (msd.length >= 2) return msd[1];
    if (msd.isNotEmpty) return msd.last;
    return statusNormal;
  }

  static int? panelId(List<int> msd) {
    if (isBootloader(msd)) return null;
    if (msd.length >= 4) {
      return (msd[2] << 8) | msd[3];
    }
    return null;
  }

  /// Last two manufacturer-data bytes, high byte then low byte.
  /// `112, 79` is `0x704F`.
  static int? advertisedConfigCrc(List<int> msd) {
    if (isBootloader(msd) || msd.length < 6) return null;
    final high = msd[msd.length - 2] & 0xFF;
    final low = msd[msd.length - 1] & 0xFF;
    return (high << 8) | low;
  }

  static bool isBootloaderCorrupt(List<int> msd) {
    if (!isBootloader(msd) || msd.length < 4) return false;
    return msd[2] == 0 && msd[3] == 0;
  }

  static bool isBootloaderValid(List<int> msd) {
    if (!isBootloader(msd) || msd.length < 4) return false;
    return msd[2] == 0 && msd[3] == 1;
  }

  static bool isBootloader(List<int> msd) =>
      statusByte(msd) == statusBootloader;

  static bool isUpgradeSuccess(List<int> msd) =>
      statusByte(msd) == statusUpgradeSuccess;
}
