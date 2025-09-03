enum PacketType {
  pol(0),
  nrm(1),
  ack(2),
  nak(3),
  net(4),
  syn(5);

  final int value;

  const PacketType(this.value);
}
