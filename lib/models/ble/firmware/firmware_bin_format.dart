import 'dart:typed_data';

/// Trailing structure of a firmware `.bin` (after the raw image bytes).
/// Order from the start of the 40-byte trailer: FW ver → HW ver → date → product ID → CRC.
class FirmwareBinFormat {
  FirmwareBinFormat._();

  static const int trailerLength = 40;
  static const int crcLength = 4;

  static const int firmwareVersionLength = 10;
  static const int hardwareVersionLength = 7;
  static const int dateLength = 8;
  static const int productIdLength = 11;

  static int get metadataLength =>
      firmwareVersionLength +
      hardwareVersionLength +
      dateLength +
      productIdLength;
}

class FirmwareBinTrailer {
  const FirmwareBinTrailer({
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.date,
    required this.productId,
  });

  final String firmwareVersion;
  final String hardwareVersion;
  final String date;
  final String productId;

  static String _fieldToString(Uint8List raw) {
    if (raw.isEmpty) return '';
    return String.fromCharCodes(
      raw,
    ).replaceAll(String.fromCharCode(0), '').trim();
  }

  /// Last 40 bytes of the file: 10+7+8+11 bytes metadata, then 4 byte CRC.
  static FirmwareBinTrailer fromLast40Bytes(Uint8List trailer) {
    if (trailer.length != FirmwareBinFormat.trailerLength) {
      throw ArgumentError(
        'Trailer must be ${FirmwareBinFormat.trailerLength} bytes',
      );
    }
    int o = 0;
    final fw = trailer.sublist(o, o + FirmwareBinFormat.firmwareVersionLength);
    o += FirmwareBinFormat.firmwareVersionLength;
    final hw = trailer.sublist(o, o + FirmwareBinFormat.hardwareVersionLength);
    o += FirmwareBinFormat.hardwareVersionLength;
    final d = trailer.sublist(o, o + FirmwareBinFormat.dateLength);
    o += FirmwareBinFormat.dateLength;
    final pid = trailer.sublist(o, o + FirmwareBinFormat.productIdLength);
    print("firnware data: fw: ${_fieldToString(fw)}");
    print("firnware data: hw: ${_fieldToString(hw)}");
    print("firnware data: d: ${_fieldToString(d)}");
    print("firnware data: pid: ${_fieldToString(pid)}");
    return FirmwareBinTrailer(
      firmwareVersion: _fieldToString(fw),
      hardwareVersion: _fieldToString(hw),
      date: _fieldToString(d),
      productId: _fieldToString(pid),
    );
  }
}
