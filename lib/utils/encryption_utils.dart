import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/aes_key.dart';
import 'package:techno_switch_solar_app/ble/ble_crypto.dart';
import 'package:techno_switch_solar_app/ble/ble_encryption_config.dart';
import 'logger.dart';
import 'storage/encryption_key_store.dart';

class EncryptionUtils {
  Future<Uint8List> encryptData({required List<int> data}) async {
    if (!kBleEncryptionEnabled) {
      return Uint8List.fromList(data);
    }

    final String? encryptionKeyHex =
        await EncryptionKeyStore.instance.readKey();
    if (encryptionKeyHex == null || encryptionKeyHex.isEmpty) {
      throw StateError('Encryption key not available');
    }

    final List<int> keyBytes = hexToBytes(encryptionKeyHex);
    return BleCrypto.transformTx(Uint8List.fromList(data), keyBytes);
  }

  Future<Uint8List> encryptDataWithFixedKey({required List<int> data}) async {
    if (!kBleEncryptionEnabled) {
      return Uint8List.fromList(data);
    }

    const String encryptionKeyHex = '47502941506172596f29336665252a2f';
    final List<int> keyBytes = hexToBytes(encryptionKeyHex);
    return BleCrypto.transformTx(Uint8List.fromList(data), keyBytes);
  }

  Future<List<int>?> decryptData(String chipherText) async {
    if (!kBleEncryptionEnabled) {
      return hexToBytes(chipherText);
    }

    final String? encryptionKeyHex =
        await EncryptionKeyStore.instance.readKey();
    if (encryptionKeyHex == null || encryptionKeyHex.isEmpty) {
      throw StateError('Encryption key not available');
    }

    List<int>? decryptedData;
    final List<int> keyBytes = hexToBytes(encryptionKeyHex);
    Logger(chipherText);
    try {
      decryptedData = BleCrypto.transformRx(
        Uint8List.fromList(hexToBytes(chipherText)),
        keyBytes,
      ).toList();
      Logger(
        ':::::::::::::::Decrypted data:::::: 1 ${decryptedData.toString()}',
      );
    } on Exception catch (e) {
      Logger(':::::::::::::::::Catch:::::::::::::');
      Logger(e.toString());
    }
    return decryptedData;
  }

  Future<List<int>?> decryptDataWithFixedKey(String chipherText) async {
    if (!kBleEncryptionEnabled) {
      return hexToBytes(chipherText);
    }

    const String encryptionKeyHex = '47502941506172596f29336665252a2f';
    List<int>? decryptedData;
    final List<int> keyBytes = hexToBytes(encryptionKeyHex);
    Logger(chipherText);
    try {
      decryptedData = BleCrypto.transformRx(
        Uint8List.fromList(hexToBytes(chipherText)),
        keyBytes,
      ).toList();
      Logger(
        ':::::::::::::::Decrypted data:::::: 2 ${decryptedData.toString()}',
      );
    } on Exception catch (e) {
      Logger(':::::::::::::::::Catch:::::::::::::');
      Logger(e.toString());
    }
    return decryptedData;
  }
}
