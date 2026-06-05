import 'dart:typed_data';
import 'aes_key.dart' as crypto;
import 'ble_encryption_config.dart';

class BleCrypto {
  BleCrypto._();

  static bool get isEnabled => kBleEncryptionEnabled;

  static bool shouldTransform({
    required bool encryptParam,
    required bool pastEncryptionKeyExchange,
  }) {
    return kBleEncryptionEnabled && encryptParam && pastEncryptionKeyExchange;
  }

  static Uint8List extractKeyFromHandshakePayload(List<int> payload) {
    final int end = kBleEncryKeyPayloadOffset + kBleEncryKeyByteSize;
    if (payload.length < end) {
      throw StateError(
        'Encryption key response too short: ${payload.length} bytes',
      );
    }
    print(
      "extractKeyFromHandshakePayload: ${payload.sublist(kBleEncryKeyPayloadOffset, end).map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    return Uint8List.fromList(payload.sublist(kBleEncryKeyPayloadOffset, end));
  }

  static Uint8List transformTx(Uint8List plainFrame, List<int> key16) {
    if (!kBleEncryptionEnabled) {
      return plainFrame;
    }
    _validateKey(key16);
    switch (kBleEncryptionAlgorithm) {
      case BleEncryptionAlgorithm.xor:
        return crypto.xorTransform(plainFrame, key16);
      case BleEncryptionAlgorithm.aes:
        return crypto.aesEncrypt(Uint8List.fromList(key16), plainFrame);
    }
  }

  static Uint8List transformRx(Uint8List encryptedFrame, List<int> key16) {
    if (!kBleEncryptionEnabled) {
      return encryptedFrame;
    }
    _validateKey(key16);
    switch (kBleEncryptionAlgorithm) {
      case BleEncryptionAlgorithm.xor:
        return crypto.xorTransform(encryptedFrame, key16);
      case BleEncryptionAlgorithm.aes:
        return crypto.aesDecrypt(Uint8List.fromList(key16), encryptedFrame);
    }
  }

  static void _validateKey(List<int> key16) {
    if (key16.length < kBleEncryKeyByteSize) {
      throw StateError(
        'Encryption key must be at least $kBleEncryKeyByteSize bytes',
      );
    }
  }
}
