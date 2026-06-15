import 'dart:async';
import 'dart:typed_data';
import 'package:techno_switch_solar_app/ble/ble_crypto.dart';
import 'package:techno_switch_solar_app/ble/ble_encryption_config.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;
import 'package:techno_switch_solar_app/utils/storage/encryption_key_store.dart';
import '../../services/app_services.dart';

class BleNotifyDataHandler extends GetxController {
  final DataTransferManager _dataTransferManager = DataTransferManager();

  int _pktTxCnt = 0;
  int _pktRxCnt = 0;
  int _lastFeaturePacketCounter = 0;
  int pollPacketCount = 0;
  int _pollPacketCountAfterControlRes = 0;
  String? _storedPasskey;
  bool passkeyAccepted = false;
  bool _controlResEventReportSent = false;
  bool _controlResEventReportValidResponseReceived = false;
  bool _passkeySent = false;
  Timer? _continuousPollTimer;
  Timer? _pollPacketResponseTimer;
  int lastKnownRxCounter = 0;

  final Rx<BleStateMachine> currentBleState = BleStateMachine.none.obs;
  final Rx<EncryptionDecryptionState> encryptionDecryptionState =
      EncryptionDecryptionState.disabled.obs;
  final Rx<ConnectionScreenState> currentConnectionScreenState =
      ConnectionScreenState.homeScreen.obs;
  final Rx<LargePacketModule> currentLargePacketModule =
      LargePacketModule.devices.obs;
  final Rx<SystemBuildStatus> systemBuildStatus = SystemBuildStatus.none.obs;
  final Rx<BuildModule> currentBuildSystemModule = BuildModule.installation.obs;

  List<Uint8List> lOnGoinglargePacketsList = <Uint8List>[];
  int lOngoingsequenceNumber = 0;
  int retryCount = 1;
  int maxRetryCount = 3;
  List<int>? dataPacketBuffer = <int>[];

  static const String _ack = '02';
  static const String _nack = '03';
  static const String _authenticationRequired = '05';
  static const String _timeout = '08';
  static const String invalidPassword = '09';

  final StreamController<BleHandshakeEvent> _handshakeController =
      StreamController<BleHandshakeEvent>.broadcast();

  Stream<BleHandshakeEvent> get handshakeEvents => _handshakeController.stream;

  StreamSubscription<List<int>>? _notifySub;

  Future<void> enableNotifyForCallBack({
    required DiscoveredDevice device,
  }) async {
    final DiscoveredDevice connectedDevice = device;

    logger.Logger(
      "BLE NOTIFY HANDLER: connected device found $connectedDevice.",
    );

    try {
      _notifySub ??= BtUtils().subscribeToNotifications(
        connectedDevice,
        onData: (List<int> data) {
          _handleNotifyData(data, connectedDevice);
        },
        onError: (Object error) {
          _emitEvent(BleHandshakeEvent.error("Notification error: $error"));
        },
      );

      _dataTransferManager.requestEncryptionKey(
        dataWritten: (bool isWritten) {
          if (isWritten) {
            currentBleState(BleStateMachine.reqEncryptionKey);
            _emitStateChange('Requesting encryption key');
          }
        },
      );
    } catch (e) {
      _emitEvent(
        BleHandshakeEvent.error('Unable to subscribe to notification: $e'),
      );
    }
  }

  Future<void> submitPasskey(String passkey) async {
    logger.Logger('========================================');
    logger.Logger('SUBMITTING PASSKEY');
    logger.Logger('========================================');
    logger.Logger('Passkey value: "$passkey"');
    logger.Logger('Passkey length: ${passkey.length} characters');

    if (passkey.isEmpty) {
      logger.Logger('Passkey submission - ERROR: Passkey cannot be empty');
      _emitEvent(BleHandshakeEvent.error('Passkey cannot be empty'));
      return;
    }

    _storedPasskey = passkey;
    pollPacketCount = 0;
    passkeyAccepted = false;
    _controlResEventReportSent = false;
    _passkeySent = true;
    _pktTxCnt = _lastFeaturePacketCounter + 1;
    _lastFeaturePacketCounter = _pktTxCnt;

    logger.Logger('Passkey submission - Calling sendingPasskeyToBle()');
    logger.Logger(
      'Passkey submission - TX Counter: $_pktTxCnt (from last feature packet), RX Counter: $_pktRxCnt',
    );

    currentBleState(BleStateMachine.sendingPasskeyPacket);
    _dataTransferManager.sendingPasskeyToBle(
      passkey,
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Passkey submission - Frame written successfully');
          logger.Logger('Passkey submission - State: sendingPasskeyPacket');
          logger.Logger(
            'Passkey submission - Waiting for acknowledgment response...',
          );
        } else {
          logger.Logger(
            'Passkey submission - WARNING: Frame write may have failed',
          );
        }
      },
    );
    logger.Logger('========================================\n');
  }

  void resetRetryCount() {
    retryCount = 1;
    update();
  }

  void increaseRetryCount() {
    retryCount++;
    update();
  }

  bool checkIfRetryReached() => retryCount >= maxRetryCount;

  void _handleNotifyData(List<int> rxData, DiscoveredDevice device) async {
    if (rxData.isEmpty) {
      return;
    }

    _dataTransferManager.stopResponseTimer();

    FrameData? frame;
    final bool shouldDecrypt =
        kBleEncryptionEnabled &&
        encryptionDecryptionState.value == EncryptionDecryptionState.enabled &&
        currentBleState.value != BleStateMachine.reqEncryptionKey;

    if (shouldDecrypt) {
      try {
        frame = await DataHandler().decryptTheDataPacketWithoutConversion(
          rxData,
        );
      } catch (e) {
        logger.Logger('BLE notify: failed to decrypt frame $e');
      }
    } else {
      logger.Logger('========================================');
      logger.Logger('TX/RX Logs - STEP 2: RECEIVE ENCRYPTION KEY (RX)');
      logger.Logger('========================================');
      String rxHex = rxData
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');
      logger.Logger(
        'TX/RX COMPLETE TECHNOSWITCH LOGS [RX] - RX BLE Frame (raw/non-encrypted): $rxHex',
      );
      logger.Logger(
        'TX/RX Logs - Current State: ${currentBleState.value.name}',
      );

      frame = _dataTransferManager.parseRxFrame(rxData);

      if (frame.commandByte.isNotEmpty && frame.commandByte.length >= 2) {
        int cmdValue =
            (int.parse(frame.commandByte[0], radix: 16) << 8) |
            int.parse(frame.commandByte[1], radix: 16);
        logger.Logger(
          'TX/RX Logs - Command: 0x${cmdValue.toRadixString(16).padLeft(4, '0')}',
        );
      }
      logger.Logger('TX/RX Logs - Frame Type: ${frame.frameTypeByte}');
      logger.Logger(
        'TX/RX Logs - Payload Length: ${frame.payloadData.length} bytes',
      );
      logger.Logger('TX/RX Logs - ========================================\n');
    }

    _logRxTechnoswitchFrames(frame, rxData);

    if (frame == null) {
      _emitEvent(BleHandshakeEvent.error('Unable to parse BLE frame'));
      return;
    }

    _processFrame(frame, device);
  }

  void _logRxTechnoswitchFrames(FrameData? frame, List<int> rawRxData) {
    String bleHex = rawRxData
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    logger.Logger(
      'TX/RX COMPLETE TECHNOSWITCH LOGS [RX] - RX BLE Frame (raw): $bleHex',
    );

    if (frame == null || frame.payloadData.isEmpty) {
      return;
    }

    List<int> technoBytes = convertStringListToHex(frame.payloadData);
    if (technoBytes.length == 216) {
      String technoHex = technoBytes
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');
      logger.Logger(
        'TX/RX ORIGINAL TECHNOSWITCH LOGS [RX] - RX Frame: $technoHex',
      );
    }
  }

  Future<void> _processFrame(
    FrameData frame,
    DiscoveredDevice connectedDevice,
  ) async {
    final bool isValid = DataHandler().frameValidation(
      frame,
      errorCode: (String error) {
        logger.Logger('BLE frame validation error: $error');
      },
    );
    if (!isValid) {
      _emitEvent(BleHandshakeEvent.error('Invalid frame received'));
      return;
    }

    switch (currentBleState.value) {
      case BleStateMachine.reqEncryptionKey:
        _handleEncryptionReqResponse(frame);
        break;
      case BleStateMachine.sendingAuthMessage:
        _handleAuthMsgResponse(frame);
        break;
      case BleStateMachine.requestingNetworkPacket:
        _handleNetworkPacketResponse(frame);
        break;
      case BleStateMachine.sendingPollPacket:
        _handlePollPacketResponse(frame, connectedDevice);
        break;
      case BleStateMachine.requestedPasskey:
        _handlePassKeyRequestResponse(frame, connectedDevice);
        break;
      case BleStateMachine.sendingPasskeyPacket:
        if (frame.payloadData.isNotEmpty) {
          List<int> technoswitchFrameBytes = convertStringListToHex(
            frame.payloadData,
          );
          if (technoswitchFrameBytes.length == 216) {
            String passkeyAckHex = technoswitchFrameBytes
                .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
                .join(' ');
            logger.Logger(
              'TX/RX ORIGINAL TECHNOSWITCH LOGS [PASSKEY] - RX Frame: $passkeyAckHex',
            );

            int pktTyp = technoswitchFrameBytes[3];
            logger.Logger(
              'Passkey acknowledgment - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
            );

            if (pktTyp == 0x03) {
              logger.Logger(
                'Passkey acknowledgment - NACK (0x03) received - Restarting from Network packet',
              );
              _restartFromNetworkPacket('Passkey acknowledgment');
              break;
            }

            if (pktTyp != 0x01 && pktTyp != 0x02) {
              logger.Logger(
                'Passkey acknowledgment - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02 or NRM=0x01) - Restarting from Network packet',
              );
              _restartFromNetworkPacket('Passkey acknowledgment');
              break;
            }

            logger.Logger(
              'Passkey acknowledgment - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
            );

            _pktRxCnt = technoswitchFrameBytes[4];
            pollPacketCount = 0;
            _sendPollPacket();
          }
        }
        break;
      case BleStateMachine.sendingControlResEventReport:
        List<int> technoswitchFrameBytes = convertStringListToHex(
          frame.payloadData,
        );
        String controlResEventReportAckHex = technoswitchFrameBytes
            .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
            .join(' ');
        logger.Logger(
          'TX/RX ORIGINAL TECHNOSWITCH LOGS [CONTROL_RES_EVENT_REPORT] - RX Frame: $controlResEventReportAckHex',
        );
        int pktTyp = technoswitchFrameBytes[3];
        logger.Logger(
          'Passkey acknowledgment - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
        );

        if (pktTyp == 0x03) {
          logger.Logger(
            'Passkey acknowledgment - NACK (0x03) received - Restarting from Network packet',
          );
          _restartFromNetworkPacket('Passkey acknowledgment');
          break;
        }

        if (pktTyp != 0x01 && pktTyp != 0x02) {
          logger.Logger(
            'Passkey acknowledgment - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02 or NRM=0x01) - Restarting from Network packet',
          );
          _restartFromNetworkPacket('Passkey acknowledgment');
          break;
        }
        logger.Logger(
          'CONTROL_RES_EVENT_REPORT - Normal acknowledgment received',
        );

        if (frame.payloadData.isNotEmpty) {
          List<int> technoswitchFrameBytes = convertStringListToHex(
            frame.payloadData,
          );
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - technoswitchFrameBytes length: ${technoswitchFrameBytes.length}  ',
          );
          if (technoswitchFrameBytes.length == 216) {
            String controlAckHex = technoswitchFrameBytes
                .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
                .join(' ');
            logger.Logger(
              'TX/RX ORIGINAL TECHNOSWITCH LOGS [CONTROL_RES_EVENT_REPORT] - RX Frame: $controlAckHex',
            );

            int pktTyp = technoswitchFrameBytes[3];
            logger.Logger(
              'CONTROL_RES_EVENT_REPORT acknowledgment - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
            );

            if (pktTyp == 0x03) {
              logger.Logger(
                'CONTROL_RES_EVENT_REPORT acknowledgment - NACK (0x03) received - Restarting from Network packet',
              );
              _restartFromNetworkPacket(
                'CONTROL_RES_EVENT_REPORT acknowledgment',
              );
              break;
            }

            if (pktTyp != 0x01 && pktTyp != 0x02) {
              logger.Logger(
                'CONTROL_RES_EVENT_REPORT acknowledgment - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02 or NRM=0x01) - Restarting from Network packet',
              );
              _restartFromNetworkPacket(
                'CONTROL_RES_EVENT_REPORT acknowledgment',
              );
              break;
            }

            logger.Logger(
              'CONTROL_RES_EVENT_REPORT acknowledgment - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
            );

            _pktRxCnt = technoswitchFrameBytes[4];
            _pktTxCnt = technoswitchFrameBytes[5];

            if (currentBleState.value == BleStateMachine.sendingPollPacket) {
              lastKnownRxCounter = _pktRxCnt;
            }
            _sendPollPacket();
            currentBleState(BleStateMachine.sendingPollPacket);
          } else {
            logger.Logger(
              'CONTROL_RES_EVENT_REPORT - technoswitchFrameBytes length: ${technoswitchFrameBytes.length}  ',
            );
          }
        }
        break;
      case BleStateMachine.receivingEventLogs:
        _handleEventLogPacketResponse(frame);
        break;
      default:
        logger.Logger(
          'BLE notify: frame received for state ${currentBleState.value.name}',
        );
        break;
    }
  }

  Future<void> _handleEncryptionReqResponse(FrameData frame) async {
    if (frame.payloadData.isEmpty) {
      logger.Logger('Encryption key -  empty response');
      _emitEvent(BleHandshakeEvent.error('Empty encryption response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _authenticationRequired) {
      logger.Logger('Encryption key -  authentication required');
      _emitEvent(BleHandshakeEvent.error('Authentication required by panel'));
      return;
    }

    final List<int> payloadBytes =
        frame.payloadData
            .map((String byte) => int.parse(byte, radix: 16))
            .toList();
    final Uint8List key16 = BleCrypto.extractKeyFromHandshakePayload(
      payloadBytes,
    );
    final String keyHex =
        key16.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
    logger.Logger('Encryption key -  payload bytes: ${frame.payloadData}');
    logger.Logger('Encryption key -  (hex): $keyHex');
    await EncryptionKeyStore.instance.saveKey(keyHex);
    encryptionDecryptionState(
      kBleEncryptionEnabled
          ? EncryptionDecryptionState.enabled
          : EncryptionDecryptionState.disabled,
    );

    _emitEvent(
      BleHandshakeEvent(
        BleHandshakeEventType.encryptionKeyReceived,
        state: currentBleState.value,
      ),
    );

    await Future.delayed(Duration(seconds: 1));

    currentBleState(BleStateMachine.sendingAuthMessage);
    _dataTransferManager.sendAuthPacket(
      dataWritten: (bool isWritten) {
        if (isWritten) {
          _emitStateChange('Sent authentication message');
        }
      },
    );
  }

  Future<void> _handleAuthMsgResponse(FrameData frame) async {
    logger.Logger('Authentication message -  frame: $frame');
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty auth response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      _emitEvent(BleHandshakeEvent.authenticated());
      logger.Logger('Authentication successful - requesting network packet...');
      await Future.delayed(Duration(seconds: 1));
      _requestNetworkPacket();
    } else if (status == _nack) {
      logger.Logger(
        'Authentication message - NACK received - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Authentication message');
    } else {
      logger.Logger(
        'Authentication message - Unexpected response: $status - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Authentication message');
    }
  }

  Future<void> _restartFromNetworkPacket(String source) async {
    logger.Logger('========================================');
    logger.Logger('$source - NACK detected - Restarting from Network packet');
    logger.Logger('========================================');

    _pollPacketResponseTimer?.cancel();
    _continuousPollTimer?.cancel();

    pollPacketCount = 0;
    _pollPacketCountAfterControlRes = 0;
    _storedPasskey = "1974";
    passkeyAccepted = false;
    _controlResEventReportSent = false;
    _controlResEventReportValidResponseReceived = false;
    _passkeySent = false;
    lastKnownRxCounter = 0;
    _pktTxCnt = 0;
    _pktRxCnt = 0;
    _lastFeaturePacketCounter = 0;

    currentBleState(BleStateMachine.none);

    _emitEvent(
      BleHandshakeEvent.error('NACK received - Restarting from Network packet'),
    );

    logger.Logger('$source - Restarting handshake from Network packet...');
    await Future.delayed(Duration(seconds: 1));
    _requestNetworkPacket();

    logger.Logger('========================================\n');
  }

  void _requestNetworkPacket() {
    logger.Logger('========================================');
    logger.Logger('REQUESTING NETWORK PACKET');
    logger.Logger('========================================');
    logger.Logger(
      'Network packet - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt',
    );

    currentBleState(BleStateMachine.requestingNetworkPacket);
    _dataTransferManager.sendingNetworkPacketToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Network packet - Frame written successfully');
          logger.Logger('Network packet - Waiting for panel response...');
        } else {
          logger.Logger(
            'Network packet - WARNING: Frame write may have failed',
          );
        }
      },
    );
    logger.Logger('========================================\n');
  }

  Future<void> _handleNetworkPacketResponse(FrameData frame) async {
    logger.Logger('========================================');
    logger.Logger('NETWORK PACKET RESPONSE RECEIVED');
    logger.Logger('========================================');
    logger.Logger('Network packet response - frame: $frame');
    logger.Logger(
      'Network packet response - payload data: ${frame.payloadData}',
    );

    if (frame.payloadData.isEmpty) {
      logger.Logger(
        'Network packet response - ERROR: Empty network packet response',
      );
      _emitEvent(BleHandshakeEvent.error('Empty network packet response'));
      return;
    }

    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    logger.Logger(
      'Network packet response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
    );

    if (technoswitchFrameBytes.length != 216) {
      logger.Logger(
        'Network packet response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
      );
      _emitEvent(
        BleHandshakeEvent.error(
          'Invalid Technoswitch frame length: ${technoswitchFrameBytes.length}',
        ),
      );
      return;
    }

    const int frameSot = 0xFE;
    const int frameEot = 0xFD;
    if (technoswitchFrameBytes[0] != frameSot) {
      logger.Logger(
        'Network packet response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
      return;
    }
    if (technoswitchFrameBytes[215] != frameEot) {
      logger.Logger(
        'Network packet response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
      return;
    }

    int pktTyp = technoswitchFrameBytes[3];
    logger.Logger(
      'Network packet response - Packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
    );

    if (pktTyp == 0x03) {
      logger.Logger(
        'Network packet response - NACK (0x03) received - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Network packet response');
      return;
    }

    if (pktTyp != 0x01 && pktTyp != 0x02 && pktTyp != 0x04) {
      logger.Logger(
        'Network packet response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected NWK=0x04, ACK=0x02, or NRM=0x01) - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Network packet response');
      return;
    }

    if (pktTyp == 4) {
      logger.Logger(
        'Network packet response - SUCCESS: Network packet received (Packet Type: NWK)',
      );

      _pktTxCnt = 0;
      _pktRxCnt = technoswitchFrameBytes[4];
      _pktTxCnt = 0;
      _lastFeaturePacketCounter = 0;

      logger.Logger('Network packet response - Sending poll packet...');
      _sendPollPacket();
    } else {
      logger.Logger(
        'Network packet response - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
      );
      _pktRxCnt = technoswitchFrameBytes[4];
      _pktTxCnt = 0;
      _lastFeaturePacketCounter = 0;
      logger.Logger('Network packet response - Sending poll packet...');
      _sendPollPacket();
    }
    logger.Logger('========================================\n');
  }

  void _sendPollPacket() async {
    await Future.delayed(Duration(seconds: 1));
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - SEND POLL PACKET');
    logger.Logger('========================================');
    logger.Logger(
      'Poll packet - TX Counter: ${_lastFeaturePacketCounter + 1} (last feature: $_lastFeaturePacketCounter), RX Counter: $_pktRxCnt',
    );

    currentBleState(BleStateMachine.sendingPollPacket);
    _dataTransferManager.sendingPollPacketToBle(
      pktTxCnt: _lastFeaturePacketCounter,
      pktRxCnt: _pktRxCnt,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Poll packet - Frame written successfully');
          logger.Logger('Poll packet - Waiting for panel response...');
        } else {
          logger.Logger('Poll packet - WARNING: Frame write may have failed');
        }
      },
    );
    logger.Logger('========================================\n');
  }

  Future<void> _handlePollPacketResponse(
    FrameData frame,
    DiscoveredDevice device,
  ) async {
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - POLL PACKET RESPONSE RECEIVED');
    logger.Logger('========================================');
    logger.Logger('Poll packet response - frame: $frame');
    logger.Logger('Poll packet response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
      logger.Logger('Poll packet response - ERROR: Empty poll packet response');
      _emitEvent(BleHandshakeEvent.error('Empty poll packet response'));
      return;
    }

    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    if (technoswitchFrameBytes.length != 216) {
      logger.Logger(
        'Poll packet response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
      );
      return;
    }

    if (technoswitchFrameBytes[0] != 0xFE ||
        technoswitchFrameBytes[215] != 0xFD) {
      logger.Logger('Poll packet response - Invalid frame markers');
      return;
    }

    int pktTyp = technoswitchFrameBytes[3];
    int mode = technoswitchFrameBytes[10];
    int socket = technoswitchFrameBytes[11];
    int command = technoswitchFrameBytes[12];

    logger.Logger(
      'Poll packet response - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
    );
    logger.Logger(
      'Poll packet response - Mode: 0x${mode.toRadixString(16).padLeft(2, '0')}, Socket: 0x${socket.toRadixString(16).padLeft(2, '0')}, Command: 0x${command.toRadixString(16).padLeft(2, '0')}',
    );

    if (pktTyp == 0x03) {
      logger.Logger(
        'Poll packet response - NACK (0x03) received - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Poll packet response');
      return;
    }

    if (!_passkeySent && !_controlResEventReportSent) {
      logger.Logger(
        'Poll packet response - First poll packet response received',
      );
      logger.Logger('Poll packet response - Prompting user for passkey...');

      _pktRxCnt = technoswitchFrameBytes[4];

      await Future.delayed(Duration(seconds: 1));
      currentBleState(BleStateMachine.requestedPasskey);
      await AppServices.bleService.submitPasskey("1974");
      logger.Logger(
        'Poll packet response - State changed to: requestedPasskey',
      );
      logger.Logger('========================================\n');
      return;
    }

    if (_passkeySent && !_controlResEventReportSent) {
      List<int> passkeyBytes = '1974'.codeUnits;
      bool passkeyFound = false;
      logger.Logger(
        'The technoswitch frame before checking the passkey: ${technoswitchFrameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      for (
        int i = 14;
        i < 14 + passkeyBytes.length && i < technoswitchFrameBytes.length;
        i++
      ) {
        if (technoswitchFrameBytes[i] == passkeyBytes[i - 14]) {
          passkeyFound = true;
        } else {
          passkeyFound = false;
          break;
        }
      }

      if (passkeyFound && (pktTyp == 0x01 || pktTyp == 0x02)) {
        logger.Logger(
          'Poll packet response - PASSKEY RESPONSE DETECTED: Contains passkey "${_storedPasskey}"',
        );
        logger.Logger(
          'Poll packet response - Passkey accepted (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
        );

        passkeyAccepted = true;

        _pktRxCnt = technoswitchFrameBytes[4];
        _pktTxCnt = _lastFeaturePacketCounter;

        logger.Logger(
          'Poll packet response - Passkey accepted. Sending CONTROL_RES_EVENT_REPORT...',
        );
        await Future.delayed(Duration(seconds: 1));
        _sendControlResEventReport();
        logger.Logger('========================================\n');
        return;
      } else if (_storedPasskey != null && !_controlResEventReportSent) {
        logger.Logger(
          'Poll packet response - Passkey "${_storedPasskey}" NOT found in response. Continuing to send poll packets...',
        );
        currentBleState(BleStateMachine.sendingPollPacket);
        _sendPollPacket();
        return;
      }
    }

    if (_controlResEventReportSent &&
        !_controlResEventReportValidResponseReceived) {
      if (mode == 0x83) {
        int message =
            technoswitchFrameBytes.length > 13 ? technoswitchFrameBytes[13] : 0;
        logger.Logger(
          'Poll packet response - CONTROL_RES_EVENT_REPORT RESPONSE DETECTED',
        );
        logger.Logger(
          'Poll packet response - Mode: 0x83, Socket: 0x04, Command: 0x02 (CONTROL_MESSAGE), Message: 0x${message.toRadixString(16).padLeft(2, '0')}, Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
        );

        if (true) {
          _controlResEventReportValidResponseReceived = true;
          logger.Logger(
            'Poll packet response - CONTROL_RES_EVENT_REPORT: OK (0x00)',
          );
          logger.Logger(
            'Poll packet response - CONTROL_RES_EVENT_REPORT response confirmed. Stopping process and disconnecting...',
          );

          _pollPacketResponseTimer?.cancel();
          _continuousPollTimer?.cancel();

          _pktRxCnt = technoswitchFrameBytes[4];
          _pktTxCnt = technoswitchFrameBytes[5];

          lastKnownRxCounter = _pktRxCnt;

          currentBleState(BleStateMachine.receivingEventLogs);
          _emitEvent(BleHandshakeEvent.passkeyAccepted());

          logger.Logger('Poll packet response - Disconnecting BLE device...');
          BtUtils()
              .disconnect()
              .then((_) {
                logger.Logger(
                  'Poll packet response - BLE device disconnected successfully',
                );
              })
              .catchError((error) {
                logger.Logger(
                  'Poll packet response - Error disconnecting BLE device: $error',
                );
              });
        }
        logger.Logger('========================================\n');
        return;
      } else if (_controlResEventReportValidResponseReceived) {
        logger.Logger(
          'Poll packet response - CONTROL_RES_EVENT_REPORT response received',
        );
        logger.Logger('Poll packet response - Sending next poll packet...');
        currentBleState(BleStateMachine.sendingPollPacket);
        _sendPollPacket();
        return;
      } else {
        currentBleState(BleStateMachine.sendingPollPacket);
        _sendPollPacket();
      }
    }

    if (_controlResEventReportValidResponseReceived) {
      logger.Logger(
        'Poll packet response - Log retrieval response: $technoswitchFrameBytes',
      );
      logger.Logger('Poll packet response - Sending next poll packet...');
      currentBleState(BleStateMachine.sendingPollPacket);
      _sendPollPacket();
      return;
    }

    if (pktTyp != 0x01 && pktTyp != 0x02 && pktTyp != 0x03) {
      logger.Logger(
        'Poll packet response - WARNING: Unexpected packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02, NRM=0x01, or NACK=0x03)',
      );
    } else if (pktTyp == 0x01 || pktTyp == 0x02) {
      logger.Logger(
        'Poll packet response - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
      );
    }

    logger.Logger('========================================\n');
  }

  void _sendControlResEventReport() {
    _pollPacketCountAfterControlRes = 0;
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - SEND CONTROL_RES_EVENT_REPORT');
    logger.Logger('========================================');

    _pktTxCnt = _lastFeaturePacketCounter + 1;
    _lastFeaturePacketCounter = _pktTxCnt;
    logger.Logger(
      'CONTROL_RES_EVENT_REPORT - TX Counter: $_pktTxCnt (from last feature packet), RX Counter: $_pktRxCnt',
    );

    _controlResEventReportSent = true;
    currentBleState(BleStateMachine.sendingControlResEventReport);
    _dataTransferManager.sendingControlResEventReportToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      network: 0,
      node: 0,
      subnode: 0,
      module: 0,
      eventBufferMask: 3,
      eventBufferMode: 0,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - Frame written successfully',
          );
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - Starting continuous polling immediately (not waiting for acknowledgment)...',
          );
        } else {
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - WARNING: Frame write may have failed',
          );
        }
      },
    );
    logger.Logger('========================================\n');
  }

  void _handleEventLogPacketResponse(FrameData frame) {
    _pollPacketResponseTimer?.cancel();

    if (frame.payloadData.isNotEmpty) {
      List<int> technoswitchFrameBytes = convertStringListToHex(
        frame.payloadData,
      );
      if (technoswitchFrameBytes.length == 216) {
        _pktRxCnt = technoswitchFrameBytes[4];
        _pktTxCnt = technoswitchFrameBytes[5];
        lastKnownRxCounter = _pktRxCnt;
      }
    }

    _pollPacketCountAfterControlRes++;

    logger.Logger(
      'Event log response - Response received, sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT...',
    );
    _sendPollPacket();
  }

  void _handlePassKeyRequestResponse(FrameData frame, DiscoveredDevice device) {
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty passkey request response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      final String deviceName = BtUtils().getBTDeviceName(device);
      _emitEvent(BleHandshakeEvent.passkeyPrompt(deviceName: deviceName));
    } else if (status == _timeout) {
      currentBleState(BleStateMachine.timeOut);
      _emitEvent(BleHandshakeEvent.error('Passkey request timed out'));
    } else {
      _emitEvent(
        BleHandshakeEvent.error('Passkey request failed with status $status'),
      );
    }
  }

  void requestControlResEventReport() {
    logger.Logger('TX/RX Logs - ========================================');
    logger.Logger(
      'TX/RX Logs - REQUESTING CONTROL_RES_EVENT_REPORT (Service Command)',
    );
    logger.Logger('TX/RX Logs - ========================================');
    logger.Logger(
      'TX/RX Logs - CONTROL_RES_EVENT_REPORT - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt',
    );

    _pktTxCnt++;

    _dataTransferManager.sendingControlResEventReportToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      network: 5,
      node: 0,
      subnode: 0,
      module: 0,
      eventBufferMask: 3,
      eventBufferMode: 0,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - Frame written successfully',
          );
          logger.Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - Waiting for panel response...',
          );
        } else {
          logger.Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - WARNING: Frame write may have failed',
          );
        }
      },
    );
    logger.Logger('TX/RX Logs - ========================================\n');
  }

  void _emitStateChange([String? message]) {
    _emitEvent(
      BleHandshakeEvent(
        BleHandshakeEventType.stateChanged,
        state: currentBleState.value,
        message: message,
      ),
    );
  }

  void _emitEvent(BleHandshakeEvent event) {
    if (_handshakeController.isClosed) {
      return;
    }
    _handshakeController.add(event);
  }

  @override
  void onClose() {
    _continuousPollTimer?.cancel();
    _pollPacketResponseTimer?.cancel();
    _handshakeController.close();
    super.onClose();
  }
}

class BleHandshakeEvent {
  const BleHandshakeEvent(
    this.type, {
    this.state,
    this.message,
    this.deviceName,
  });

  final BleHandshakeEventType type;
  final BleStateMachine? state;
  final String? message;
  final String? deviceName;

  factory BleHandshakeEvent.stateChanged(BleStateMachine state) =>
      BleHandshakeEvent(BleHandshakeEventType.stateChanged, state: state);

  factory BleHandshakeEvent.encryptionKey() =>
      const BleHandshakeEvent(BleHandshakeEventType.encryptionKeyReceived);

  factory BleHandshakeEvent.authenticated() =>
      const BleHandshakeEvent(BleHandshakeEventType.authenticated);

  factory BleHandshakeEvent.passkeyPrompt({String? deviceName}) =>
      BleHandshakeEvent(
        BleHandshakeEventType.passkeyRequested,
        deviceName: deviceName,
      );

  factory BleHandshakeEvent.passkeyAccepted() =>
      const BleHandshakeEvent(BleHandshakeEventType.passkeyAccepted);

  factory BleHandshakeEvent.error(String message) =>
      BleHandshakeEvent(BleHandshakeEventType.error, message: message);
}

enum BleHandshakeEventType {
  stateChanged,
  encryptionKeyReceived,
  authenticated,
  passkeyRequested,
  passkeyAccepted,
  error,
}

enum ConnectionScreenState {
  homeScreen,
  installationScreen,
  maintanence,
  projectDetails,
  panelReplace,
  buildPartialScreen,
}

enum SystemBuildStatus { none, started, completed, failed }

enum BuildModule {
  installation,
  maintenanceAdd,
  editDevice,
  editProperties,
  editPendingBitProperties,
  editExpanderProperties,
  editExpanderPendingBitProperties,
  bulkEdit,
  skipPartialDevices,
  updateCandE,
  maintanaceZoneUpdate,
  removeDevice,
  retryRemoveDevice,
  replaceDevice,
  replaceExpander,
  replaceExpanderFailed,
  sendPartialRemoveDeviceProcedure,
  panelReplace,
}

enum LargePacketModule {
  devices,
  panelNetworkData,
  firmWareUpgrade,
  sendingProjectData,
  sendingZoneData,
}

enum EncryptionDecryptionState { disabled, enabled }

enum BleStateMachine {
  none,
  requestedPasskey,
  passkeyEntered,
  reqEncryptionKey,
  timeOut,
  sendingAuthMessage,
  requestingNetworkPacket,
  sendingPollPacket,
  sendingPasskeyPacket,
  sendingControlResEventReport,
  receivingEventLogs,
  sendingDummyPacket,
  connected,

  createProject,
  installationStep1Completed,
  installationStep2Completed,
  installationStep3Completed,

  sendingPanelConfig,
  sendingProjectData,
  sendingExpanderConfig,
  updateExpanderConfig,
  buildSystem,
  stopBuildSystem,
  panelVersionSend,
  procedureCommandSent,
  getSystemOnlineStatus,
  linkStatusCommand,
  systemBuildSuccess,
  systemBuildFailed,
  sendingZoneData,

  connectCommandSend,

  dataSyncRequest,
  dataStartRequest,
  sendingLargePacketOnGoing,
  largeDataResended,
  dataEndRequest,
  mcuSelection,
  eraseFirmware,
  eofImageData,
  waitingForBuildReady,
  updateBleProcess,
  updatePanelNetworkDataProcess,
  sendingEmptyDeviceData,
  putDeviceToLinkMode,

  expanderPassKeySent,

  requestedForPanelConfig,
  requestedForDeviceConfig,
  requestedForProjectData,
  requestedForExpanderData,
  requestedForZoneData,
  respondedDataSyncRequest,
  respondedToDataStart,
  respondToEndPacket,

  getAllDeviceStatusState,
  getSingleDeviceStatusState,
  getSingleDeviceStatusStateForPendingBit,
  getAllDeviceVersionsState,
  getProjectState,
  requestedForMcuVersions,

  requestedForNetworkData,
  requestedForExpanderParentAddress,
  requestedForNetworkDataCRC,
  checkMismatchForNetworkDataCRC,
  startPanelReplacementSession,
  closePanelReplacementSession,
  closeOldPanelReplacementSession,

  addDeviceState,
  removeDevice,
  replaceDevice,
  editDevice,

  changeDeviceAddress,
  editDeviceProperties,
  editDevicePendingBitProperties,
  editExpanderProperties,
  editExpanderPendingBitProperties,
  bulkEditLedUpdate,
  identifyDevices,

  retryRemoveDeviceState,
  skipRemoveDeviceState,
  retryAddDeviceState,

  updateDevicePointData,
  updateExpanderPropertyData,
  updateExpanderPendingBitPropertyData,
  updateDevicePropertiesData,
  updateDevicePendingBitPropertiesData,
  updatingProjectData,
  updatingBuildStateData,
  updatingPanelData,

  requestedForEventLogs,
  requestedForDiagnosticLogs,
  requestedForEventLogsFilterData,
  requestedForEventLogsFilterDataWithSectionNumber,
  requestedPanelStatus,

  updatePanelDateTimeState,
  updatePanelDateTimeBeforeBuildState,
  requestedForConfigCrc,
  requestedForPanelConfigStatus,
  requestedForDeviceVersions,

  firmwareUploadStatus,
  rfTestCMD,
  enableAnalogValue,
  enableAnalogValueInOnline,
  disableAnalogValue,
  disableAnalogValueWithoutResponse,
  disableAnalogValueForBuildSystem,
  disableAnalogValueFollowWithConnectCMD,

  disableAnalogValueExpanderProperties,
  disableAnalogValueSendingPanelNetworkData,
  disableAnalogValueExpanderPendingBitProperties,
  disableAnalogValueEditProperties,
  disableAnalogValueEditPendingBitProperties,
  disableAnalogValueRemoveCommand,
  disableAnalogValueForFetchPanelData,
  disableAnalogValueReplaceCommand,
  disableAnalogAddZone,

  resetBleTrack,
}
