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

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/utils/storage/encryption_key_store.dart';

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

  /// Enable notifications on the currently connected BLE device.
  Future<void> enableNotifyForCallBack() async {
    final BluetoothDevice? connectedDevice =
        await BtUtils().getConnectedDevices();
    if (connectedDevice == null) {
      Logger('BLE notify handler: no connected device found.');
      _emitEvent(
        BleHandshakeEvent.error('Device disconnected before handshake'),
      );
      return;
    }

    BtUtils().enableNotifications(
      connectedDevice,
      (List<int> data) {
        if (connectedDevice.isConnected) {
          _handleNotifyData(data, connectedDevice);
        }
      },
      notifyEnabledcallback: (bool enabled) {
        if (!enabled) {
          _emitEvent(
            BleHandshakeEvent.error(
              'Unable to enable notifications on primary characteristic',
            ),
          );
          return;
        }

        _dataTransferManager.requestEncryptionKey(
          dataWritten: (bool isWritten) {
            if (isWritten) {
              currentBleState(BleStateMachine.reqEncryptionKey);
              _emitStateChange('Requesting encryption key');
            }
          },
        );
      },
    );
  }

  /// Sends the user provided passkey back to the panel.
  Future<void> submitPasskey(String passkey) async {
    Logger('========================================');
    Logger('SUBMITTING PASSKEY');
    Logger('========================================');
    Logger('Passkey value: "$passkey"');
    Logger('Passkey length: ${passkey.length} characters');

    if (passkey.isEmpty) {
      Logger('Passkey submission - ERROR: Passkey cannot be empty');
      _emitEvent(BleHandshakeEvent.error('Passkey cannot be empty'));
      return;
    }

    Logger('Passkey submission - Calling sendingPasskeyToBle()');
    _dataTransferManager.sendingPasskeyToBle(
      passkey,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          Logger('Passkey submission - Frame written successfully');
          Logger('Passkey submission - State changing to: passkeyEntered');
          currentBleState(BleStateMachine.passkeyEntered);
          _emitStateChange('Passkey sent to panel');
          Logger('Passkey submission - Waiting for panel response...');
        } else {
          Logger('Passkey submission - WARNING: Frame write may have failed');
        }
      },
    );
    Logger('========================================\n');
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

  void _handleNotifyData(List<int> rxData, BluetoothDevice device) async {
    if (rxData.isEmpty) {
      return;
    }

    // Stop any outstanding timers – we received a response.
    _dataTransferManager.stopResponseTimer();

    FrameData? frame;
    final bool shouldDecrypt =
        encryptionDecryptionState.value == EncryptionDecryptionState.enabled &&
        currentBleState.value != BleStateMachine.reqEncryptionKey;

    if (shouldDecrypt) {
      try {
        frame = await DataHandler().decryptTheDataPacketWithoutConversion(
          rxData,
        );
      } catch (e) {
        Logger('BLE notify: failed to decrypt frame $e');
      }
    } else {
      // Non-encrypted RX (encryption key response)
      Logger('========================================');
      Logger('TX/RX Logs - STEP 2: RECEIVE ENCRYPTION KEY (RX)');
      Logger('========================================');
      String rxHex = rxData
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');
      String rxAscii = _bytesToAscii(rxData);
      Logger('TX/RX Logs - Non-encrypted RX Data (${rxData.length} bytes):');
      Logger('TX/RX Logs - Hex: $rxHex');
      Logger('TX/RX Logs - ASCII: $rxAscii');
      Logger('TX/RX Logs - Current State: ${currentBleState.value.name}');

      frame = _dataTransferManager.parseRxFrame(rxData);

      if (frame.commandByte.isNotEmpty && frame.commandByte.length >= 2) {
        int cmdValue =
            (int.parse(frame.commandByte[0], radix: 16) << 8) |
            int.parse(frame.commandByte[1], radix: 16);
        Logger(
          'TX/RX Logs - Command: 0x${cmdValue.toRadixString(16).padLeft(4, '0')}',
        );
      }
      Logger('TX/RX Logs - Frame Type: ${frame.frameTypeByte}');
      Logger('TX/RX Logs - Payload Length: ${frame.payloadData.length} bytes');
      Logger('TX/RX Logs - ========================================\n');
    }

    if (frame == null) {
      _emitEvent(BleHandshakeEvent.error('Unable to parse BLE frame'));
      return;
    }

    _processFrame(frame, device);
  }

  void _processFrame(FrameData frame, BluetoothDevice connectedDevice) {
    final bool isValid = DataHandler().frameValidation(
      frame,
      errorCode: (String error) {
        Logger('BLE frame validation error: $error');
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
      case BleStateMachine.requestedPasskey:
        _handlePassKeyRequestResponse(frame, connectedDevice);
        break;
      case BleStateMachine.passkeyEntered:
        _handlePasskeyResponse(frame);
        break;
      case BleStateMachine.sendingDummyPacket:
        _handleDummyPacketResponse(frame);
        break;
      default:
        // For now we only care about the connect/auth flow.
        Logger(
          'BLE notify: frame received for state ${currentBleState.value.name}',
        );
        break;
    }
  }

  Future<void> _handleEncryptionReqResponse(FrameData frame) async {
    Logger('Encryption key -  frame: $frame');
    if (frame.payloadData.isEmpty) {
      Logger('Encryption key -  empty response');
      _emitEvent(BleHandshakeEvent.error('Empty encryption response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _authenticationRequired) {
      Logger('Encryption key -  authentication required');
      _emitEvent(BleHandshakeEvent.error('Authentication required by panel'));
      return;
    }

    final String keyHex =
        frame.payloadData.map((String byte) => byte.toLowerCase()).join();
    Logger('Encryption key -  payload bytes: ${frame.payloadData}');
    Logger('Encryption key -  (hex): $keyHex');
    await EncryptionKeyStore.instance.saveKey(keyHex);
    encryptionDecryptionState(EncryptionDecryptionState.enabled);

    _emitEvent(
      BleHandshakeEvent(
        BleHandshakeEventType.encryptionKeyReceived,
        state: currentBleState.value,
      ),
    );

    _dataTransferManager.sendAuthPacket(
      dataWritten: (bool isWritten) {
        if (isWritten) {
          currentBleState(BleStateMachine.sendingAuthMessage);
          _emitStateChange('Sent authentication message');
        }
      },
    );
  }

  void _handleAuthMsgResponse(FrameData frame) {
    Logger('Authentication message -  frame: $frame');
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty auth response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      _emitEvent(BleHandshakeEvent.authenticated());
      // After authentication, request network packet first (old way)
      Logger('Authentication successful - requesting network packet...');
      _requestNetworkPacket();
    } else if (status == _nack) {
      _emitEvent(BleHandshakeEvent.error('Auth message rejected by panel'));
    } else {
      _emitEvent(BleHandshakeEvent.error('Unexpected auth response: $status'));
    }
  }

  void _requestNetworkPacket() {
    Logger('========================================');
    Logger('REQUESTING NETWORK PACKET');
    Logger('========================================');
    Logger('Network packet - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt');

    currentBleState(BleStateMachine.requestingNetworkPacket);
    _dataTransferManager.sendingNetworkPacketToBle(
      pktTxCnt: _pktTxCnt,
      pktRxCnt: _pktRxCnt,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          Logger('Network packet - Frame written successfully');
          Logger('Network packet - Waiting for panel response...');
        } else {
          Logger('Network packet - WARNING: Frame write may have failed');
        }
      },
    );
    Logger('========================================\n');
  }

  void _handleNetworkPacketResponse(FrameData frame) {
    Logger('========================================');
    Logger('NETWORK PACKET RESPONSE RECEIVED');
    Logger('========================================');
    Logger('Network packet response - frame: $frame');
    Logger('Network packet response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
      Logger('Network packet response - ERROR: Empty network packet response');
      _emitEvent(BleHandshakeEvent.error('Empty network packet response'));
      return;
    }

    // The payload contains a nested Technoswitch frame (216 bytes)
    // Convert hex strings to integers
    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    Logger(
      'Network packet response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
    );

    // Validate Technoswitch frame structure (should be 216 bytes)
    if (technoswitchFrameBytes.length != 216) {
      Logger(
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
      Logger(
        'Network packet response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
      return;
    }
    if (technoswitchFrameBytes[215] != frameEot) {
      Logger(
        'Network packet response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
      return;
    }

    // Check packet type - should be NWK (0x04)
    int pktTyp = technoswitchFrameBytes[3];
    Logger(
      'Network packet response - Packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
    );

    if (pktTyp == 4) {
      // NWK packet received successfully
      Logger('Network packet response - SUCCESS: Network packet received');
      _pktRxCnt =
          technoswitchFrameBytes[4]; // Update rx counter from tx counter in response
      _pktTxCnt++;

      // Now prompt for passkey
      currentBleState(BleStateMachine.requestedPasskey);
      _emitEvent(BleHandshakeEvent.passkeyPrompt());
      Logger('Network packet response - State changed to: requestedPasskey');
    } else {
      Logger(
        'Network packet response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
      );
      _emitEvent(
        BleHandshakeEvent.error(
          'Unexpected network packet response: packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
        ),
      );
    }
    Logger('========================================\n');
  }

  void _handlePassKeyRequestResponse(FrameData frame, BluetoothDevice device) {
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

  void _handlePasskeyResponse(FrameData frame) {
    Logger('TX/RX Logs - ========================================');
    Logger('TX/RX Logs - PASSKEY RESPONSE RECEIVED');
    Logger('TX/RX Logs - ========================================');
    Logger('Passkey response - frame: $frame');
    Logger('Passkey response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
      Logger('Passkey response - ERROR: Empty passkey response');
      _emitEvent(BleHandshakeEvent.error('Empty passkey response'));
      return;
    }

    // The payload contains a nested Technoswitch frame (216 bytes)
    // Convert hex strings to integers
    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    Logger(
      'Passkey response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
    );

    // Validate Technoswitch frame structure (should be 216 bytes)
    if (technoswitchFrameBytes.length != 216) {
      Logger(
        'Passkey response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
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
      Logger(
        'Passkey response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
      return;
    }
    if (technoswitchFrameBytes[215] != frameEot) {
      Logger(
        'Passkey response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
      return;
    }

    // Extract packet type and check status
    // Structure: [0]SOT [1]dest [2]origin [3]pktTyp [4]txp [5]rxp [6-12]header [13+]payload
    int pktTyp = technoswitchFrameBytes[3];
    int mode = technoswitchFrameBytes[10];
    int cmd = technoswitchFrameBytes[12];
    int statusByte = technoswitchFrameBytes[13];
    String status = statusByte.toRadixString(16).padLeft(2, '0').toUpperCase();

    Logger(
      'TX/RX Logs - Passkey response - Technoswitch frame parsed successfully',
    );
    Logger(
      'TX/RX Logs - Passkey response - Packet Type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')} (NRM=1, ACK=2)',
    );
    Logger(
      'TX/RX Logs - Passkey response - Mode: 0x${mode.toRadixString(16).padLeft(2, '0')}, Command: 0x${cmd.toRadixString(16).padLeft(2, '0')}',
    );
    Logger(
      'TX/RX Logs - Passkey response - Status byte at index 13: 0x$status (decimal: $statusByte)',
    );

    // Check packet type: NRM (0x01) or ACK (0x02) indicates success
    // Similar to old way: accept both NRM and ACK packets
    if (pktTyp == 1 || pktTyp == 2) {
      Logger('skjbskjbs $pktTyp');
      // NRM (1) or ACK (2) packet received - treat as passkey accepted
      Logger(
        'TX/RX Logs - Passkey response - SUCCESS: Passkey accepted by panel (Packet Type: ${pktTyp == 1 ? "NRM" : "ACK"})',
      );
      // After passkey acceptance, send CONTROL_RES_EVENT_REPORT command
      Logger(
        'TX/RX Logs - Passkey response - Sending CONTROL_RES_EVENT_REPORT command...',
      );
      _requestControlResEventReport();
    } else if (status == _invalidPassword) {
      Logger(
        'TX/RX Logs - Passkey response - ERROR: Invalid passkey (status: 0x09)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid passkey'));
    } else if (status == _timeout) {
      Logger(
        'TX/RX Logs - Passkey response - ERROR: Passkey validation timed out (status: 0x08)',
      );
      currentBleState(BleStateMachine.timeOut);
      _emitEvent(BleHandshakeEvent.error('Passkey validation timed out'));
    } else {
      Logger(
        'TX/RX Logs - Passkey response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
      );
      _emitEvent(
        BleHandshakeEvent.error(
          'Unexpected passkey response: packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
        ),
      );
    }
    Logger('========================================\n');
  }

  void _requestDummyPacket() {
    Logger('TX/RX Logs - ========================================');
    Logger('TX/RX Logs - REQUESTING DUMMY PACKET');
    Logger('TX/RX Logs - ========================================');
    Logger(
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
          Logger('Dummy packet - Frame written successfully');
          Logger('Dummy packet - Waiting for panel response...');
        } else {
          Logger('Dummy packet - WARNING: Frame write may have failed');
        }
      },
    );
    Logger('========================================\n');
  }

  void _requestControlResEventReport() {
    Logger('TX/RX Logs - ========================================');
    Logger('TX/RX Logs - REQUESTING CONTROL_RES_EVENT_REPORT');
    Logger('TX/RX Logs - ========================================');
    Logger(
      'TX/RX Logs - CONTROL_RES_EVENT_REPORT - pktTxCnt: $_pktTxCnt, pktRxCnt: $_pktRxCnt',
    );

    // Update packet counters before sending
    // Increment TX counter for new command
    _pktTxCnt++;

    currentBleState(BleStateMachine.connected);
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
          Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - Frame written successfully',
          );
          Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - Waiting for panel response...',
          );
          // Mark handshake as completed after sending the command
          _emitEvent(BleHandshakeEvent.passkeyAccepted());
          _emitStateChange(
            'Handshake completed - CONTROL_RES_EVENT_REPORT sent',
          );
        } else {
          Logger(
            'TX/RX Logs - CONTROL_RES_EVENT_REPORT - WARNING: Frame write may have failed',
          );
          _emitEvent(
            BleHandshakeEvent.error('Failed to send CONTROL_RES_EVENT_REPORT'),
          );
        }
      },
    );
    Logger('TX/RX Logs - ========================================\n');
  }

  void _handleDummyPacketResponse(FrameData frame) {
    Logger('========================================');
    Logger('DUMMY PACKET RESPONSE RECEIVED');
    Logger('========================================');
    Logger('Dummy packet response - frame: $frame');
    Logger('Dummy packet response - payload data: ${frame.payloadData}');

    if (frame.payloadData.isEmpty) {
      Logger('Dummy packet response - ERROR: Empty dummy packet response');
      _emitEvent(BleHandshakeEvent.error('Empty dummy packet response'));
      return;
    }

    // The payload contains a nested Technoswitch frame (216 bytes)
    // Convert hex strings to integers
    List<int> technoswitchFrameBytes = convertStringListToHex(
      frame.payloadData,
    );

    Logger(
      'Dummy packet response - Technoswitch frame length: ${technoswitchFrameBytes.length} bytes',
    );

    // Validate Technoswitch frame structure (should be 216 bytes)
    if (technoswitchFrameBytes.length != 216) {
      Logger(
        'Dummy packet response - ERROR: Invalid Technoswitch frame length: ${technoswitchFrameBytes.length} bytes (expected 216)',
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
      Logger(
        'Dummy packet response - ERROR: Invalid SOT: 0x${technoswitchFrameBytes[0].toRadixString(16).padLeft(2, '0')} (expected 0xFE)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame SOT'));
      return;
    }
    if (technoswitchFrameBytes[215] != frameEot) {
      Logger(
        'Dummy packet response - ERROR: Invalid EOT: 0x${technoswitchFrameBytes[215].toRadixString(16).padLeft(2, '0')} (expected 0xFD)',
      );
      _emitEvent(BleHandshakeEvent.error('Invalid Technoswitch frame EOT'));
      return;
    }

    // Check packet type - should be NRM (0x01)
    int pktTyp = technoswitchFrameBytes[3];
    Logger(
      'Dummy packet response - Packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
    );

    // Check mode - should be DB_STATUS_INSTRUCT (0x83) or similar
    int mode = technoswitchFrameBytes[10];
    Logger(
      'Dummy packet response - Mode: 0x${mode.toRadixString(16).padLeft(2, '0')}',
    );

    if (pktTyp == 1) {
      // NRM packet received successfully
      Logger('Dummy packet response - SUCCESS: Dummy packet acknowledged');
      _pktRxCnt =
          technoswitchFrameBytes[4]; // Update rx counter from tx counter in response
      _pktTxCnt++;

      // Now mark as connected
      currentBleState(BleStateMachine.connected);
      _emitEvent(BleHandshakeEvent.passkeyAccepted());
      _emitStateChange('Handshake completed');
      Logger('Dummy packet response - State changed to: connected');
    } else {
      Logger(
        'Dummy packet response - ERROR: Unexpected packet type: 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
      );
      _emitEvent(
        BleHandshakeEvent.error(
          'Unexpected dummy packet response: packet type 0x${pktTyp.toRadixString(16).padLeft(2, '0')}',
        ),
      );
    }
    Logger('========================================\n');
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
