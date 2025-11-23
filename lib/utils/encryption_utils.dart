import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'logger.dart';
import 'storage/encryption_key_store.dart';

const String _defaultAesPadding = 'PKCS7';

class EncryptionUtils {
  /// Encrypts the given data using the stored encryption key.
  ///
  /// This method encrypts the input data using the encryption key retrieved
  /// from the shared preferences. It returns a Future<Uint8List> containing the encrypted bytes.
  ///
  /// Parameters:
  ///   - data: The data to be encrypted.
  ///
  /// Returns:
  ///   A Future<Uint8List> containing the encrypted bytes.
  ///
  Future<Uint8List> encryptData({required List<int> data}) async {
    final String? encryptionKey = await EncryptionKeyStore.instance.readKey();
    if (encryptionKey == null || encryptionKey.isEmpty) {
      throw StateError('Encryption key not available');
    }
    final Key key = encrypt.Key.fromBase16(encryptionKey);
    final Encrypter encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: _defaultAesPadding),
    );
    final Encrypted encrypted = encrypter.encryptBytes(data);

    return encrypted.bytes;
  }

  Future<Uint8List> encryptDataWithFixedKey({required List<int> data}) async {
    String? encryptionKey = "47502941506172596f29336665252a2f";
    final Key key = encrypt.Key.fromBase16(encryptionKey);
    final Encrypter encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: _defaultAesPadding),
    );
    final Encrypted encrypted = encrypter.encryptBytes(data);

    return encrypted.bytes;
  }

  /// Decrypts the given cipher text using the stored encryption key.
  ///
  /// This method decrypts the input cipher text using the encryption key retrieved
  /// from the shared preferences. It returns the decrypted string.
  ///
  /// Parameters:
  ///   - chipherText: The cipher text to be decrypted.
  ///
  /// Returns:
  ///   A Future<String> containing the decrypted string.
  ///
  /// Throws:
  ///   An Exception if decryption fails.
  Future<List<int>?> decryptData(String chipherText) async {
    final String? encryptionKey = await EncryptionKeyStore.instance.readKey();
    if (encryptionKey == null || encryptionKey.isEmpty) {
      throw StateError('Encryption key not available');
    }
    List<int>? decryptedData;
    final Key key = encrypt.Key.fromBase16(encryptionKey);
    Logger(chipherText);
    try {
      final Encrypter decryption = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb),
      );
      final List<int> decrypted = decryption.decryptBytes(
        Encrypted.fromBase16(chipherText),
      );
      decryptedData = decrypted;
      Logger(":::::::::::::::Decrypted data:::::: ${decryptedData.toString()}");
    } on Exception catch (e) {
      Logger(":::::::::::::::::Catch:::::::::::::");
      Logger(e.toString());
    }
    return decryptedData;
  }

  Future<List<int>?> decryptDataWithFixedKey(String chipherText) async {
    String? encryptionKey = "47502941506172596f29336665252a2f";
    List<int>? decryptedData;
    final Key key = encrypt.Key.fromBase16(encryptionKey);
    Logger(chipherText);
    try {
      final Encrypter decryption = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb),
      );
      final List<int> decrypted = decryption.decryptBytes(
        Encrypted.fromBase16(chipherText),
      );
      decryptedData = decrypted;
      Logger(":::::::::::::::Decrypted data:::::: ${decryptedData.toString()}");
    } on Exception catch (e) {
      Logger(":::::::::::::::::Catch:::::::::::::");
      Logger(e.toString());
    }
    return decryptedData;
  }
}
