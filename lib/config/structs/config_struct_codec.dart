import 'dart:typed_data';

/// Shared binary helpers for packed firmware config structs.
abstract final class ConfigStructCodec {
  static void writeFixedText(
    Uint8List buf,
    int offset,
    String text,
    int maxLength,
  ) {
    final units = text.codeUnits;
    final len = units.length.clamp(0, maxLength);
    for (var i = 0; i < len; i++) {
      buf[offset + i] = units[i];
    }
  }

  static String readFixedText(Uint8List bytes, int offset, int maxLength) {
    var len = maxLength;
    while (len > 0 && bytes[offset + len - 1] == 0) {
      len--;
    }
    if (len == 0) {
      return '';
    }
    return String.fromCharCodes(bytes.sublist(offset, offset + len));
  }

  static void writeU16Le(Uint8List buf, int offset, int value) {
    buf[offset] = value & 0xFF;
    buf[offset + 1] = (value >> 8) & 0xFF;
  }

  static int readU16Le(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  static int clampU8(int value) => value.clamp(0, 0xFF);
}
