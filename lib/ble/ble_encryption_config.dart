library;

enum BleEncryptionAlgorithm { xor, aes }

const bool kBleEncryptionEnabled = true;

const BleEncryptionAlgorithm kBleEncryptionAlgorithm =
    BleEncryptionAlgorithm.xor;

const int kBleEncryKeyByteSize = 16;

const int kBleEncryKeyArraySize = 16;

const int kBleXorEncryptStrength = 2;

const int kBleEncryKeyPayloadOffset = 0;

const int kBleAesBlockSize = 16;
