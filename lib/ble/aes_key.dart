import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'dart:convert';

import 'ble_encryption_config.dart';

void _reverseKey(List<int> key) {
  for (int i = 0, j = key.length - 1; i < j; i++, j--) {
    final int tmp = key[i];
    key[i] = key[j];
    key[j] = tmp;
  }
}

/// Firmware XOR path: strength rounds of cycling XOR + key reversal.
Uint8List xorTransform(Uint8List data, List<int> handshakeKey) {
  final Uint8List out = Uint8List.fromList(data);
  final List<int> key = List<int>.from(
    handshakeKey.sublist(0, kBleEncryKeyByteSize),
  );

  // Match firmware: u8_key_index is declared once; it does NOT reset between
  // strength rounds (see aes_encrypt_data / aes_decrypt_data in panel C).
  int keyIndex = 0;
  for (int round = 0; round < kBleXorEncryptStrength; round++) {
    for (int i = 0; i < out.length; i++) {
      out[i] = out[i] ^ key[keyIndex];
      keyIndex = (keyIndex + 1) % kBleEncryKeyArraySize;
    }
    _reverseKey(key);
  }

  return out;
}

Uint8List pkcs7Pad(Uint8List data) {
  int blockSize = 16; // AES block size
  int paddingLength = blockSize - (data.length % blockSize);
  return Uint8List.fromList(data + List.filled(paddingLength, paddingLength));
}

Uint8List pkcs7Unpad(Uint8List data) {
  int paddingLength = data.last;
  return Uint8List.sublistView(data, 0, data.length - paddingLength);
}

Uint8List aesEncrypt(Uint8List key, Uint8List data) {
  final aesKey = encrypt.Key(key);
  final aes = encrypt.Encrypter(
    encrypt.AES(aesKey, mode: encrypt.AESMode.ecb, padding: null),
  );

  Uint8List padded = pkcs7Pad(data);

  final encrypted = aes.encryptBytes(padded);
  return Uint8List.fromList(encrypted.bytes);
}

Uint8List aesDecrypt(Uint8List key, Uint8List encryptedData) {
  final aesKey = encrypt.Key(key);
  final aes = encrypt.Encrypter(
    encrypt.AES(aesKey, mode: encrypt.AESMode.ecb, padding: null),
  );

  final decrypted = aes.decryptBytes(encrypt.Encrypted(encryptedData));

  return pkcs7Unpad(Uint8List.fromList(decrypted));
}

/// Converts a dynamic input to Uint8List (bytes)
Uint8List convertToBytes(dynamic data) {
  // Check if data is hex string
  if (data is String && isHex(data)) {
    return Uint8List.fromList(hexToBytes(data));
  }

  // Already Uint8List
  if (data is Uint8List) {
    return data;
  }

  // Convert normal string
  if (data is String) {
    return Uint8List.fromList(utf8.encode(data));
  }

  // Convert list<int>
  if (data is List<int>) {
    return Uint8List.fromList(data);
  }

  throw ArgumentError("Unsupported data type for conversion to bytes");
}

/// Check if a string is a valid hexadecimal string
bool isHex(String s) {
  final hexReg = RegExp(r'^[0-9A-Fa-f]+$');
  return hexReg.hasMatch(s);
}

/// Convert a hex string (e.g., '0A1B2C') to a list of bytes
List<int> hexToBytes(String hex) {
  if (hex.length % 2 != 0) {
    // Pad with leading 0 if odd length
    hex = '0' + hex;
  }
  final result = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}
