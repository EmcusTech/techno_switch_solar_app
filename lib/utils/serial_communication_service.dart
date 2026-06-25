import 'dart:async';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

enum PanelConnectionState { notConnected, connected, processing }

enum ProcessState {
  reqNwkPkt,
  reqAccessKey,
  dummyPktSend,
  readEvtLog,
  reqRspWaitState,
}

enum PacketType {
  poll(0),
  nrm(1),
  ack(2),
  nack(3),
  nwk(4),
  sync(5);

  const PacketType(this.value);
  final int value;
}

enum RequestMode {
  pollReq(0),
  moduleReq(1),
  dbSetupReq(2),
  dbStatusReq(3),
  cntrlReq(4);

  const RequestMode(this.value);
  final int value;
}

enum InstructMode {
  pollInstruct(0x80),
  moduleInstruct(0x81),
  dbSetupInstruct(0x82),
  dbStatusInstruct(0x83),
  cntrlInstruct(0x84);

  const InstructMode(this.value);
  final int value;
}

class CommHeader {
  int nwk = 0;
  int nod = 0;
  int subnod = 0;
  int module = 0;
  int mode = 0;
  int sck = 0;
  int cmd = 0;
}

class CommData {
  CommHeader header = CommHeader();
  List<int> data = List.filled(200, 0);
}

class CommFrame {
  int sot = 0;
  int dest = 0;
  int origin = 0;
  int pktTyp = 0;
  int txp = 0;
  int rxp = 0;
  CommData payload = CommData();
  int crc = 0;
  int eot = 0;
}

class SerialCommunicationService {
  static SerialCommunicationService? _instance;

  static SerialCommunicationService get instance {
    _instance ??= SerialCommunicationService._internal();
    return _instance!;
  }

  SerialCommunicationService._internal();

  factory SerialCommunicationService() => instance;

  static const int frameSot = 0xFE;
  static const int frameEot = 0xFD;
  static const int frameHeaderSize = 7;
  static const int frameOtherFieldSize = 9;
  static const int framePayloadSize = 200;
  static const int commEachFrameSize = 216;
  static const int eventStatusCmd = 0x02;
  static const int scriptOrig = 0;
  static const int scriptDest = 1;

  static const int logNw = 0;
  static const int logNd = 0;
  static const int logSnd = 0;
  static const int logMo = 0;
  static const int logMd = 2;
  static const int logSk = 0;
  static const int logCmd = 2;
  static const int logEvtSearchMethod = 0x04;

  DiscoveredDevice? _device;
  final PanelConnectionState _connectionState =
      PanelConnectionState.notConnected;

  int logCount = 1001;

  String? _currentPanelId;
  final StreamController<LogModel> _logStreamController =
      StreamController<LogModel>.broadcast();
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  Stream<LogModel> get logStream => _logStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;

  PanelConnectionState get connectionState => _connectionState;
  bool get isConnected =>
      _connectionState == PanelConnectionState.connected ||
      _connectionState == PanelConnectionState.processing;
  DiscoveredDevice? get connectedDevice => _device;
  String? get currentPanelId {
    return _currentPanelId;
  }

  void dispose() {
    _logStreamController.close();
    _statusStreamController.close();
  }
}
