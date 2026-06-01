/// Utilities for parsing BLE Manufacturer Specific Data (MSD).
///
/// Legacy format (2 bytes): `[status0, status1]` — mode is in byte index 1.
/// Current format (4 bytes): `[status0, status1, byte2, byte3]` —
/// bytes 0–1 unchanged; bytes 2–3 meaning depends on mode:
/// - In application mode: may encode panel ID (see [panelId]).
/// - In bootloader mode (byte 1 == 1): `[0, 0]` corrupt, `[0, 1]` valid.
class BleMsdUtils {
  BleMsdUtils._();

  /// Normal application mode.
  static const int statusNormal = 0;

  /// Bootloader / firmware upgrade mode.
  static const int statusBootloader = 1;

  /// Firmware upgrade completed successfully.
  static const int statusUpgradeSuccess = 2;

  /// Returns the device mode/status byte from MSD.
  /// Uses index 1 for 2+ byte payloads; falls back to the sole byte for 1-byte MSD.
  static int statusByte(List<int> msd) {
    if (msd.length >= 2) return msd[1];
    if (msd.isNotEmpty) return msd.last;
    return statusNormal;
  }

  /// Returns the panel ID from bytes 2–3 when present (application mode).
  static int? panelId(List<int> msd) {
    if (isBootloader(msd)) return null;
    if (msd.length >= 4) {
      return (msd[2] << 8) | msd[3];
    }
    return null;
  }

  /// Bootloader MSD bytes 2–3: `[0, 0]` means on-device bootloader image is corrupt.
  static bool isBootloaderCorrupt(List<int> msd) {
    if (!isBootloader(msd) || msd.length < 4) return false;
    return msd[2] == 0 && msd[3] == 0;
  }

  /// Bootloader MSD bytes 2–3: `[0, 1]` means on-device bootloader image is valid.
  static bool isBootloaderValid(List<int> msd) {
    if (!isBootloader(msd) || msd.length < 4) return false;
    return msd[2] == 0 && msd[3] == 1;
  }

  static bool isBootloader(List<int> msd) =>
      statusByte(msd) == statusBootloader;

  static bool isUpgradeSuccess(List<int> msd) =>
      statusByte(msd) == statusUpgradeSuccess;
}
