import 'dart:typed_data';

/// Common SETUP_* data section offset inside the 216-byte BLE frame.
///
/// Protocol data starts at offset 7 (NETWORK..SETUP command header is 0..6).
/// In the Flutter frame, the command byte is at [12], so structs begin at [13].
abstract final class ConfigSetupPayload {
  static const int commandOffset = 12;
  static const int structOffset = 13;

  static void writeStruct(Uint8List packet, Uint8List structBytes) {
    packet.setRange(
      structOffset,
      structOffset + structBytes.length,
      structBytes,
    );
  }

  static Uint8List readStructBytes(List<int> payload, int structByteLength) {
    final bytes = Uint8List.fromList(payload);
    if (bytes.length < structOffset + structByteLength) {
      throw RangeError(
        'SETUP payload needs ${structOffset + structByteLength} bytes, got ${bytes.length}',
      );
    }
    return Uint8List.sublistView(bytes, structOffset, structOffset + structByteLength);
  }
}
