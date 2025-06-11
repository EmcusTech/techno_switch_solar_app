import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/utils/timestamp_converter.dart';

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
  static const int frameSot = 0xFE;
  static const int frameEot = 0xFD;
  static const int frameHeaderSize = 7;
  static const int frameOtherFieldSize = 9;
  static const int framePayloadSize = 200;
  static const int commEachFrameSize = 216;
  static const int eventStatusCmd = 0x02;
  static const int scriptOrig = 0;
  static const int scriptDest = 1;

  // Event log details
  static const int logNw = 0;
  static const int logNd = 0;
  static const int logSnd = 0;
  static const int logMo = 0;
  static const int logMd = 2;
  static const int logSk = 0;
  static const int logCmd = 2;
  static const int logEvtSearchMethod = 0x04;

  UsbPort? _port;
  StreamSubscription? _subscription;
  PanelConnectionState _connectionState = PanelConnectionState.notConnected;
  ProcessState _processState = ProcessState.reqNwkPkt;
  ProcessState _mainProcessState = ProcessState.reqNwkPkt;

  int _pktTxCnt = 0;
  int _pktRxCnt = 0;
  int _logEvtSearchNumber = 200; // Start from 1000th log
  bool _stopEvtLogRead = false;
  int _totalValidEvtLogCnt = 0;
  Timer? _processTimer;
  Timer? _responseTimer;

  final CommFrame _commFrame = CommFrame();
  final StreamController<LogModel> _logStreamController =
      StreamController<LogModel>.broadcast();
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  Stream<LogModel> get logStream => _logStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;

  Future<bool> connectToDevice() async {
    try {
      _statusStreamController.add("Searching for USB devices...");

      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        _statusStreamController.add("No USB devices found");
        return false;
      }

      // Try to connect to the first available device
      for (UsbDevice device in devices) {
        _statusStreamController.add(
          "Trying device: ${device.productName ?? 'Unknown'}",
        );

        try {
          _port = await device.create();

          if (_port == null) {
            continue; // Try next device
          }

          bool openResult = await _port!.open();
          if (!openResult) {
            await _port!.close();
            _port = null;
            continue; // Try next device
          }

          // Configure the port with more explicit settings
          await Future.delayed(
            Duration(milliseconds: 100),
          ); // Give time for device to settle

          try {
            await _port!.setDTR(true);
            await Future.delayed(Duration(milliseconds: 10));
            await _port!.setRTS(true);
            await Future.delayed(Duration(milliseconds: 10));

            await _port!.setPortParameters(
              115200,
              UsbPort.DATABITS_8,
              UsbPort.STOPBITS_1,
              UsbPort.PARITY_NONE,
            );
            await Future.delayed(Duration(milliseconds: 100));
          } catch (e) {
            _statusStreamController.add("Port configuration failed: $e");
            await _port!.close();
            _port = null;
            continue; // Try next device
          }

          // Test the connection with a small data read
          try {
            _subscription = _port!.inputStream?.listen(
              _onDataReceived,
              onError: (error) {
                _statusStreamController.add("Data stream error: $error");
                disconnect();
              },
            );

            _connectionState = PanelConnectionState.connected;
            _statusStreamController.add(
              "Connected to device: ${device.productName ?? 'USB Device'}",
            );

            // Start the communication process
            _startCommunicationProcess();
            return true;
          } catch (e) {
            _statusStreamController.add("Stream setup failed: $e");
            await _port!.close();
            _port = null;
            continue; // Try next device
          }
        } catch (e) {
          _statusStreamController.add("Device connection failed: $e");
          if (_port != null) {
            try {
              await _port!.close();
            } catch (_) {}
            _port = null;
          }
          continue; // Try next device
        }
      }

      _statusStreamController.add("Failed to connect to any device");
      return false;
    } catch (e) {
      _statusStreamController.add("Connection error: $e");
      return false;
    }
  }

  void _startCommunicationProcess() {
    _connectionState = PanelConnectionState.processing;
    _totalValidEvtLogCnt = 0;
    _pktTxCnt = 0;
    _pktRxCnt = 0;
    // _logEvtSearchNumber = 200;
    _stopEvtLogRead = false;
    _processState = ProcessState.reqNwkPkt;
    _mainProcessState = ProcessState.reqNwkPkt;

    _processTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_connectionState != PanelConnectionState.processing) {
        timer.cancel();
        return;
      }
      _panelProcess();
    });
  }

  void _panelProcess() {
    switch (_mainProcessState) {
      case ProcessState.reqNwkPkt:
        _reqNwkPkt();
        break;
      case ProcessState.reqAccessKey:
        _reqAccessKey();
        break;
      case ProcessState.dummyPktSend:
        _sendDummyPkt();
        break;
      case ProcessState.readEvtLog:
        _reqEvtLog();
        break;
      case ProcessState.reqRspWaitState:
        // Waiting for response - check for timeout
        _responseTimer ??= Timer(Duration(seconds: 10), () {
          _statusStreamController.add("Response timeout - retrying...");
          _mainProcessState = ProcessState.reqNwkPkt;
          _responseTimer = null;
        });
        break;
    }
  }

  void _reqNwkPkt() {
    _statusStreamController.add("Requesting network packet...");

    List<int> nwkReqPkt = [
      0xfe,
      0x01,
      0x00,
      0x04,
      _pktTxCnt & 0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      ...List.filled(200, 0x00),
      0xb1,
      0x4a,
      0xfd,
    ];

    _sendData(Uint8List.fromList(nwkReqPkt));
    _processState = ProcessState.reqNwkPkt;
    _mainProcessState = ProcessState.reqRspWaitState;
    _pktTxCnt++;
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void _reqAccessKey() {
    _statusStreamController.add("Requesting access key...");

    List<int> accessKeyReqPkt = [
      0xfe,
      0x01,
      0x00,
      0x01,
      (_pktTxCnt & 0xFF),
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x83,
      0x00,
      0x04,
      0x04,
      0x31,
      0x39,
      0x37,
      0x34,
      ...List.filled(195, 0x00),
      0x70,
      0x2c,
      0xfd,
    ];

    _sendData(Uint8List.fromList(accessKeyReqPkt));
    _processState = ProcessState.reqAccessKey;
    _mainProcessState = ProcessState.reqRspWaitState;
    _pktTxCnt++;
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void _sendDummyPkt() {
    _statusStreamController.add("Sending dummy packet for access key...");

    _logEvtSearchNumber--;
    List<int> evtLogPayloadData = [
      logEvtSearchMethod,
      (_logEvtSearchNumber >> 24) & 0xff,
      (_logEvtSearchNumber >> 16) & 0xff,
      (_logEvtSearchNumber >> 8) & 0xff,
      _logEvtSearchNumber & 0xff,
    ];

    List<int> framePacket = _frameTheTxCommPkt(
      scriptDest,
      scriptOrig,
      PacketType.nrm.value,
      _pktTxCnt & 0xFF,
      _pktRxCnt & 0xFF,
      logNw,
      logNd,
      logSnd,
      logMo,
      logMd,
      logSk,
      logCmd,
      evtLogPayloadData,
      5,
    );

    _sendData(Uint8List.fromList(framePacket));
    _pktTxCnt++;
    _processState = ProcessState.dummyPktSend;
    _mainProcessState = ProcessState.reqRspWaitState;
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void _reqEvtLog() {
    if (_pktTxCnt >= 255) {
      _pktTxCnt = 0;
    }

    List<int> evtLogPayloadData = [
      logEvtSearchMethod,
      (_logEvtSearchNumber >> 24) & 0xff,
      (_logEvtSearchNumber >> 16) & 0xff,
      (_logEvtSearchNumber >> 8) & 0xff,
      _logEvtSearchNumber & 0xff,
    ];

    List<int> framePacket = _frameTheTxCommPkt(
      scriptDest,
      scriptOrig,
      PacketType.nrm.value,
      _pktTxCnt & 0xFF,
      _pktRxCnt & 0xFF,
      logNw,
      logNd,
      logSnd,
      logMo,
      logMd,
      logSk,
      logCmd,
      evtLogPayloadData,
      5,
    );

    _sendData(Uint8List.fromList(framePacket));

    if (_logEvtSearchNumber <= 0) {
      _stopEvtLogRead = true;
    } else {
      _logEvtSearchNumber--;
    }

    _pktTxCnt++;
    _processState = ProcessState.readEvtLog;
    _mainProcessState = ProcessState.reqRspWaitState;
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  List<int> _frameTheTxCommPkt(
    int des,
    int orig,
    int pkttyp,
    int txp,
    int rxp,
    int nwk,
    int node,
    int subnode,
    int module,
    int mode,
    int sock,
    int cmd,
    List<int> data,
    int dataLe,
  ) {
    if (dataLe > 0) {
      List<int> frameBuffer = List.filled(216, 0);

      frameBuffer[0] = frameSot;
      frameBuffer[1] = des;
      frameBuffer[2] = orig;
      frameBuffer[3] = pkttyp;
      frameBuffer[4] = txp;
      frameBuffer[5] = rxp;
      frameBuffer[6] = nwk;
      frameBuffer[7] = node;
      frameBuffer[8] = subnode;
      frameBuffer[9] = module;
      frameBuffer[10] = mode;
      frameBuffer[11] = sock;
      frameBuffer[12] = cmd;

      for (int i = 0; i < dataLe && i < data.length; i++) {
        frameBuffer[13 + i] = data[i];
      }

      int crc = _toolsFletcherChecksum(frameBuffer.sublist(0, 213));
      frameBuffer[213] = (crc >> 8) & 0xFF;
      frameBuffer[214] = crc & 0xFF;
      frameBuffer[215] = frameEot;

      return frameBuffer;
    }
    return [];
  }

  int _toolsFletcherChecksum(List<int> buffer) {
    int length = buffer.length;
    int checksum = 0;

    if (length > 0) {
      int sum1 = 0;
      int sum2 = 0;

      for (int i = 0; i < length; i++) {
        sum1 = (sum1 + buffer[i]) % 255;
        sum2 = (sum2 + sum1) % 255;
      }

      int chk1 = (255 - ((sum1 + sum2) % 255)) & 0xFF;
      int chk2 = (255 - ((sum1 + chk1) % 255)) & 0xFF;

      checksum = (chk1 << 8) | chk2;
    }

    return checksum;
  }

  void _sendData(Uint8List data) async {
    if (_port != null) {
      try {
        String hexString = data
            .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(' ');
        print('writing data: $hexString');
        await _port!.write(data);
        await Future.delayed(
          Duration(milliseconds: 50),
        ); // Small delay between writes
      } catch (e) {
        _statusStreamController.add("Send error: $e");
        disconnect();
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    if (data.length >= 216) {
      String hexString = data
          .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      print('DEBUG: Received raw data: $hexString');
      print('DEBUG: Current Process State: $_processState');
      print('DEBUG: Current Main Process State: $_mainProcessState');
      _rxFrameProcess(data, data.length);
    } else {
      print('DEBUG: Received partial packet: ${data.length} bytes');
      _statusStreamController.add(
        "Received partial packet: ${data.length} bytes",
      );
    }
  }

  void _parseAndUpdateRxCommPkt(Uint8List rxFrame, int rxFrameLen) {
    if (rxFrame.length >= 216) {
      _commFrame.sot = rxFrame[0];
      _commFrame.dest = rxFrame[1];
      _commFrame.origin = rxFrame[2];
      _commFrame.pktTyp = rxFrame[3];
      _commFrame.txp = rxFrame[4];
      _commFrame.rxp = rxFrame[5];
      _commFrame.payload.header.nwk = rxFrame[6];
      _commFrame.payload.header.nod = rxFrame[7];
      _commFrame.payload.header.subnod = rxFrame[8];
      _commFrame.payload.header.module = rxFrame[9];
      _commFrame.payload.header.mode = rxFrame[10];
      _commFrame.payload.header.sck = rxFrame[11];
      _commFrame.payload.header.cmd = rxFrame[12];

      for (int i = 0; i < 200; i++) {
        _commFrame.payload.data[i] = rxFrame[13 + i];
      }

      _commFrame.crc = (rxFrame[213] << 8) | rxFrame[214];
      _commFrame.eot = rxFrame[215];
    }
  }

  void _rxFrameProcess(Uint8List rxFrame, int rxFrameLen) {
    _parseAndUpdateRxCommPkt(rxFrame, rxFrameLen);
    print('DEBUG: Processing frame - Packet Type: ${_commFrame.pktTyp}');
    print('DEBUG: Frame Mode: ${_commFrame.payload.header.mode}');
    print('DEBUG: Frame Command: ${_commFrame.payload.header.cmd}');

    // Cancel response timer since we received a response
    _responseTimer?.cancel();
    _responseTimer = null;

    switch (_processState) {
      case ProcessState.reqNwkPkt:
        print('DEBUG: Processing Network Packet Request');
        if (_commFrame.pktTyp == PacketType.nwk.value) {
          _statusStreamController.add("Network packet received");
          _processState = ProcessState.reqAccessKey;
          _mainProcessState = ProcessState.reqAccessKey;
          print('DEBUG: Network packet received, transitioning to Access Key Request');
        } else {
          _statusStreamController.add("Network packet NACK received");
          _processState = ProcessState.reqNwkPkt;
          _mainProcessState = ProcessState.reqNwkPkt;
          print('DEBUG: Network packet NACK received, retrying Network Request');
        }
        break;

      case ProcessState.reqAccessKey:
        print('DEBUG: Processing Access Key Request');
        if (_commFrame.pktTyp == PacketType.ack.value) {
          _statusStreamController.add("Access key ACK received");
          _processState = ProcessState.dummyPktSend;
          _mainProcessState = ProcessState.dummyPktSend;
          print('DEBUG: Access key ACK received, transitioning to Dummy Packet Send');
        } else {
          _statusStreamController.add("Access key NACK received");
          _processState = ProcessState.reqNwkPkt;
          _mainProcessState = ProcessState.reqNwkPkt;
          print('DEBUG: Access key NACK received, restarting from Network Request');
        }
        break;

      case ProcessState.dummyPktSend:
        print('DEBUG: Processing Dummy Packet Send');
        if (_commFrame.pktTyp == PacketType.nrm.value &&
            _commFrame.payload.header.mode == InstructMode.dbStatusInstruct.value) {
          List<int> asciiList = _commFrame.payload.data.sublist(1, 5);
          String asciiStr = String.fromCharCodes(asciiList);
          print('DEBUG: Dummy packet response - ASCII: $asciiStr');

          if (asciiStr == '1974') {
            _statusStreamController.add("Access key verified - Starting log retrieval");
            _processState = ProcessState.readEvtLog;
            _mainProcessState = ProcessState.readEvtLog;
            print('DEBUG: Access key verified, starting log retrieval');
          } else {
            _statusStreamController.add("Invalid access key");
            _processState = ProcessState.reqNwkPkt;
            _mainProcessState = ProcessState.reqNwkPkt;
            print('DEBUG: Invalid access key, restarting from Network Request');
          }
        } else {
          _statusStreamController.add("Dummy packet NACK received");
          _processState = ProcessState.reqNwkPkt;
          _mainProcessState = ProcessState.reqNwkPkt;
          print('DEBUG: Dummy packet NACK received, restarting from Network Request');
        }
        break;

      case ProcessState.readEvtLog:
        print('DEBUG: Processing Event Log');
        if (_commFrame.pktTyp == PacketType.nrm.value &&
            _commFrame.payload.header.mode == RequestMode.dbSetupReq.value &&
            _commFrame.payload.header.cmd == eventStatusCmd) {
          print('DEBUG: Valid event log packet received, processing...');
          _processEventLog(_commFrame.payload.data);
          _processState = ProcessState.readEvtLog;
          _mainProcessState = ProcessState.readEvtLog;
        } else {
          print('DEBUG: Invalid event log packet - Type: ${_commFrame.pktTyp}, Mode: ${_commFrame.payload.header.mode}, Cmd: ${_commFrame.payload.header.cmd}');
          _statusStreamController.add("Invalid event log packet");
        }
        break;

      case ProcessState.reqRspWaitState:
        print('DEBUG: In Response Wait State');
        break;
    }

    _pktRxCnt = _commFrame.txp;
    print('DEBUG: Updated packet RX count: $_pktRxCnt');

    if (_stopEvtLogRead) {
      print('DEBUG: Log reading completed. Total valid logs: $_totalValidEvtLogCnt');
      _statusStreamController.add("Completed reading logs. Total: $_totalValidEvtLogCnt");
      disconnect();
    }
  }

  void _processEventLog(List<int> evtData) {
    List<int> timestamp = evtData.sublist(17, 21);
    int timestampDecimal = timestamp[3] | (timestamp[2] << 8) | (timestamp[1] << 16) | (timestamp[0] << 24);
    print('DEBUG: Processing log with timestamp: $timestampDecimal');

    // Comment out timestamp validation
    // if (timestampDecimal != 0x00) {
    _totalValidEvtLogCnt++;
    print('DEBUG: Processing log - Total count: $_totalValidEvtLogCnt');

    // Use current time if timestamp is invalid
    DateTime eventTime = timestampDecimal != 0x00 
        ? TimestampConverter.clockTimeFromTimeStamp(timestampDecimal)
        : DateTime.now();
    print('DEBUG: Event time: $eventTime');

    int eventId = evtData[4] | (evtData[3] << 8) | (evtData[2] << 16) | (evtData[1] << 24);
    print('DEBUG: Event ID: $eventId');

    String evtTextAscii;
    List<int> evtText = evtData.sublist(47);
    if (evtText.length > 1 && evtText[1] != 0x00) {
        List<int> evtTextValue = evtText.sublist(2, evtText[1] + 2);
        evtTextAscii = String.fromCharCodes(evtTextValue);
        print('DEBUG: Event text: $evtTextAscii');
    } else {
        evtTextAscii = "NO-TEXT";
        print('DEBUG: No event text found');
    }

    String panelSource;
    if (evtData[5] == 0 && evtData[6] == 0 && evtData[7] == 0) {
        panelSource = "SOLAR";
    } else if (evtData[5] == 1 && evtData[6] == 1 && evtData[7] == 0) {
        panelSource = "Panel No.${evtData[5]}";
    } else {
        panelSource = "Panel ${evtData[5]}.${evtData[6]}.${evtData[7]}";
    }
    print('DEBUG: Panel source: $panelSource');

    LogModel logModel = LogModel(
        panelText: panelSource,
        eventId: (eventId + 1).toString(),
        eventDateTime: eventTime,
        panelNo: evtData[5].toString(),
        lBusNo: evtData[6].toString(),
        moduleNo: evtData[7].toString(),
        eventStatus: EventConstants.getEventStatusValue(evtData[15]),
        eventClass: EventConstants.getEventClassValue(evtData[12]),
        eventSource: panelSource,
        eventType: EventConstants.getEventType(evtData[14]),
        eventSubType: EventConstants.getEventDescription(evtData[14], evtData[16]),
        identifier: EventConstants.getEventIdentifier(evtData[14], evtData[34], evtData[35], evtData[36]),
        text: evtTextAscii,
    );

    print('DEBUG: Adding log to stream - Event Type: ${logModel.eventType}');
    _logStreamController.add(logModel);
    _statusStreamController.add("Log $_totalValidEvtLogCnt received: ${logModel.eventType}");
    // } else {
    //     print('DEBUG: Skipping log due to invalid timestamp (0x00)');
    // }
  }

  void disconnect() async {
    _connectionState = PanelConnectionState.notConnected;
    _processTimer?.cancel();
    _responseTimer?.cancel();
    await _subscription?.cancel();
    if (_port != null) {
      try {
        await _port!.close();
      } catch (e) {
        // Ignore close errors
      }
      _port = null;
    }
    _statusStreamController.add("Disconnected");
  }

  void dispose() {
    disconnect();
    _logStreamController.close();
    _statusStreamController.close();
  }
}
