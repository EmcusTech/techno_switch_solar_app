import 'dart:typed_data';

class FirmwarePacket {
  final int sequence;
  final Uint8List bytes;

  FirmwarePacket({required this.sequence, required this.bytes});
}

class FirmwarePacketResult {
  final List<FirmwarePacket> packets;
  final int totalLogicalPackets;
  final List<int> skippedSequences;

  FirmwarePacketResult({
    required this.packets,
    required this.totalLogicalPackets,
    required this.skippedSequences,
  });
}
