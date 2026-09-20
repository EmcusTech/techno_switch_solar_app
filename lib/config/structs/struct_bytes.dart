import 'dart:typed_data';

abstract final class StructBytes {
  static void writeFixedText(Uint8List buf, int offset, String text, int maxLen) {
    final units = text.codeUnits;
    final len = units.length.clamp(0, maxLen);
    for (var i = 0; i < len; i++) {
      buf[offset + i] = units[i];
    }
  }

  static String readFixedText(Uint8List bytes, int offset, int maxLen) {
    var len = maxLen;
    while (len > 0 && bytes[offset + len - 1] == 0) {
      len--;
    }
    if (len == 0) {
      return '';
    }
    return String.fromCharCodes(bytes.sublist(offset, offset + len));
  }

  static void writeUint16Le(Uint8List buf, int offset, int value) {
    buf[offset] = value & 0xFF;
    buf[offset + 1] = (value >> 8) & 0xFF;
  }

  static int readUint16Le(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  static void writeFixedAsciiDigits(
    Uint8List buf,
    int offset,
    String digits,
    int maxLen,
  ) {
    final trimmed = digits.trim();
    final len = trimmed.length.clamp(0, maxLen);
    for (var i = 0; i < len; i++) {
      buf[offset + i] = trimmed.codeUnitAt(i);
    }
  }

  static String readFixedAsciiDigits(Uint8List bytes, int offset, int maxLen) {
    final chars = <int>[];
    for (var i = 0; i < maxLen; i++) {
      final value = bytes[offset + i];
      if (value == 0) {
        break;
      }
      chars.add(value);
    }
    return String.fromCharCodes(chars);
  }
}
