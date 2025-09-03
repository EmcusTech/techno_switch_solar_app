import 'package:techno_switch_solar_app/utils/protocols/models/command_data_model.dart';
import 'package:techno_switch_solar_app/utils/protocols/models/net_packet_data_model.dart';

class NetworkPacket {
  final int sot;
  final int des;
  final int ori;
  final int typ;
  final int txp;
  final int rxp;
  final NetworkPacketData data;
  final List<int> chk;
  final int eot;

  NetworkPacket({
    required this.sot,
    required this.des,
    required this.ori,
    required this.typ,
    required this.txp,
    required this.rxp,
    required this.data,
    required this.chk,
    required this.eot,
  });

  List<int> getPacket() {
    return List.from([sot, des, ori, typ, txp, rxp, data, ...chk, eot]);
  }
}

enum NetworkPacketType { networkPacket, commandPacket }

class NetworkPacketData {
  final NetPacketDataModel? networkPacketDataModel;
  final CommandDataModel? commandDataModel;

  NetworkPacketData({this.networkPacketDataModel, this.commandDataModel});
}
