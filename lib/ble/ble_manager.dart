import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'ble_frame.dart';
import 'aes_key.dart' as aes;
import 'ble_process.dart';
import 'dart:typed_data';

const int BLE_FAILED = 0;
const int BLE_SUCCESS = 1;

const int enBLE_SOF_MSB = 0xAA;
const int enBLE_SOF_LSB = 0x55;
const int enBLE_EOF_MSB = 0xEE;
const int enBLE_EOF_LSB = 0xBB;

const int enBLE_SOF_MSB_POS = 0;
const int enBLE_SOF_LSB_POS = 1;
const int enBLE_CMD_MSB_POS = 2;
const int enBLE_CMD_LSB_POS = 3;
const int enBLE_TOF_POS = 4;
const int enBLE_DATA_LEN_MSB_POS = 5;
const int enBLE_DATA_LEN_LSB_POS = 6;
const int enBLE_DATA_POS = 7;

const int BLE_FRAME_FILED_SIZE = 11; // total overhead for frame

enum BleStates {
  REQ_ENCY_KEY,
  SEND_AUTHN_MSG,
  PROCESS_PANEL_EVT_LOG_READ,
  PROCESS_WAIT_RSP,
  IDLE,
  // add other states
}

enum DeviceConnectState { notConnected, registerNotifyHandler, running }

enum OtaProcessState {
  sendNetworkPacket,
  sendPollPacket,
  sendAccessKeyPacket,
  sendControlCmdPacket,
  sendStopCntrlCmdPkt,
  sendContinuousPollPacket,
  otaWaitRsp,
  notInUse,
}

const String BLE_AUTHN_MSG = "TECHNOSWITCH-AUTH-APP";

class BleManager {
  int u8TxPktCnt = 0;
  int u8RxPktCnt = 0;
  // BLE state variables
  BleStates bleCurrentState = BleStates.REQ_ENCY_KEY;
  BleStates bleStateMachineState = BleStates.REQ_ENCY_KEY;

  Map<String, dynamic> bleAESKey = {};
  BleRxFrame bleRxFrame = BleRxFrame();
  int txData = 0;

  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  final Uuid serviceUuid = Uuid.parse("D973F2F0-B19E-11E2-9E96-0800200C9A66");
  final Uuid notifyUuid = Uuid.parse("D973F2F1-B19E-11E2-9E96-0800200C9A66");
  final Uuid writeUuid = Uuid.parse("D973F2F2-B19E-11E2-9E96-0800200C9A66");

  DiscoveredDevice? selectedDevice;
  QualifiedCharacteristic? notifyChar;
  QualifiedCharacteristic? writeChar;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  // Prevent duplicate poll writes while waiting for notify
  bool _pollInFlight = false;
  int receivedPollCount = 0;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  bool _connectedOnce = false;
  bool _isGattConnected = false;
  StreamSubscription<List<int>>? _notifySub;

  // BLE state machine
  late BleProcess bleProcess;

  BleManager() {
    flutterReactiveBle.logLevel = LogLevel.verbose;
    bleProcess = BleProcess(this);
  }

  ValueNotifier<String> get processDesc => bleProcess.processDesc;

  bool get isConnected => _isGattConnected;

  /// SCAN & CONNECT
  Future<void> connectToKnownDevice({
    int maxRetries = 3,
    required DiscoveredDevice device,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      print("BLE connect attempt $attempt / $maxRetries");

      try {
        selectedDevice = device;
        await _connectOnce(device);
        print("BLE connected successfully");
        return; // ✅ SUCCESS
      } catch (e) {
        print("BLE attempt $attempt failed: $e");

        await _notifySub?.cancel();
        await _connectionSub?.cancel();

        _notifySub = null;
        _connectionSub = null;
        _connectedOnce = false;
        _isGattConnected = false;
        selectedDevice = null;

        // ---- RESET PROTOCOL STATE ----
        bleCurrentState = BleStates.REQ_ENCY_KEY;
        bleStateMachineState = BleStates.REQ_ENCY_KEY;
        bleAESKey.clear();
        _pollInFlight = false;
        receivedPollCount = 0;

        if (attempt >= maxRetries) {
          print("Max BLE retry attempts reached");
          processDesc.value =
              "Max BLE retry attempts reached, please scan again and connect.";
          rethrow;
        }

        // BLE stack cooldown (important)
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _refreshGattIfNeeded(String deviceId) async {
    //Only works in Android
    if (!Platform.isAndroid) return;

    try {
      print("🔄 Clearing GATT cache...");
      await flutterReactiveBle.clearGattCache(deviceId);
      print("✅ GATT cache cleared");
    } catch (e) {
      print("⚠️ GATT cache clear failed: $e");
    }
  }

  Future<void> _connectOnce(DiscoveredDevice device) async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan, // still required on Android 12+
      Permission.location,
    ].request();

    if (await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      throw Exception("Bluetooth permissions not granted");
    }

    final Completer<void> connectedCompleter = Completer();

    _connectionSub = flutterReactiveBle
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) async {
            print("Connection state: ${update.connectionState}");

            if (update.connectionState == DeviceConnectionState.connected) {
              _isGattConnected = true;

              if (_connectedOnce) return;
              _connectedOnce = true;

              //Let Android finish bonding internally
              await Future.delayed(const Duration(milliseconds: 300));

              //GATT CACHE REFRESH (Android only)
              await _refreshGattIfNeeded(device.id);

              //Small safety delay
              await Future.delayed(const Duration(milliseconds: 200));

              notifyChar = QualifiedCharacteristic(
                characteristicId: notifyUuid,
                serviceId: serviceUuid,
                deviceId: device.id,
              );

              writeChar = QualifiedCharacteristic(
                characteristicId: writeUuid,
                serviceId: serviceUuid,
                deviceId: device.id,
              );

              await flutterReactiveBle.requestMtu(
                deviceId: device.id,
                mtu: 247,
              );

              bleProcess.deviceConnectState =
                  DeviceConnectState.registerNotifyHandler;

              Get.find<BleLogController>().enableNotify();

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.complete();
              }
            }

            if (update.connectionState == DeviceConnectionState.disconnected) {
              _isGattConnected = false;
              _connectedOnce = false;

              await _notifySub?.cancel();
              _notifySub = null;

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.completeError(
                  Exception("Disconnected during connection"),
                );
                processDesc.value = "Disconnected during connection";
              }
            }
          },
          onError: (e) {
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.completeError(e);
            }
          },
        );

    await connectedCompleter.future;
  }

  /// REGISTER NOTIFICATIONS
  Future<void> registerNotifyHandler() async {
    print("Register notify handler");

    if (_notifySub != null) return;

    if (!isConnected) {
      print("Device disconnected before notification start");
      return;
    }

    // Subscribe to notifications
    _notifySub = flutterReactiveBle
        .subscribeToCharacteristic(notifyChar!)
        .listen(
          (data) => notificationHandler(Uint8List.fromList(data)),
          onError: (e) {
            print("Notification subscription error: $e");
          },
        );

    print("Listening for notifications...");
    await Future.delayed(const Duration(milliseconds: 300));
    print("---Notification handler registered----");
    bleProcess.requestENCKey();
  }

  /// DISCONNECT
  Future<void> disconnectHandler() async {
    print("Disconnecting device...");

    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _notifySub = null;
    _connectionSub = null;

    _isGattConnected = false;
    _connectedOnce = false;
    selectedDevice = null;
  }

  /// SHUTDOWN
  Future<void> shutdown() async {
    print("Shutdown BLE");
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _scanSub = null;
    _notifySub = null;
    _connectionSub = null;

    _isGattConnected = false;
    _connectedOnce = false;
  }

  // ----------------------
  // Notification Handler
  // ----------------------
  Future<void> notificationHandler(Uint8List data) async {
    if (bleProcess.isOtaCompleted ||
        otaProcessState == OtaProcessState.notInUse) {
      print("RX ignored after OTA completion");
      return;
    }
    print(
      "TX/RX: --------notify received----- RX TIME:${DateTime.now().toIso8601String()}",
    );
    txData = 1;
    bleProcess.cancelRxTimeout();
    // Any notify received implies previous write completed → allow next poll
    _pollInFlight = false;
    if (bleCurrentState == BleStates.REQ_ENCY_KEY) {
      print("Encryption key req response");
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);
      print(
        "SOF:${bleRxFrame.sof},${bleRxFrame.cmd},${bleRxFrame.tof},${bleRxFrame.payloadLen},${bleRxFrame.payload},${bleRxFrame.crc},${bleRxFrame.calculatedCrc},${bleRxFrame.crc},${bleRxFrame.eof}",
      );
      if (bleValidateRxFrame(bleRxFrame)) {
        print("Validation success");
        bleAESKey["AES_KEY"] = bleRxFrame.payload;
        print("Received key: ${bleAESKey['AES_KEY']}");

        await Future.delayed(Duration(milliseconds: 300));
        bleStateMachineState = BleStates.SEND_AUTHN_MSG;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;

        print("handler bleStateMachineState: $bleStateMachineState");
        bleProcess.sendAuthPacket();
      } else {
        print("Validation failed");
      }
    } else if (bleCurrentState == BleStates.SEND_AUTHN_MSG) {
      print("Authn msg response");
      // Uint8List decryptedData = aes.aesDecrypt(bleAESKey["AES_KEY"], data);
      bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        print("AUTH KEY Validation success");
        await Future.delayed(Duration(seconds: 1));
        bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        print("Current state: $bleStateMachineState");
        // Send Network Packet
        Get.find<BleLogController>().sendNetworkPacket();
      } else {
        print("Validation failed");
      }
    } else {
      receivedPollCount++;
      print("The Received RX count is : $receivedPollCount");
      // Uint8List decryptedData = aes.aesDecrypt(bleAESKey["AES_KEY"], data);
      bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        await bleProcess.bleRxFrameProcess(bleRxFrame);
      } else {
        print(
          "<<<<<<<<<<<<<<<< RECEIVED FRAME VALIDATION FAILED >>>>>>>>>>>>>>>>>>>>>>>>>>",
        );
      }
    }
  }

  // ----------------------
  // Function to register notifications
  // ----------------------
  void registerNotificationListener(characteristic) {
    characteristic.value.listen((data) async {
      await notificationHandler(data);
    });
  }

  // other BLE functions: connect, write, send frame, etc.

  /// HANDLERS FOR BLE STATE MACHINE
  OtaProcessState otaProcessState = OtaProcessState.sendNetworkPacket;

  int toolsFletcherChecksum(List<int> buffer) {
    int length = buffer.length;
    if (length == 0) return 0;

    int sum1 = 0;
    int sum2 = 0;

    for (var b in buffer) {
      sum1 = (sum1 + b) % 255;
      sum2 = (sum2 + sum1) % 255;
    }

    int chk1 = (255 - ((sum1 + sum2) % 255)) & 0xFF;
    int chk2 = (255 - ((sum1 + chk1) % 255)) & 0xFF;

    return (chk1 << 8) | chk2;
  }

  List<int> convertToBytes(dynamic data) {
    if (data is List<int>) return data;
    if (data is String) return data.codeUnits;
    throw Exception("Unsupported data type for conversion to bytes");
  }

  static crcCcittFalse(
    List<int> data, {
    int poly = 0x1021,
    int initVal = 0xFFFF,
  }) {
    int crc = initVal;

    for (int byte in data) {
      crc ^= (byte << 8) & 0xFFFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc & 0xFFFF;
  }

  List<int> bleFrameFormat(
    int cmd,
    int typeOfFrame,
    int dataLen,
    List<int> data,
  ) {
    if (cmd <= 0 || typeOfFrame <= 0 || dataLen <= 0 || data.isEmpty) {
      return [];
    }

    List<int> frameBuff = List.filled(dataLen + BLE_FRAME_FILED_SIZE, 0);

    // Start of frame
    frameBuff[enBLE_SOF_MSB_POS] = enBLE_SOF_MSB;
    frameBuff[enBLE_SOF_LSB_POS] = enBLE_SOF_LSB;

    // Command
    frameBuff[enBLE_CMD_MSB_POS] = (cmd >> 8) & 0xFF;
    frameBuff[enBLE_CMD_LSB_POS] = cmd & 0xFF;

    // Type of frame
    frameBuff[enBLE_TOF_POS] = typeOfFrame;

    // Data length
    frameBuff[enBLE_DATA_LEN_MSB_POS] = (dataLen >> 8) & 0xFF;
    frameBuff[enBLE_DATA_LEN_LSB_POS] = dataLen & 0xFF;

    // Copy actual data
    for (int i = 0; i < dataLen; i++) {
      frameBuff[enBLE_DATA_POS + i] = data[i];
    }

    // CRC
    int crc = crcCcittFalse(frameBuff.sublist(0, enBLE_DATA_POS + dataLen));
    frameBuff[enBLE_DATA_POS + dataLen] = (crc >> 8) & 0xFF;
    frameBuff[enBLE_DATA_POS + 1 + dataLen] = crc & 0xFF;

    // End of frame
    frameBuff[enBLE_DATA_POS + 2 + dataLen] = enBLE_EOF_MSB;
    frameBuff[enBLE_DATA_POS + 3 + dataLen] = enBLE_EOF_LSB;

    return frameBuff;
  }

  Future<void> sendData(Uint8List frame, {bool encrypt = true}) async {
    if (!isConnected || writeChar == null) return;

    try {
      Uint8List dataToSend;

      //Encryption and Decryption is disabled
      // Encrypt if in proper state
      // await Future.delayed(const Duration(milliseconds: 300));
      // if (encrypt && (bleCurrentState.index > BleStates.REQ_ENCY_KEY.index)) {
      //   dataToSend = aes.aesEncrypt(bleAESKey["AES_KEY"], frame);
      //   print("Sending encrypted data: length ${dataToSend.length}");
      // } else {
      //   dataToSend = frame;
      //   print("Sending plain data: length ${dataToSend.length}");
      // }

      dataToSend = frame;
      print("Sending plain data: length ${dataToSend.length}");

      print(
        "::::::Data Written:::$dataToSend::TX Time${DateTime.now().toIso8601String()}}",
      );
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: dataToSend,
      );
    } catch (e) {
      print("Send data failed: $e");
    }
  }

  Future<void> sendSmallDataFrame(
    int cmd,
    int length,
    List<int> data, {
    bool encrypt = true,
  }) async {
    if (writeChar == null) return;

    List<int> frame = bleFrameFormat(
      cmd,
      0x01,
      length,
      data,
    ); // 0x01 is small frame type
    Uint8List frameBytes = aes.convertToBytes(frame);

    try {
      //Encrption and Decryption is disabled
      // if (encrypt) {
      //   List<int> encryptedData = aes.aesEncrypt(
      //     bleAESKey["AES_KEY"],
      //     frameBytes,
      //   );
      //   // await Future.delayed(const Duration(milliseconds: 300));
      //   print(
      //     "::::::Data Written:::$encryptedData::TX Time${DateTime.now().toIso8601String()}}",
      //   );
      //   await flutterReactiveBle.writeCharacteristicWithResponse(
      //     writeChar!,
      //     value: encryptedData,
      //   );
      // } else {
      //   print("::::::Data Written:::::");
      //   await flutterReactiveBle.writeCharacteristicWithResponse(
      //     writeChar!,
      //     value: frameBytes,
      //   );
      // }

      print("::::::Data Written:::::");
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: frameBytes,
      );
    } catch (e) {
      print("Send frame failed: $e");
    }
  }

  Future<void> sendAesKeyReq() async {
    // Build BLE frame (same as Python: ble_frame_format(0x1000, 0x01, 1, [0x00]))
    List<int> reqFrame = bleFrameFormat(0x1000, 0x01, 1, [0x00]);

    // Convert to Uint8List
    Uint8List reqFrameBytes = aes.convertToBytes(reqFrame);

    print("Framed key req Frame: $reqFrame after bytes convert $reqFrameBytes");

    print("TX/RX: TRANSMIT: enc key request : $reqFrameBytes");

    // Send using BLE
    await sendData(reqFrameBytes);
  }

  Future<void> sendAuthnMsg() async {
    if (writeChar == null) return;

    // Convert message string to bytes
    List<int> msgBytes = BLE_AUTHN_MSG.codeUnits;

    // Create BLE frame
    List<int> authnMsgFrame = bleFrameFormat(
      0x1000,
      0x02,
      msgBytes.length,
      msgBytes,
    );

    // Convert to Uint8List for BLE
    Uint8List frameBytes = Uint8List.fromList(authnMsgFrame);

    print("Framed Authn Msg: $authnMsgFrame");
    print("TX/RX: TRANSMIT: Auth Frame bytes: $frameBytes");

    // Send using your sendData function which handles encryption
    await sendData(frameBytes);
  }

  Future<void> sendNetworkPacket() async {
    u8TxPktCnt = 0;

    List<int> u8Pkt = List.filled(216, 0);
    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x04; // pkt type
    u8Pkt[4] = 0x00; // tx pkt num
    u8Pkt[5] = 0x00; // rx pkt num
    u8Pkt[6] = 0x05; // network number
    u8Pkt[11] = 0x02; // socket number
    u8Pkt[12] = 0x01;

    // Checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));
    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Network Packet time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );
    // print(u8Pkt.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' '));

    await sendSmallDataFrame(0x1000, 216, u8Pkt); // see step 4
  }

  Future<void> sendPollPacket() async {
    if (bleProcess.isOtaCompleted ||
        otaProcessState == OtaProcessState.notInUse) {
      print("Poll blocked (OTA completed / notInUse)");
      return;
    }
    // Guard: skip if a previous poll write is still awaiting notify
    if (_pollInFlight) {
      print("Skipping poll: previous write still in-flight");
      return;
    }
    _pollInFlight = true;
    // await Future.delayed(Duration(milliseconds: 200));
    // Create the 216-byte poll packet
    List<int> pollPkt = List.filled(216, 0);
    pollPkt[0] = 0xFE;
    pollPkt[1] = 0x01;
    pollPkt[2] = 0x00;

    // Update packet numbers
    pollPkt[4] = (u8TxPktCnt + 1) & 0xFF; // tx pkt num
    pollPkt[5] = (u8RxPktCnt & 0xFF); // rx pkt num
    print(
      "Sending poll pkt rx cnt pollPkt[5] value:${pollPkt[5]},u8RxPktCnt:${u8RxPktCnt}",
    );
    // Network + socket
    pollPkt[6] = 0x00; // network number
    pollPkt[11] = 0x00; // socket number

    // Compute checksum over first 213 bytes
    int checksum = toolsFletcherChecksum(pollPkt.sublist(0, 216 - 3));

    pollPkt[213] = (checksum >> 8) & 0xFF;
    pollPkt[214] = checksum & 0xFF;
    pollPkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Poll Packet time: ${DateTime.now().toIso8601String()}, packet: ${pollPkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   pollPkt
    //       .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, pollPkt);
  }

  // Allow BleProcess to clear in-flight on timeout
  void resetPollInFlight() {
    _pollInFlight = false;
  }

  Future<void> sendAccessKeyPkt() async {
    u8TxPktCnt += 1;

    // Create 216-byte packet
    List<int> pkt = List.filled(216, 0);
    pkt[0] = 0xFE;
    pkt[1] = 0x01;
    pkt[2] = 0x00;

    pkt[3] = 0x01; // pkt type
    pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    pkt[6] = 0x00; // network number
    pkt[10] = 0x83; // mode
    pkt[11] = 0x00; // socket number
    pkt[12] = 0x04;
    pkt[13] = 0x04;

    // "1974"
    pkt[14] = 0x31; // '1'
    pkt[15] = 0x39; // '9'
    pkt[16] = 0x37; // '7'
    pkt[17] = 0x34; // '4'

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(pkt.sublist(0, 216 - 3));

    pkt[213] = (checksum >> 8) & 0xFF;
    pkt[214] = checksum & 0xFF;
    pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Access Key Packet time: ${DateTime.now().toIso8601String()}, packet: ${pkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ').toString()}",
    );
    // print(
    //   pkt
    //       .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' ')
    //       .toString(),
    // );

    await sendSmallDataFrame(0x1000, 216, pkt);
  }

  Future<void> sendStartCntrlCmdPkt() async {
    // Update global counters
    u8TxPktCnt += 1;

    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);
    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x83; // mode
    u8_pkt[11] = 0x04; // socket number
    u8_pkt[12] = 0x0B; // command byte 1
    u8_pkt[13] = 0x03; // command byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Start Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendStopCntrlCmdPkt() async {
    // Update global counters
    u8TxPktCnt += 1;

    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);
    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x83; // mode
    u8_pkt[11] = 0x04; // socket number
    u8_pkt[12] = 0x0B; // command byte 1
    u8_pkt[13] = 0x03; // command byte 2
    u8_pkt[14] = 0x01; // Event Buffer Mode -> Stop

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Stop Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }
}
