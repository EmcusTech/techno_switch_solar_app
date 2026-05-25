/// BLE encryption configuration — edit these values to control TX/RX crypto.
library;

/// XOR → firmware `ENABLE_XOR_ENCRYPTION` path.
/// AES → firmware `#else` path (AES-ECB + PKCS7).
enum BleEncryptionAlgorithm { xor, aes }

// ── User controls (edit in code) ────────────────────────────────────────────

/// Master switch — when false, all BLE traffic is plain.
const bool kBleEncryptionEnabled = true;

/// Algorithm used when [kBleEncryptionEnabled] is true.
const BleEncryptionAlgorithm kBleEncryptionAlgorithm =
    BleEncryptionAlgorithm.xor;

// ── Firmware constants ──────────────────────────────────────────────────────

/// Matches firmware `AES_CRYP_ENCRY_KEY_BYTE_SIZE`.
const int kBleEncryKeyByteSize = 16;

/// Matches firmware `AES_ENCRY_KEY_ARRAY_SIZE`.
const int kBleEncryKeyArraySize = 16;

/// Matches firmware `u8_encrypt_strength` in XOR path.
const int kBleXorEncryptStrength = 2;

/// Key starts at this offset in the encryption-key response payload.
const int kBleEncryKeyPayloadOffset = 0;

/// AES block size for the legacy AES-ECB path.
const int kBleAesBlockSize = 16;
