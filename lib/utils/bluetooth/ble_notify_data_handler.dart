/*
* Project      : technoswitch_solar_app
* File         : ble_notify_data_handler.dart
* Description  : Simplified GetX controller that manages the Technoswitch BLE
*                handshake (encryption exchange, auth message and passkey flow).
*                The older project specific navigation/hooks have been removed
*                so the rest of the app can integrate it freely.
*/

import 'dart:async';
import 'dart:typed_data';

// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/services/firmware_upgrade_service.dart';
import 'package:techno_switch_solar_app/models/mcu_info.dart';

import '../../services/app_services.dart';

/// Converts bytes to ASCII representation (printable chars or dots)
String _bytesToAscii(List<int> bytes) {
  return bytes.map((b) {
    if (b >= 32 && b <= 126) {
      // Printable ASCII characters
      return String.fromCharCode(b);
    } else {
      // Non-printable characters shown as dots
      return '.';
    }
  }).join();
}

class BleNotifyDataHandler extends GetxController {
  final DataTransferManager _dataTransferManager = DataTransferManager();

  // Packet counters for network packet and passkey
  int _pktTxCnt = 0;
  int _pktRxCnt = 0;
  int _lastFeaturePacketCounter =
      0; // Track counter of last feature packet sent

  // Poll packet flow tracking
  int _pollPacketCount = 0; // Track how many poll packets sent after passkey
  int _pollPacketCountAfterControlRes =
      0; // Track how many poll packets sent after CONTROL_RES_EVENT_REPORT
  String? _storedPasskey; // Store passkey to detect response in poll packets
  bool _passkeyAccepted = false; // Track if passkey was found in poll response
  bool _controlResEventReportSent = false;
  bool _controlResEventReportValidResponseReceived =
      false; // Track if CONTROL_RES_EVENT_REPORT was sent
  bool _passkeySent = false; // Track if passkey was sent
  Timer? _continuousPollTimer; // Timer for continuous poll packet sending
  Timer?
  _pollPacketResponseTimer; // Timer to wait 100ms for poll packet response
  int _lastKnownRxCounter =
      0; // Store last known RX counter when no response received

  /// Observables used across the Bluetooth helpers.
  final Rx<BleStateMachine> currentBleState = BleStateMachine.none.obs;
  final Rx<EncryptionDecryptionState> encryptionDecryptionState =
      EncryptionDecryptionState.disabled.obs;
  final Rx<ConnectionScreenState> currentConnectionScreenState =
      ConnectionScreenState.homeScreen.obs;
  final Rx<LargePacketModule> currentLargePacketModule =
      LargePacketModule.devices.obs;
  final Rx<SystemBuildStatus> systemBuildStatus = SystemBuildStatus.none.obs;
  final Rx<BuildModule> currentBuildSystemModule = BuildModule.installation.obs;

  /// Legacy properties referenced by other helpers (large data transfer).
  List<Uint8List> lOnGoinglargePacketsList = <Uint8List>[];
  int lOngoingsequenceNumber = 0;
  int retryCount = 1;
  int maxRetryCount = 3;
  List<int>? dataPacketBuffer = <int>[];

  static const String _ack = '02';
  static const String _nack = '03';
  static const String _authenticationRequired = '05';
  static const String _timeout = '08';
  static const String _invalidPassword = '09';

  final StreamController<BleHandshakeEvent> _handshakeController =
      StreamController<BleHandshakeEvent>.broadcast();

  Stream<BleHandshakeEvent> get handshakeEvents => _handshakeController.stream;

  StreamSubscription<List<int>>? _notifySub;

  /// Enable notifications on the currently connected BLE device.
  ///
  Future<void> enableNotifyForCallBack({
    required DiscoveredDevice device,
  }) async {
    final DiscoveredDevice? connectedDevice = device;

    if (connectedDevice == null) {
      logger.Logger("BLE NOTIFY HANDLER: no connected device found.");
      _emitEvent(
        BleHandshakeEvent.error("Device disconnected before handshake"),
      );
      return;
    } else {
      logger.Logger(
        "BLE NOTIFY HANDLER: connected device found $connectedDevice.",
      );
    }

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
  // Future<void> enableNotifyForCallBack() async {
  //   final DiscoveredDevice? connectedDevice =
  //       await BtUtils().getConnectedDevice();
  //   if (connectedDevice == null) {
  //     logger.Logger('BLE notify handler: no connected device found.');
  //     _emitEvent(
  //       BleHandshakeEvent.error('Device disconnected before handshake'),
  //     );
  //     return;
  //   }

  //   BtUtils().enableNotifications(
  //     connectedDevice,
  //     (List<int> data) {
  //       if (connectedDevice.isConnected) {
  //         _handleNotifyData(data, connectedDevice);
  //       }
  //     },
  //     notifyEnabledcallback: (bool enabled) {
  //       if (!enabled) {
  //         _emitEvent(
  //           BleHandshakeEvent.error(
  //             'Unable to enable notifications on primary characteristic',
  //           ),
  //         );
  //         return;
  //       }

  //       _dataTransferManager.requestEncryptionKey(
  //         dataWritten: (bool isWritten) {
  //           if (isWritten) {
  //             currentBleState(BleStateMachine.reqEncryptionKey);
  //             _emitStateChange('Requesting encryption key');
  //           }
  //         },
  //       );
  //     },
  //   );
  // }

  /// Sends the user provided passkey back to the panel.
  /// After sending passkey, sends 3 poll packets, then CONTROL_RES_EVENT_REPORT, then continuous poll packets.
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

    // Store passkey to detect response in poll packets
    _storedPasskey = passkey;
    _pollPacketCount = 0;
    _passkeyAccepted = false; // Reset passkey acceptance flag
    _controlResEventReportSent = false;
    _passkeySent = true;
    // Compute TX for this feature = lastFeature + 1
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
          // Don't send poll packet here - wait for acknowledgment in _processFrame
          // The acknowledgment will be handled in sendingPasskeyPacket state case
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

    // Stop any outstanding timers – we received a response.
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
      // Non-encrypted RX (encryption key response)
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

    // Log RX frames (BLE + inner Technoswitch if present)
    _logRxTechnoswitchFrames(frame, rxData);

    if (frame == null) {
      _emitEvent(BleHandshakeEvent.error('Unable to parse BLE frame'));
      return;
    }

    _processFrame(frame, device);
  }

  /// Logs RX BLE frame (raw) and inner Technoswitch frame (if length 216).
  void _logRxTechnoswitchFrames(FrameData? frame, List<int> rawRxData) {
    // Log raw BLE frame
    String bleHex = rawRxData
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    logger.Logger(
      'TX/RX COMPLETE TECHNOSWITCH LOGS [RX] - RX BLE Frame (raw): $bleHex',
    );

    if (frame == null || frame.payloadData.isEmpty) {
      return;
    }

    // Convert payload to Technoswitch bytes and log if full length
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
        // Handle immediate acknowledgment response for passkey
        // Extract Technoswitch frame from payload and log it
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

            // Extract packet type for ACK/NACK validation
            int pktTyp = technoswitchFrameBytes[3];
            logger.Logger(
              'Passkey acknowledgment - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
            );

            // Check for NACK (0x03) - restart from network packet
            if (pktTyp == 0x03) {
              logger.Logger(
                'Passkey acknowledgment - NACK (0x03) received - Restarting from Network packet',
              );
              _restartFromNetworkPacket('Passkey acknowledgment');
              break;
            }

            // Validate ACK/NACK - should be ACK (0x02) or NRM (0x01)
            if (pktTyp != 0x01 && pktTyp != 0x02) {
              logger.Logger(
                'Passkey acknowledgment - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02 or NRM=0x01) - Restarting from Network packet',
              );
              // await Future.delayed(Duration(seconds: 1));
              // // _sendPollPacket();
              _restartFromNetworkPacket('Passkey acknowledgment');
              break;
            }

            logger.Logger(
              'Passkey acknowledgment - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
            );

            // Update RX counter from acknowledgment
            _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx

            // Now send first poll packet after acknowledgment
            _pollPacketCount = 0;
            _sendPollPacket();
          }
        }
        break;
      // case BleStateMachine.requestedPasskey:
      //   _handlePassKeyRequestResponse(frame, connectedDevice);
      //   break;
      case BleStateMachine.sendingControlResEventReport:
        // After sending CONTROL_RES_EVENT_REPORT, we may receive a normal acknowledgment response
        // This is NOT the CONTROL_RES_EVENT_REPORT response - that comes in a poll packet
        // We don't wait for this acknowledgment - polling already started
        // But if acknowledgment comes, we can still update counters
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

        // Check for NACK (0x03) - restart from network packet
        if (pktTyp == 0x03) {
          logger.Logger(
            'Passkey acknowledgment - NACK (0x03) received - Restarting from Network packet',
          );
          _restartFromNetworkPacket('Passkey acknowledgment');
          break;
        }

        // Validate ACK/NACK - should be ACK (0x02) or NRM (0x01)
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

        // Parse the response to update counters and log it
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

            // Extract packet type for ACK/NACK validation
            int pktTyp = technoswitchFrameBytes[3];
            logger.Logger(
              'CONTROL_RES_EVENT_REPORT acknowledgment - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
            );

            // Check for NACK (0x03) - restart from network packet
            if (pktTyp == 0x03) {
              logger.Logger(
                'CONTROL_RES_EVENT_REPORT acknowledgment - NACK (0x03) received - Restarting from Network packet',
              );
              _restartFromNetworkPacket(
                'CONTROL_RES_EVENT_REPORT acknowledgment',
              );
              break;
            }

            // Validate ACK/NACK - should be ACK (0x02) or NRM (0x01)
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

            // Update counters from response (optional - polling already started)
            _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx
            _pktTxCnt = technoswitchFrameBytes[5]; // Panel's rx = our tx

            // Update last known RX counter if polling is active
            if (currentBleState.value == BleStateMachine.sendingPollPacket) {
              _lastKnownRxCounter = _pktRxCnt;
            }
            _sendPollPacket();
            currentBleState(BleStateMachine.sendingPollPacket);
          } else {
            logger.Logger(
              'CONTROL_RES_EVENT_REPORT - technoswitchFrameBytes length: ${technoswitchFrameBytes.length}  ',
            );
          }
        }
        // Don't call _startContinuousPollPackets() here - already started
        break;
      case BleStateMachine.receivingEventLogs:
        _handleEventLogPacketResponse(frame);
        break;
      // case BleStateMachine.sendingDummyPacket:
      //   _handleDummyPacketResponse(frame);
      //   break;
      // case BleStateMachine.mcuSelection:
      //   _handleMcuSelectionProcess(frame, connectedDevice);
      //   break;
      // case BleStateMachine.eofImageData:
      //   _handleEofImageDataProcess(frame, connectedDevice);
      //   break;
      // case BleStateMachine.dataSyncRequest:
      //   _handleDataSyncRequestProcess(frame, connectedDevice);
      //   break;
      // case BleStateMachine.dataStartRequest:
      //   _handleDataStartRequestProcess(frame, connectedDevice);
      //   break;
      // case BleStateMachine.sendingLargePacketOnGoing:
      //   _handleLargePacketProcess(frame, connectedDevice);
      //   break;
      // case BleStateMachine.dataEndRequest:
      //   _handleDataEndRequestProcess(frame, connectedDevice);
      //   break;
      default:
        // For now we only care about the connect/auth flow.
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

    final List<int> payloadBytes = frame.payloadData
        .map((String byte) => int.parse(byte, radix: 16))
        .toList();
    final Uint8List key16 =
        BleCrypto.extractKeyFromHandshakePayload(payloadBytes);
    final String keyHex = key16
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
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
          // currentBleState(BleStateMachine.sendingAuthMessage);
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
      // After authentication, request network packet first (old way)
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

  /// Helper method to restart the handshake from Network Packet.
  /// Resets all state variables and timers, then requests network packet.
  Future<void> _restartFromNetworkPacket(String source) async {
    logger.Logger('========================================');
    logger.Logger('$source - NACK detected - Restarting from Network packet');
    logger.Logger('========================================');

    // Cancel all timers
    _pollPacketResponseTimer?.cancel();
    _continuousPollTimer?.cancel();

    // Reset all state variables
    _pollPacketCount = 0;
    _pollPacketCountAfterControlRes = 0;
    _storedPasskey = "1974";
    _passkeyAccepted = false; // Reset passkey acceptance flag
    _controlResEventReportSent = false;
    _controlResEventReportValidResponseReceived = false;
    _passkeySent = false;
    _lastKnownRxCounter = 0;
    _pktTxCnt = 0;
    _pktRxCnt = 0;
    _lastFeaturePacketCounter = 0;

    // Reset state
    currentBleState(BleStateMachine.none);

    // Emit error event
    _emitEvent(
      BleHandshakeEvent.error('NACK received - Restarting from Network packet'),
    );

    // Restart from network packet
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

    // The payload contains a nested Technoswitch frame (216 bytes)
    // Convert hex strings to integers
    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    logger.Logger(
      'Network packet response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
    );

    // Validate Technoswitch frame structure (should be 216 bytes)
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

    // Validate frame markers
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

    // Check packet type - should be NWK (0x04), ACK (0x02), or NRM (0x01)
    int pktTyp = technoswitchFrameBytes[3];
    logger.Logger(
      'Network packet response - Packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
    );

    // Check for NACK (0x03) - restart from network packet
    if (pktTyp == 0x03) {
      logger.Logger(
        'Network packet response - NACK (0x03) received - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Network packet response');
      return;
    }

    // Check for ACK/NACK validation
    if (pktTyp != 0x01 && pktTyp != 0x02 && pktTyp != 0x04) {
      logger.Logger(
        'Network packet response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected NWK=0x04, ACK=0x02, or NRM=0x01) - Restarting from Network packet',
      );
      _restartFromNetworkPacket('Network packet response');
      return;
    }

    if (pktTyp == 4) {
      // Future.delayed(const Duration(milliseconds: 3500), () {
      //   _requestNetworkPacket();
      // });
      // NWK packet received successfully
      logger.Logger(
        'Network packet response - SUCCESS: Network packet received (Packet Type: NWK)',
      );

      // Reset tx counter to 0 as per C code (send_nwk_pkt resets u8_tx_pkt_cnt=0)
      _pktTxCnt = 0;
      // Update rx counter from response byte 4 (panel's tx counter)
      _pktRxCnt = technoswitchFrameBytes[4];

      // Last feature counter remains the TX used for this feature (0 for NWK)
      _pktTxCnt = 0;
      _lastFeaturePacketCounter = 0;

      // After network packet, send poll packet (Step 2)
      logger.Logger('Network packet response - Sending poll packet...');
      _sendPollPacket();
    } else {
      // Future.delayed(const Duration(milliseconds: 3500), () {
      //   _requestNetworkPacket();
      // });
      // ACK (0x02) or NRM (0x01) - also valid, proceed
      logger.Logger(
        'Network packet response - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
      );
      // Update counters
      _pktRxCnt = technoswitchFrameBytes[4];
      _pktTxCnt = 0;
      _lastFeaturePacketCounter = 0;
      // Proceed to poll packet
      logger.Logger('Network packet response - Sending poll packet...');
      _sendPollPacket();
    }
    logger.Logger('========================================\n');
  }

  /// Sends a poll packet with current packet counters.
  /// Poll packets use (lastFeaturePacketCounter+1) as per user's counter logic.
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
      pktTxCnt:
          _lastFeaturePacketCounter, // Pass lastFeaturePacketCounter, builder will add 1
      pktRxCnt: _pktRxCnt,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Poll packet - Frame written successfully');
          logger.Logger('Poll packet - Waiting for panel response...');

          // After CONTROL_RES_EVENT_REPORT, wait 100ms for response, then send next if no response
          // if (_controlResEventReportSent) {
          //   // Cancel any existing timer
          //   _pollPacketResponseTimer?.cancel();

          //   // Start 100ms timer to wait for response
          //   _pollPacketResponseTimer = Timer(const Duration(milliseconds: 0), () {
          //     // No response received within 100ms - use last known RX counter and send next poll packet
          //     logger.Logger(
          //       'Poll packet - No response received within 100ms, using last known RX counter: $_lastKnownRxCounter',
          //     );
          //     _pktRxCnt = _lastKnownRxCounter; // Use last known RX counter

          //     // Send next poll packet
          //     _pollPacketCountAfterControlRes++;

          //     // Check if we've sent 100 poll packets without valid CONTROL_RES_EVENT_REPORT response
          //     if (_pollPacketCountAfterControlRes >= 100) {
          //       logger.Logger(
          //         'Poll packet - 100 poll packets sent after CONTROL_RES_EVENT_REPORT without valid response - Restarting from Network packet',
          //       );
          //       _restartFromNetworkPacket('Poll packet timeout (100 packets)');
          //       return;
          //     }

          //     logger.Logger(
          //       'Poll packet - Sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT (no response timeout)...',
          //     );
          //     _sendPollPacket();
          //   });
          // }
        } else {
          logger.Logger('Poll packet - WARNING: Frame write may have failed');
        }
      },
    );
    logger.Logger('========================================\n');
  }

  /// Handles poll packet response.
  /// Detects passkey response (contains stored passkey) and CONTROL_RES_EVENT_REPORT response (mode=0x83, socket=0x04, command=0x02).
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

    // The payload contains a nested Technoswitch frame (216 bytes)
    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    if (technoswitchFrameBytes.length != 216) {
      logger.Logger(
        'Poll packet response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
      );
      // Continue - might be a normal poll response
      // _sendNextPollPacket();
      return;
    }

    // Validate frame markers
    if (technoswitchFrameBytes[0] != 0xFE ||
        technoswitchFrameBytes[215] != 0xFD) {
      logger.Logger('Poll packet response - Invalid frame markers');
      // _sendNextPollPacket();
      return;
    }

    // Extract frame fields
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

    // If no passkey stored yet, this is the first poll packet after network packet
    // Prompt user for passkey
    if (!_passkeySent && !_controlResEventReportSent) {
      // TODO: Add normal poll packet response here.
      logger.Logger(
        'Poll packet response - First poll packet response received',
      );
      logger.Logger('Poll packet response - Prompting user for passkey...');

      // Update counters from response
      // Response byte 4 is panel's tx counter (our rx counter)
      _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx
      // Do NOT override _pktTxCnt here – keep last feature counter (Network = 0)
      // Feature TX counter only moves when a feature command is sent/accepted.

      // Prompt for passkey
      await Future.delayed(Duration(seconds: 1));
      currentBleState(BleStateMachine.requestedPasskey);
      // _emitEvent(BleHandshakeEvent.passkeyPrompt());
      await AppServices.bleService.submitPasskey("1974");
      logger.Logger(
        'Poll packet response - State changed to: requestedPasskey',
      );
      logger.Logger('========================================\n');
      // currentBleState(BleStateMachine.sendingPasskeyPacket);
      return;
    }

    // Check for passkey response (contains stored passkey in payload)
    if (_passkeySent && !_controlResEventReportSent) {
      // Check if response contains the passkey (bytes 14-17+)
      List<int> passkeyBytes = '1974'.codeUnits;
      bool passkeyFound = false;
      logger.Logger(
        'The technoswitch frame before checking the passkey: ${technoswitchFrameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      // Check if passkey appears in the response (typically at offset 14-17)
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

        // Mark passkey as accepted
        _passkeyAccepted = true;

        // Update counters from response (rx only); keep feature counter as the passkey TX
        _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx
        _pktTxCnt = _lastFeaturePacketCounter;

        // Passkey response detected in poll packet - now send CONTROL_RES_EVENT_REPORT
        logger.Logger(
          'Poll packet response - Passkey accepted. Sending CONTROL_RES_EVENT_REPORT...',
        );
        await Future.delayed(Duration(seconds: 1));
        _sendControlResEventReport();
        logger.Logger('========================================\n');
        return;
      } else if (_storedPasskey != null && !_controlResEventReportSent) {
        // Passkey not found in this response - log and continue polling
        logger.Logger(
          'Poll packet response - Passkey "${_storedPasskey}" NOT found in response. Continuing to send poll packets...',
        );
        currentBleState(BleStateMachine.sendingPollPacket);
        _sendPollPacket();
        return;
      }
    }

    // // Check for NACK (0x03) - restart from network packet if received
    // if (pktTyp == 0x03) {
    //   logger.Logger(
    //     'Poll packet response - NACK (0x03) received - Restarting from Network packet',
    //   );
    //   _restartFromNetworkPacket('Poll packet response');
    //   return;
    // }

    // Check for CONTROL_RES_EVENT_REPORT response
    // Response format: mode=0x83, socket=0x04, command=0x02 (CONTROL_MESSAGE), message=0x00 (OK)
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

        // Validate ACK/NACK for CONTROL_RES_EVENT_REPORT response
        // if (pktTyp == 0x03) {
        //   logger.Logger(
        //     'Poll packet response - CONTROL_RES_EVENT_REPORT response - NACK (0x03) received - Restarting from Network packet',
        //   );
        //   _restartFromNetworkPacket('CONTROL_RES_EVENT_REPORT response');
        //   return;
        // }

        // if (pktTyp != 0x01 && pktTyp != 0x02) {
        //   logger.Logger(
        //     'Poll packet response - CONTROL_RES_EVENT_REPORT response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02 or NRM=0x01) - Restarting from Network packet',
        //   );
        //   _restartFromNetworkPacket('CONTROL_RES_EVENT_REPORT response');
        //   return;
        // }

        // logger.Logger(
        //   'Poll packet response - CONTROL_RES_EVENT_REPORT response - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
        // );

        if (true) {
          _controlResEventReportValidResponseReceived = true;
          logger.Logger(
            'Poll packet response - CONTROL_RES_EVENT_REPORT: OK (0x00)',
          );
          logger.Logger(
            'Poll packet response - CONTROL_RES_EVENT_REPORT response confirmed. Stopping process and disconnecting...',
          );

          // Cancel all timers to stop the polling process
          _pollPacketResponseTimer?.cancel();
          _continuousPollTimer?.cancel();

          // Update counters from response
          _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx
          _pktTxCnt = technoswitchFrameBytes[5]; // Panel's rx = our tx

          // Store the RX counter as last known value
          _lastKnownRxCounter = _pktRxCnt;

          // Set state to indicate completion
          currentBleState(BleStateMachine.receivingEventLogs);
          _emitEvent(BleHandshakeEvent.passkeyAccepted());

          // Disconnect BLE device
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

    // Validate ACK/NACK for normal poll packet responses
    // ACK (0x02) or NRM (0x01) are valid, NACK (0x03) already handled above
    if (pktTyp != 0x01 && pktTyp != 0x02 && pktTyp != 0x03) {
      logger.Logger(
        'Poll packet response - WARNING: Unexpected packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (expected ACK=0x02, NRM=0x01, or NACK=0x03)',
      );
      // Continue processing but log warning
    } else if (pktTyp == 0x01 || pktTyp == 0x02) {
      logger.Logger(
        'Poll packet response - Valid response received (Packet Type: ${pktTyp == 0x01 ? "NRM" : "ACK"})',
      );
    }

    // Normal poll packet response (event log data or other)
    // if (_controlResEventReportSent) {
    //   logger.Logger('Poll packet response - Event log data received');
    //   // Cancel timeout timer since we received a response
    //   _pollPacketResponseTimer?.cancel();
    //   // Handle event log data
    //   _handleEventLogPacketResponse(frame);
    //   return; // Return early to avoid duplicate poll packet sending
    // } else {
    //   // Before CONTROL_RES_EVENT_REPORT, keep sending poll packets until passkey is found
    //   if (!_passkeyAccepted && !_controlResEventReportSent) {
    //     // Passkey not yet accepted - continue sending poll packets
    //     _pollPacketCount++;
    //     logger.Logger(
    //       'Poll packet response - Passkey not yet found. Sending poll packet $_pollPacketCount (waiting for passkey response)...',
    //     );

    //     // Optional: Add timeout to prevent infinite polling
    //     // If we've sent too many poll packets without finding passkey, restart
    //     if (_pollPacketCount >= 50) {
    //       logger.Logger(
    //         'Poll packet response - ERROR: 50 poll packets sent without finding passkey. Restarting from Network packet...',
    //       );
    //       _restartFromNetworkPacket('Passkey not found after 50 poll packets');
    //       return;
    //     }

    //     _sendPollPacket();
    //   } else if (_passkeyAccepted && !_controlResEventReportSent) {
    //     // Passkey was accepted but CONTROL_RES_EVENT_REPORT not sent yet (shouldn't happen, but safety check)
    //     logger.Logger('Passkey accepted. Sending CONTROL_RES_EVENT_REPORT...');
    //     _sendControlResEventReport();
    //   } else {
    //     // After CONTROL_RES_EVENT_REPORT, continue with continuous polling
    //     _pollPacketCountAfterControlRes++;
    //     logger.Logger(
    //       'Poll packet response - Sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT (500ms delay)...',
    //     );
    //     // Future.delayed(const Duration(milliseconds: 35), () {
    //     //   _sendPollPacket();
    //     // });
    //     _sendPollPacket();
    //   }
    // }
    logger.Logger('========================================\n');
  }

  /// Sends the next poll packet based on current flow state.
  /// This is called when we need to continue the poll packet flow.
  // void _sendNextPollPacket() {
  //   if (_controlResEventReportSent) {
  //     // After CONTROL_RES_EVENT_REPORT, continue with continuous polling
  //     _pollPacketCountAfterControlRes++;
  //     logger.Logger(
  //       'Next poll packet - Sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT (500ms delay)...',
  //     );
  //     // Future.delayed(const Duration(milliseconds: 35), () {
  //     //   _sendPollPacket();
  //     // });
  //     _sendPollPacket();
  //   } else if (!_passkeyAccepted && !_controlResEventReportSent) {
  //     // Before CONTROL_RES_EVENT_REPORT, keep sending poll packets until passkey is found
  //     _pollPacketCount++;
  //     logger.Logger(
  //       'Sending poll packet $_pollPacketCount (waiting for passkey response)...',
  //     );

  //     // Optional: Add timeout to prevent infinite polling
  //     if (_pollPacketCount >= 50) {
  //       logger.Logger(
  //         'Next poll packet - ERROR: 50 poll packets sent without finding passkey. Restarting from Network packet...',
  //       );
  //       _restartFromNetworkPacket('Passkey not found after 50 poll packets');
  //       return;
  //     }

  //     _sendPollPacket();
  //   } else if (_passkeyAccepted && !_controlResEventReportSent) {
  //     // Passkey was accepted but CONTROL_RES_EVENT_REPORT not sent yet
  //     logger.Logger('Passkey accepted. Sending CONTROL_RES_EVENT_REPORT...');
  //     _sendControlResEventReport();
  //   }
  // }

  /// Sends CONTROL_RES_EVENT_REPORT command.
  void _sendControlResEventReport() {
    // Reset poll packet counter after CONTROL_RES_EVENT_REPORT
    _pollPacketCountAfterControlRes = 0;
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - SEND CONTROL_RES_EVENT_REPORT');
    logger.Logger('========================================');

    // Compute TX for this feature = lastFeature + 1
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
      eventBufferMask: 3, // Radio event printer
      eventBufferMode: 0, // Start
      dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - Frame written successfully',
          );
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - Starting continuous polling immediately (not waiting for acknowledgment)...',
          );
          // // Start continuous polling immediately - don't wait for acknowledgment
          // _startContinuousPollPackets();
        } else {
          logger.Logger(
            'CONTROL_RES_EVENT_REPORT - WARNING: Frame write may have failed',
          );
        }
      },
    );
    logger.Logger('========================================\n');
  }

  /// Starts continuous poll packet sending after CONTROL_RES_EVENT_REPORT.
  // void _startContinuousPollPackets() {
  //   logger.Logger('Starting continuous poll packet sending...');

  //   // Cancel any existing timer
  //   _continuousPollTimer?.cancel();
  //   _pollPacketResponseTimer?.cancel();

  //   // Reset poll packet counter after CONTROL_RES_EVENT_REPORT
  //   _pollPacketCountAfterControlRes = 0;

  //   // Store current RX counter as last known value
  //   _lastKnownRxCounter = _pktRxCnt;

  //   // Set state to receiving event logs
  //   currentBleState(BleStateMachine.receivingEventLogs);

  //   // Send first poll packet immediately (will start 100ms timeout)
  //   _pollPacketCountAfterControlRes++;
  //   logger.Logger(
  //     'Starting continuous polling - Sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT...',
  //   );
  //   _sendPollPacket();
  // }

  /// Handles event log packet response (normal poll packet responses after CONTROL_RES_EVENT_REPORT).
  void _handleEventLogPacketResponse(FrameData frame) {
    // Cancel the timeout timer since we received a response
    _pollPacketResponseTimer?.cancel();

    // Update counters and continue sending poll packets
    if (frame.payloadData.isNotEmpty) {
      List<int> technoswitchFrameBytes = convertStringListToHex(
        frame.payloadData,
      );
      if (technoswitchFrameBytes.length == 216) {
        // Update counters from response
        // Response byte 4 is panel's tx counter (our rx counter)
        // Response byte 5 is panel's rx counter (our tx counter)
        _pktRxCnt = technoswitchFrameBytes[4]; // Panel's tx = our rx
        _pktTxCnt = technoswitchFrameBytes[5]; // Panel's rx = our tx

        // Store the RX counter as last known value
        _lastKnownRxCounter = _pktRxCnt;
      }
    }

    // Continue sending poll packets - response received, so wait for next response
    _pollPacketCountAfterControlRes++;

    // Check if we've sent 100 poll packets without valid CONTROL_RES_EVENT_REPORT response
    // if (_pollPacketCountAfterControlRes >= 100) {
    //   logger.Logger(
    //     'Event log response - 100 poll packets sent after CONTROL_RES_EVENT_REPORT without valid response - Restarting from Network packet',
    //   );
    //   _restartFromNetworkPacket('Poll packet timeout (100 packets)');
    //   return;
    // }

    logger.Logger(
      'Event log response - Response received, sending poll packet #$_pollPacketCountAfterControlRes after CONTROL_RES_EVENT_REPORT...',
    );
    _sendPollPacket();
  }

  // Polling packet methods removed from handshake flow - kept for reference
  // The handshake now goes directly from network packet to passkey request
  /*
  void _requestPollingPacket1() {
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - REQUESTING POLLING PACKET 1');
    logger.Logger('========================================');

    currentBleState(BleStateMachine.sendingPollingPacket1);
    _dataTransferManager.sendingPollingPacket1ToBle(
          dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Polling packet 1 - Frame written successfully');
          logger.Logger('Polling packet 1 - Waiting for panel response...');
      } else {
          logger.Logger('Polling packet 1 - WARNING: Frame write may have failed');
        }
      },
    );
    logger.Logger('========================================\n');
  }

  void _handlePollingPacket1Response(FrameData frame) {
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - POLLING PACKET 1 RESPONSE RECEIVED');
    logger.Logger('========================================');
    logger.Logger('Polling packet 1 response - frame: $frame');
    logger.Logger('Polling packet 1 response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
      logger.Logger(
        'Polling packet 1 response - ERROR: Empty polling packet 1 response',
      );
      _emitEvent(BleHandshakeEvent.error('Empty polling packet 1 response'));
      return;
    }

    // Polling packet 1 response received successfully
      logger.Logger(
      'Polling packet 1 response - SUCCESS: Polling packet 1 acknowledged',
    );

    // Now prompt for passkey
    currentBleState(BleStateMachine.requestedPasskey);
    _emitEvent(BleHandshakeEvent.passkeyPrompt());
    logger.Logger('Polling packet 1 response - State changed to: requestedPasskey');
    logger.Logger('========================================\n');
  }
  */

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

  // void _handlePasskeyResponse(FrameData frame) {
  //   logger.Logger('TX/RX Logs - ========================================');
  //   logger.Logger('TX/RX Logs - PASSKEY RESPONSE RECEIVED');
  //   logger.Logger('TX/RX Logs - ========================================');
  //   logger.Logger('Passkey response - frame: $frame');
  //   logger.Logger('Passkey response - payload data: ${frame.payloadData}');

  //   if (frame.payloadData.isEmpty) {
  //     logger.Logger('Passkey response - ERROR: Empty passkey response');
  //     _emitEvent(BleHandshakeEvent.error('Empty passkey response'));
  //     return;
  //   }

  //   // The payload contains a nested Technoswitch frame (216 bytes)
  //   // Convert hex strings to integers
  //   List<int> technoswitchFrameBytes = convertStringListToHex(
  //     frame.payloadData,
  //   );

  //   logger.Logger(
  //     'Passkey response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
  //   );

  //   // Validate Technoswitch frame structure (should be 216 bytes)
  //   if (technoswitchFrameBytes.length != 216) {
  //     logger.Logger(
  //       'Passkey response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
  //     );
  //     _emitEvent(
  //       BleHandshakeEvent.error(
  //         'Invalid Technoswitch frame length: ${technoswitchFrameBytes.length}',
  //       ),
  //     );
  //     return;
  //   }

  //   // Validate frame markers
  //   const int frameSot = 0xFE;
  //   const int frameEot = 0xFD;
  //   if (technoswitchFrameBytes[0] != frameSot) {
  //     logger.Logger(
  //       'Passkey response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
  //     return;
  //   }
  //   if (technoswitchFrameBytes[215] != frameEot) {
  //     logger.Logger(
  //       'Passkey response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
  //     return;
  //   }

  //   // Extract packet type and check status
  //   // Structure: [0]SOT [1]dest [2]origin [3]pktTyp [4]txp [5]rxp [6-12]header [13+]payload
  //   int pktTyp = technoswitchFrameBytes[3];
  //   int mode = technoswitchFrameBytes[10];
  //   int cmd = technoswitchFrameBytes[12];
  //   int statusByte = technoswitchFrameBytes[13];
  //   String status = statusByte.toRadixString(16).padLeft(2, '0').toUpperCase();

  //   logger.Logger(
  //     'TX/RX Logs - Passkey response - Technoswitch frame parsed successfully',
  //   );
  //   logger.Logger(
  //     'TX/RX Logs - Passkey response - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (NRM=1, ACK=2)',
  //   );
  //   logger.Logger(
  //     'TX/RX Logs - Passkey response - Mode: 0x${mode.toRadixString(16).padLeft(2, '0')}, Command: 0x${cmd.toRadixString(16).padLeft(2, '0')}',
  //   );
  //   logger.Logger(
  //     'TX/RX Logs - Passkey response - Status byte at index 13: 0x$status (decimal: $statusByte)',
  //   );

  //   // Check packet type: NRM (0x01) or ACK (0x02) indicates success
  //   // Similar to old way: accept both NRM and ACK packets
  //   if (pktTyp == 1 || pktTyp == 2) {
  //     // NRM (1) or ACK (2) packet received - treat as passkey accepted
  //     logger.Logger(
  //       'TX/RX Logs - Passkey response - SUCCESS: Passkey accepted by panel (Packet Type: ${pktTyp == 1 ? "NRM" : "ACK"})',
  //     );
  //     // After passkey acceptance, handshake is complete
  //     // CONTROL_RES_EVENT_REPORT is a service command, not part of handshake
  //     logger.Logger(
  //       'TX/RX Logs - Passkey response - Handshake completed, connection established',
  //     );
  //     currentBleState(BleStateMachine.connected);
  //     _emitEvent(BleHandshakeEvent.passkeyAccepted());
  //     _emitStateChange('Handshake completed - Connection established');
  //   } else if (status == _invalidPassword) {
  //     logger.Logger(
  //       'TX/RX Logs - Passkey response - ERROR: Invalid passkey (status: 0x09)',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Invalid passkey'));
  //   } else if (status == _timeout) {
  //     logger.Logger(
  //       'TX/RX Logs - Passkey response - ERROR: Passkey validation timed out (status: 0x08)',
  //     );
  //     currentBleState(BleStateMachine.timeOut);
  //     _emitEvent(BleHandshakeEvent.error('Passkey validation timed out'));
  //   } else {
  //     logger.Logger(
  //       'TX/RX Logs - Passkey response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
  //     );
  //     _emitEvent(
  //       BleHandshakeEvent.error(
  //         'Unexpected passkey response: packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
  //       ),
  //     );
  //   }
  //   logger.Logger('========================================\n');
  // }

  // Polling packet methods removed from handshake flow - kept for reference
  // The handshake now goes directly from passkey acceptance to CONTROL_RES_EVENT_REPORT
  /*
  void _requestPollingPacket2() {
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - REQUESTING POLLING PACKET 2');
    logger.Logger('========================================');

    currentBleState(BleStateMachine.sendingPollingPacket2);
    _dataTransferManager.sendingPollingPacket2ToBle(
          dataWritten: (bool isWritten) {
            if (isWritten) {
          logger.Logger('Polling packet 2 - Frame written successfully');
          logger.Logger('Polling packet 2 - Waiting for panel response...');
      } else {
          logger.Logger('Polling packet 2 - WARNING: Frame write may have failed');
            }
          },
        );
    logger.Logger('========================================\n');
  }

  void _handlePollingPacket2Response(FrameData frame) {
    logger.Logger('========================================');
    logger.Logger('TX/RX Logs - POLLING PACKET 2 RESPONSE RECEIVED');
    logger.Logger('========================================');
    logger.Logger('Polling packet 2 response - frame: $frame');
    logger.Logger('Polling packet 2 response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
    logger.Logger(
        'Polling packet 2 response - ERROR: Empty polling packet 2 response',
      );
      _emitEvent(BleHandshakeEvent.error('Empty polling packet 2 response'));
      return;
    }

    // Polling packet 2 response received successfully
    logger.Logger(
      'Polling packet 2 response - SUCCESS: Polling packet 2 acknowledged',
    );

    // After polling packet 2, send CONTROL_RES_EVENT_REPORT command
    logger.Logger(
      'Polling packet 2 response - Sending CONTROL_RES_EVENT_REPORT command...',
    );
    _requestControlResEventReport();
    logger.Logger('========================================\n');
  }
  */

  // Dummy packet method - kept for reference but not used in simplified handshake
  /*
  void _requestDummyPacket() {
    logger.Logger('TX/RX Logs - ========================================');
    logger.Logger('TX/RX Logs - REQUESTING DUMMY PACKET');
    logger.Logger('TX/RX Logs - ========================================');
      logger.Logger(
      'TX/RX Logs - Dummy packet - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt',
    );

    // Use default event log search number (999)
    int logEvtSearchNumber = 999;

    currentBleState(BleStateMachine.sendingDummyPacket);
    _dataTransferManager.sendingDummyPacketToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      logEvtSearchNumber: logEvtSearchNumber,
        dataWritten: (bool isWritten) {
        if (isWritten) {
          logger.Logger('Dummy packet - Frame written successfully');
          logger.Logger('Dummy packet - Waiting for panel response...');
    } else {
          logger.Logger('Dummy packet - WARNING: Frame write may have failed');
        }
      },
    );
    logger.Logger('========================================\n');
  }
  */

  /// Sends CONTROL_RES_EVENT_REPORT command (service command, not part of handshake)
  /// This should be called after connection is established, similar to firmware upgrade
  /// It's used to enable event reporting/logs, not for authentication
  void requestControlResEventReport() {
    logger.Logger('TX/RX Logs - ========================================');
    logger.Logger(
      'TX/RX Logs - REQUESTING CONTROL_RES_EVENT_REPORT (Service Command)',
    );
    logger.Logger('TX/RX Logs - ========================================');
    logger.Logger(
      'TX/RX Logs - CONTROL_RES_EVENT_REPORT - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt',
    );

    // Update packet counters before sending
    // Increment TX counter for new command
    _pktTxCnt++;

    _dataTransferManager.sendingControlResEventReportToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      network: 5,
      node: 0,
      subnode: 0,
      module: 0,
      eventBufferMask: 3, // Radio event printer
      eventBufferMode: 0, // Start
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

  // void _handleDummyPacketResponse(FrameData frame) {
  //   logger.Logger('========================================');
  //   logger.Logger('DUMMY PACKET RESPONSE RECEIVED');
  //   logger.Logger('========================================');
  //   logger.Logger('Dummy packet response - frame: $frame');
  //   logger.Logger('Dummy packet response - payload data: ${frame.payloadData}');

  //   if (frame.payloadData.isEmpty) {
  //     logger.Logger(
  //       'Dummy packet response - ERROR: Empty dummy packet response',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Empty dummy packet response'));
  //     return;
  //   }

  //   // The payload contains a nested Technoswitch frame (216 bytes)
  //   // Convert hex strings to integers
  //   List<int> technoswitchFrameBytes = convertStringListToHex(
  //     frame.payloadData,
  //   );

  //   logger.Logger(
  //     'Dummy packet response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
  //   );

  //   // Validate Technoswitch frame structure (should be 216 bytes)
  //   if (technoswitchFrameBytes.length != 216) {
  //     logger.Logger(
  //       'Dummy packet response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
  //     );
  //     _emitEvent(
  //       BleHandshakeEvent.error(
  //         'Invalid Technoswitch frame length: ${technoswitchFrameBytes.length}',
  //       ),
  //     );
  //     return;
  //   }

  //   // Validate frame markers
  //   const int frameSot = 0xFE;
  //   const int frameEot = 0xFD;
  //   if (technoswitchFrameBytes[0] != frameSot) {
  //     logger.Logger(
  //       'Dummy packet response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
  //     return;
  //   }
  //   if (technoswitchFrameBytes[215] != frameEot) {
  //     logger.Logger(
  //       'Dummy packet response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
  //     );
  //     _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
  //     return;
  //   }

  //   // Check packet type - should be NRM (0x01)
  //   int pktTyp = technoswitchFrameBytes[3];
  //   logger.Logger(
  //     'Dummy packet response - Packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
  //   );

  //   // Check mode - should be DB_STATUS_INSTRUCT (0x83) or similar
  //   int mode = technoswitchFrameBytes[10];
  //   logger.Logger(
  //     'Dummy packet response - Mode: 0x${mode.toRadixString(16).padLeft(2, '0')}',
  //   );

  //   if (pktTyp == 1) {
  //     // NRM packet received successfully
  //     logger.Logger(
  //       'Dummy packet response - SUCCESS: Dummy packet acknowledged',
  //     );
  //     _pktRxCnt =
  //         technoswitchFrameBytes[4]; // Update rx counter from tx counter in response
  //     _pktTxCnt++;

  //     // Now mark as connected
  //     currentBleState(BleStateMachine.connected);
  //     _emitEvent(BleHandshakeEvent.passkeyAccepted());
  //     _emitStateChange('Handshake completed');
  //     logger.Logger('Dummy packet response - State changed to: connected');
  //   } else {
  //     logger.Logger(
  //       'Dummy packet response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
  //     );
  //     _emitEvent(
  //       BleHandshakeEvent.error(
  //         'Unexpected dummy packet response: packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
  //       ),
  //     );
  //   }
  //   logger.Logger('========================================\n');
  // }

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

  /// Handles MCU selection response
  // void _handleMcuSelectionProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) {
  //   if (data.payloadData.isEmpty) {
  //     logger.Logger('MCU Selection - Empty response');
  //     return;
  //   }

  //   final String status = data.payloadData[0];
  //   if (status == _ack) {
  //     logger.Logger('MCU Selection - ACK received');
  //     // Get UpdatesController if available
  //     if (Get.isRegistered<UpdatesController>()) {
  //       final UpdatesController updatesController =
  //           Get.find<UpdatesController>();

  //       if (updatesController.typeData == updatesController.mainMcu) {
  //         DataTransferManager().sendEofImageDataToBle(
  //           updatesController.mainMcuLast100Byte,
  //           dataWritten: (bool isWritten) {
  //             if (isWritten) {
  //               currentBleState(BleStateMachine.eofImageData);
  //             }
  //           },
  //         );
  //       } else if (updatesController.typeData == updatesController.rfMcu) {
  //         DataTransferManager().sendEofImageDataToBle(
  //           updatesController.rfMcuLast100Byte,
  //           dataWritten: (bool isWritten) {
  //             if (isWritten) {
  //               currentBleState(BleStateMachine.eofImageData);
  //             }
  //           },
  //         );
  //       } else if (updatesController.typeData == updatesController.netMcu) {
  //         DataTransferManager().sendEofImageDataToBle(
  //           updatesController.netMcuLast100Byte,
  //           dataWritten: (bool isWritten) {
  //             if (isWritten) {
  //               currentBleState(BleStateMachine.eofImageData);
  //             }
  //           },
  //         );
  //       } else {
  //         DataTransferManager().sendDataSyncRequestPacket(
  //           dataWritten: (bool isWritten) async {
  //             if (isWritten) {
  //               currentBleState(BleStateMachine.dataSyncRequest);
  //             }
  //           },
  //         );
  //       }
  //     }
  //   } else if (status == _nack) {
  //     logger.Logger('MCU Selection - NACK received');
  //     // Handle NACK - firmware upgrade failed
  //   } else {
  //     logger.Logger('MCU Selection - Unexpected response: $status');
  //   }
  // }

  /// Handles EOF image data response
  // Future<void> _handleEofImageDataProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) async {
  //   if (data.payloadData.isEmpty) {
  //     logger.Logger('EOF Image Data - Empty response');
  //     return;
  //   }

  //   final String status = data.payloadData[0];
  //   if (status == _ack) {
  //     logger.Logger('EOF Image Data - ACK received');
  //     DataTransferManager().sendDataSyncRequestPacket(
  //       dataWritten: (bool isWritten) async {
  //         if (isWritten) {
  //           currentBleState(BleStateMachine.dataSyncRequest);
  //         }
  //       },
  //     );
  //   } else if (status == _nack) {
  //     logger.Logger('EOF Image Data - NACK received');
  //     // Handle NACK - firmware upgrade failed
  //     if (Get.isRegistered<UpdatesController>()) {
  //       final UpdatesController updatesController =
  //           Get.find<UpdatesController>();
  //       updatesController.downloadingStatus.value = DownloadStatus.failed;
  //     }
  //   } else {
  //     logger.Logger('EOF Image Data - Unexpected response: $status');
  //   }
  // }

  /// Handles data sync request response
  // void _handleDataSyncRequestProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) {
  //   if (data.payloadData.isEmpty) {
  //     logger.Logger('Data Sync Request - Empty response');
  //     return;
  //   }

  //   final String status = data.payloadData[0];
  //   if (status == _ack) {
  //     logger.Logger('Data Sync Request - ACK received');
  //     currentBleState(BleStateMachine.respondedDataSyncRequest);

  //     // Start sending firmware data
  //     if (Get.isRegistered<UpdatesController>()) {
  //       final UpdatesController updatesController =
  //           Get.find<UpdatesController>();
  //       updatesController.sendFirmwareUpdateData();
  //     }
  //   } else if (status == _nack) {
  //     logger.Logger('Data Sync Request - NACK received');
  //   } else {
  //     logger.Logger('Data Sync Request - Unexpected response: $status');
  //   }
  // }

  /// Handles data start request response
  // void _handleDataStartRequestProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) {
  //   if (data.payloadData.isEmpty) {
  //     logger.Logger('Data Start Request - Empty response');
  //     return;
  //   }

  //   final String status = data.payloadData[0];
  //   if (status == _ack) {
  //     logger.Logger('Data Start Request - ACK received');
  //     currentBleState(BleStateMachine.respondedToDataStart);
  //   } else if (status == _nack) {
  //     logger.Logger('Data Start Request - NACK received');
  //   } else {
  //     logger.Logger('Data Start Request - Unexpected response: $status');
  //   }
  // }

  /// Handles large packet process response
  // void _handleLargePacketProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) {
  //   // Large packet responses are typically handled in DataTransferManager
  //   // This can be used for progress tracking or error handling
  //   logger.Logger('Large Packet Process - Response received');
  // }

  /// Handles data end request response
  // void _handleDataEndRequestProcess(
  //   FrameData data,
  //   DiscoveredDevice connectedDevice,
  // ) {
  //   if (data.payloadData.isEmpty) {
  //     logger.Logger('Data End Request - Empty response');
  //     return;
  //   }

  //   final String status = data.payloadData[0];
  //   if (status == _ack) {
  //     logger.Logger('Data End Request - ACK received');
  //     currentBleState(BleStateMachine.respondToEndPacket);

  //     // Check if there are more MCUs to update
  //     if (Get.isRegistered<UpdatesController>()) {
  //       final UpdatesController updatesController =
  //           Get.find<UpdatesController>();
  //       if (updatesController.mismatchedMcuInfos.isNotEmpty) {
  //         // Process next MCU
  //         final MCUInfo nextMcu = updatesController.mismatchedMcuInfos[0];
  //         updatesController.mismatchedMcuInfos.removeAt(0);
  //         updatesController.readBinFile(nextMcu.byteData);
  //         updatesController.selectedMcu(nextMcu.mcuType);
  //       } else {
  //         // All MCUs updated
  //         updatesController.downloadingStatus.value = DownloadStatus.completed;
  //       }
  //     }
  //   } else if (status == _nack) {
  //     logger.Logger('Data End Request - NACK received');
  //     if (Get.isRegistered<UpdatesController>()) {
  //       final UpdatesController updatesController =
  //           Get.find<UpdatesController>();
  //       updatesController.downloadingStatus.value = DownloadStatus.failed;
  //     }
  //   } else {
  //     logger.Logger('Data End Request - Unexpected response: $status');
  //   }
  // }

  @override
  void onClose() {
    // Cancel any active timers
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

/// ---------------- Enums retained from the legacy implementation ----------------

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
  //used for connection
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

  //used for create project
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

  // Large packet states
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

  // expander pass key
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
