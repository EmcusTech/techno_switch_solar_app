import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/ble_listener_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/storage/encryption_key_store.dart';

/// Handshake state enum
enum HandshakeState {
  none,
  requestingEncryptionKey,
  sendingAuthMessage,
  requestingNetworkPacket,
  sendingEmcCommands,
  completed,
}

class BleListenerHomeScreen extends StatefulWidget {
  const BleListenerHomeScreen({super.key});

  @override
  State<BleListenerHomeScreen> createState() => _BleListenerHomeScreenState();
}

class _BleListenerHomeScreenState extends State<BleListenerHomeScreen> {
  final BtUtils _btUtils = BtUtils();
  final DataTransferManager _dataTransferManager = DataTransferManager();
  bool _isSending = false;
  bool _isSendingStopEmc = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Handshake state
  HandshakeState _handshakeState = HandshakeState.none;
  int _pktTxCnt = 0;
  int _pktRxCnt = 0;
  bool _encryptionEnabled = false;

  // ACK/NACK constants
  static const String _ack = '02';
  static const String _nack = '03';
  static const String _authenticationRequired = '01';

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Sets up notification listener for receiving responses
  void _setupNotificationListener() {
    // This will be set up when device is connected
  }

  Future<void> _checkExistingConnection() async {
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice != null) {
      setState(() {
        _connectedDevice = connectedDevice;
        _isConnected = true;
        _connectionStatus =
            'Connected to: ${_btUtils.getBTDeviceName(connectedDevice)}';
      });
    }
  }

  Future<void> _connectToBle() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Scanning for devices...';
    });

    try {
      // Start scanning
      await _btUtils.scanDevices((List<ScanResult> results) async {
        if (results.isEmpty) {
          setState(() {
            _connectionStatus = 'No devices found';
            _isConnecting = false;
          });
          return;
        }

        // Try to connect to the first device found
        final device = results.first.device;
        setState(() {
          _connectionStatus =
              'Connecting to ${_btUtils.getBTDeviceName(device)}...';
        });

        await _btUtils.connectToDevice(device, (bool connected) async {
          if (connected) {
            setState(() {
              _connectedDevice = device;
              _isConnected = true;
              _isConnecting = false;
              _connectionStatus =
                  'Connected to: ${_btUtils.getBTDeviceName(device)}';
            });
            await _btUtils.stopScanning();
            // Start handshake flow
            _startHandshake();
          } else {
            setState(() {
              _connectionStatus = 'Connection failed';
              _isConnecting = false;
            });
          }
        });
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
        _isConnecting = false;
      });
      Logger('BLE Home - Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    await _btUtils.disconnect();
    _notificationSubscription?.cancel();
    setState(() {
      _connectedDevice = null;
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Disconnected';
      _handshakeState = HandshakeState.none;
      _encryptionEnabled = false;
      _pktTxCnt = 0;
      _pktRxCnt = 0;
    });
  }

  /// Starts the handshake flow: encryption key request -> auth -> network packet -> EMC commands
  Future<void> _startHandshake() async {
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice == null) {
      Logger('Handshake - No device connected');
      return;
    }

    setState(() {
      _connectionStatus = 'Starting handshake...';
      _handshakeState = HandshakeState.requestingEncryptionKey;
    });

    // Set up notification listener for handshake responses
    _btUtils.enableNotifications(
      connectedDevice,
      _handleHandshakeNotification,
      notifyEnabledcallback: (bool enabled) {
        if (!enabled) {
          Logger('Handshake - Failed to enable notifications');
          setState(() {
            _connectionStatus = 'Failed to enable notifications';
          });
          return;
        }

        // After notifications enabled, request encryption key
        Logger(
          'Handshake - Notifications enabled, requesting encryption key...',
        );
        _requestEncryptionKey();
      },
    );
  }

  /// Requests encryption key (non-encrypted)
  void _requestEncryptionKey() {
    Logger('Handshake - Requesting encryption key...');
    _dataTransferManager.requestEncryptionKey(
      dataWritten: (bool isWritten) {
        if (isWritten) {
          Logger('Handshake - Encryption key request sent');
          setState(() {
            _connectionStatus = 'Requesting encryption key...';
          });
        } else {
          Logger('Handshake - Failed to send encryption key request');
        }
      },
    );
  }

  /// Handles incoming notifications during handshake
  void _handleHandshakeNotification(List<int> data) async {
    if (data.isEmpty) return;

    Logger(
      'Handshake - Received data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );

    try {
      FrameData? frame;
      bool shouldDecrypt =
          _encryptionEnabled &&
          _handshakeState != HandshakeState.requestingEncryptionKey;

      if (shouldDecrypt) {
        try {
          // Decrypt directly without using GetX-dependent method
          String hexString = bytesToHex(data);
          List<int>? decryptedData = await EncryptionUtils().decryptData(
            hexString,
          );

          if (decryptedData == null || decryptedData.isEmpty) {
            Logger('Handshake - Decryption returned empty data');
            return;
          }

          frame = _dataTransferManager.parseRxFrame(decryptedData);
        } catch (e) {
          Logger('Handshake - Decryption failed, trying non-encrypted: $e');
          frame = _dataTransferManager.parseRxFrame(data);
        }
      } else {
        frame = _dataTransferManager.parseRxFrame(data);
      }

      if (frame == null) {
        Logger('Handshake - Failed to parse frame');
        return;
      }

      // Basic frame validation (skip GetX-dependent validation)
      if (frame.preambleByte.isEmpty ||
          frame.payloadData.isEmpty ||
          frame.endFrame.isEmpty) {
        Logger('Handshake - Invalid frame structure');
        return;
      }

      // Check preamble
      if (frame.preambleByte.length < 2 ||
          frame.preambleByte[0] != 'AA' ||
          frame.preambleByte[1] != '55') {
        Logger('Handshake - Invalid preamble: ${frame.preambleByte}');
        return;
      }

      // Check end frame
      if (frame.endFrame.length < 2 ||
          frame.endFrame[0] != 'EE' ||
          frame.endFrame[1] != 'BB') {
        Logger('Handshake - Invalid end frame: ${frame.endFrame}');
        return;
      }

      // Handle based on current handshake state
      switch (_handshakeState) {
        case HandshakeState.requestingEncryptionKey:
          await _handleEncryptionKeyResponse(frame);
          break;
        case HandshakeState.sendingAuthMessage:
          _handleAuthResponse(frame);
          break;
        case HandshakeState.requestingNetworkPacket:
          await _handleNetworkPacketResponse(frame);
          break;
        case HandshakeState.sendingEmcCommands:
          // ACK/NACK handling is done in _waitForAckNack
          // This state is maintained for tracking
          break;
        default:
          Logger('Handshake - Received frame in state: ${_handshakeState}');
          break;
      }
    } catch (e) {
      Logger('Handshake - Error handling notification: $e');
    }
  }

  /// Handles encryption key response
  Future<void> _handleEncryptionKeyResponse(FrameData frame) async {
    Logger('Handshake - Encryption key response received');
    if (frame.payloadData.isEmpty) {
      Logger('Handshake - Empty encryption key response');
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _authenticationRequired) {
      Logger('Handshake - Authentication required');
      setState(() {
        _connectionStatus = 'Authentication required';
      });
      return;
    }

    // Save encryption key
    final String keyHex =
        frame.payloadData.map((String byte) => byte.toLowerCase()).join();
    Logger('Handshake - Encryption key received: $keyHex');
    await EncryptionKeyStore.instance.saveKey(keyHex);
    _encryptionEnabled = true;

    setState(() {
      _connectionStatus = 'Encryption key received, sending auth...';
      _handshakeState = HandshakeState.sendingAuthMessage;
    });

    // Send auth packet
    _dataTransferManager.sendAuthPacket(
      dataWritten: (bool isWritten) {
        if (isWritten) {
          Logger('Handshake - Auth packet sent');
        } else {
          Logger('Handshake - Failed to send auth packet');
        }
      },
    );
  }

  /// Handles auth response
  void _handleAuthResponse(FrameData frame) {
    Logger('Handshake - Auth response received');
    if (frame.payloadData.isEmpty) {
      Logger('Handshake - Empty auth response');
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      Logger('Handshake - Auth successful, handshake completed');
      setState(() {
        _handshakeState = HandshakeState.completed;
        _connectionStatus = 'Handshake completed - Ready for commands';
      });

      Logger(
        'Handshake - Handshake completed. Commands can now be sent via buttons.',
      );
    } else if (status == _nack) {
      Logger('Handshake - Auth failed (NACK)');
      setState(() {
        _connectionStatus = 'Authentication failed';
      });
    }
  }

  /// Handles network packet response - completes handshake
  Future<void> _handleNetworkPacketResponse(FrameData frame) async {
    Logger('Handshake - Network packet response received');
    if (frame.payloadData.isEmpty) {
      Logger('Handshake - Empty network packet response');
      return;
    }

    // Parse Technoswitch frame from payload
    List<int> technoswitchFrameBytes =
        frame.payloadData
            .map((String hex) => int.parse(hex, radix: 16))
            .toList();

    if (technoswitchFrameBytes.length != 216) {
      Logger(
        'Handshake - Invalid Technoswitch frame length: ${technoswitchFrameBytes.length}',
      );
      return;
    }

    // Validate frame markers
    if (technoswitchFrameBytes[0] != 0xFE ||
        technoswitchFrameBytes[215] != 0xFD) {
      Logger('Handshake - Invalid Technoswitch frame markers');
      return;
    }

    // Check packet type
    int pktTyp = technoswitchFrameBytes[3];
    if (pktTyp == 4) {
      // NWK packet received successfully
      Logger('Handshake - Network packet received successfully');
      _pktRxCnt = technoswitchFrameBytes[4];
      _pktTxCnt++;

      setState(() {
        _handshakeState = HandshakeState.completed;
        _connectionStatus = 'Handshake completed - Ready for commands';
      });

      Logger(
        'Handshake - Handshake completed. EMC commands can now be sent via buttons.',
      );
    } else {
      Logger(
        'Handshake - Unexpected packet type: 0x${pktTyp.toRadixString(16)}',
      );
    }
  }

  // Constants for new BLE frame format
  static const int PREAMBLE_FIRST_BYTE = 0xAA;
  static const int PREAMBLE_SECOND_BYTE = 0x55;
  static const int DATA_PACKET_FRAME_TYPE_BYTE = 0x02;
  static const int END_OF_FRAME_FIRST_BYTE = 0xEE;
  static const int END_OF_FRAME_SECOND_BYTE = 0xBB;

  /// Creates a new BLE frame with all zeros as payload
  /// Format: SOF (0xAA 0x55) + CMD (2 bytes) + TOF (1 byte) + PAYLOAD LEN (2 bytes) + PAYLOAD (all zeros) + CRC (2 bytes) + EOF (0xEE 0xBB)
  Future<Uint8List> _createBleFrameWithZeroPayload({
    int payloadSize = 10,
    int command = 0x1005, // Using BLE_PANEL_CONFIG_CMD as default
  }) async {
    // Create payload with all zeros
    List<int> payload = List.filled(payloadSize, 0);

    // Build new BLE frame header
    Uint8List newBleFrame = Uint8List.fromList(<int>[
      // SOF
      PREAMBLE_FIRST_BYTE, // 0xAA
      PREAMBLE_SECOND_BYTE, // 0x55
      // CMD (2 bytes, big-endian)
      (command >> 8) & 0xFF, // MSB
      command & 0xFF, // LSB
      // TOF (Small Data Frame: 0x02)
      DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
      // PAYLOAD LEN (2 bytes, big-endian)
      (payloadSize >> 8) & 0xFF, // MSB
      payloadSize & 0xFF, // LSB
      // PAYLOAD (all zeros)
      ...payload,
    ]);

    // Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
    int calculatedCRC = convertCrc16(newBleFrame);
    Logger(
      'BLE Frame - Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})',
    );

    // Add CRC and EOF to new BLE frame
    List<int> completeBleFrame = newBleFrame.toList();
    completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
    completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
    completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

    Logger(
      'BLE Frame - Complete frame (${completeBleFrame.length} bytes) before encryption',
    );

    Logger('BLE Frame - Complete frame:hbhjb $newBleFrame');

    // Encrypt the entire new BLE frame
    Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
      data: completeBleFrame,
    );

    Logger(
      'BLE Frame - Encrypted frame (${encryptedDataPacket.length} bytes) ready for transmission',
    );

    return encryptedDataPacket;
  }

  /// Creates a BLE frame for listening command with command 0x1004
  /// Format: SOF (0xAA 0x55) + CMD (0x1004) + TOF (1 byte) + PAYLOAD LEN (2 bytes) + PAYLOAD (all zeros) + CRC (2 bytes) + EOF (0xEE 0xBB)
  Future<Uint8List> _createListeningCommandFrame({int payloadSize = 10}) async {
    // Create payload with all zeros
    List<int> payload = List.filled(payloadSize, 0);
    int command = 0x1004; // BLE_BUILD_SYSTEM_CMD

    // Build new BLE frame header
    Uint8List newBleFrame = Uint8List.fromList(<int>[
      // SOF
      PREAMBLE_FIRST_BYTE, // 0xAA
      PREAMBLE_SECOND_BYTE, // 0x55
      // CMD (2 bytes, big-endian) - 0x1004
      (command >> 8) & 0xFF, // MSB = 0x10
      command & 0xFF, // LSB = 0x04
      // TOF (Small Data Frame: 0x02)
      DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
      // PAYLOAD LEN (2 bytes, big-endian)
      (payloadSize >> 8) & 0xFF, // MSB
      payloadSize & 0xFF, // LSB
      // PAYLOAD (all zeros)
      ...payload,
    ]);

    // Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
    int calculatedCRC = convertCrc16(newBleFrame);
    Logger(
      'BLE Listening Command - Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})',
    );

    // Add CRC and EOF to new BLE frame
    List<int> completeBleFrame = newBleFrame.toList();
    completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
    completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
    completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

    Logger(
      'BLE Listening Command - Complete frame (${completeBleFrame.length} bytes) before encryption',
    );

    // Encrypt the entire new BLE frame
    Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
      data: completeBleFrame,
    );

    Logger(
      'BLE Listening Command - Encrypted frame (${encryptedDataPacket.length} bytes) ready for transmission',
    );

    return encryptedDataPacket;
  }

  /// Waits for ACK/NACK response after sending a command
  /// Returns: true for ACK, false for NACK, null for timeout/error
  Future<bool?> _waitForAckNack({
    required int expectedCommand,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice == null) {
      Logger('ACK/NACK - No device connected');
      return null;
    }

    final Completer<bool?> completer = Completer<bool?>();
    final Completer<bool> notificationReady = Completer<bool>();

    try {
      // Set up temporary notification listener
      _btUtils.enableNotifications(
        connectedDevice,
        (List<int> data) async {
          if (completer.isCompleted) return;

          try {
            Logger(
              'ACK/NACK - Received response: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
            );

            // Check if data follows new BLE protocol format
            if (data.length >= 9 && data[0] == 0xAA && data[1] == 0x55) {
              // Try to decrypt
              FrameData? frame;
              try {
                // Decrypt directly without using GetX-dependent method
                String hexString = bytesToHex(data);
                List<int>? decryptedData = await EncryptionUtils().decryptData(
                  hexString,
                );

                Logger('ACK/NACK - Decrypted hex data: $decryptedData');

                if (decryptedData != null && decryptedData.isNotEmpty) {
                  frame = _dataTransferManager.parseRxFrame(decryptedData);
                } else {
                  // If decryption returns empty, try parsing as non-encrypted
                  frame = _dataTransferManager.parseRxFrame(data);
                }
              } catch (e) {
                // If decryption fails, try parsing as non-encrypted
                Logger('ACK/NACK - Decryption failed: $e');
                frame = _dataTransferManager.parseRxFrame(data);
              }

              if (frame != null && frame.payloadData.isNotEmpty) {
                // Check command matches (optional - response might have different command)
                if (frame.commandByte.length >= 2) {
                  int cmdValue =
                      (int.parse(frame.commandByte[0], radix: 16) << 8) |
                      int.parse(frame.commandByte[1], radix: 16);

                  Logger(
                    'ACK/NACK - Response command: 0x${cmdValue.toRadixString(16).padLeft(4, '0')}, Expected: 0x${expectedCommand.toRadixString(16).padLeft(4, '0')}',
                  );
                }

                // Check payload for ACK/NACK status
                final String status = frame.payloadData.first;
                Logger('ACK/NACK - Status: $status');

                if (status == _ack) {
                  Logger('ACK/NACK - ACK received (0x02)');
                  if (!completer.isCompleted) {
                    completer.complete(true);
                  }
                } else if (status == _nack) {
                  Logger('ACK/NACK - NACK received (0x03)');
                  if (!completer.isCompleted) {
                    completer.complete(false);
                  }
                }
              }
            }
          } catch (e) {
            Logger('ACK/NACK - Error parsing response: $e');
          }
        },
        notifyEnabledcallback: (bool enabled) {
          if (!notificationReady.isCompleted) {
            notificationReady.complete(enabled);
          }
          if (!enabled) {
            Logger('ACK/NACK - Failed to enable notifications');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
      );

      // Wait for notifications to be enabled (with short timeout)
      final notificationsEnabled = await notificationReady.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          Logger('ACK/NACK - Timeout enabling notifications');
          return false;
        },
      );

      // Only wait for response if notifications were enabled
      if (!notificationsEnabled) {
        Logger('ACK/NACK - Notifications not enabled');
        return null;
      }

      // Wait for response with timeout
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          Logger('ACK/NACK - Timeout waiting for response');
          return null;
        },
      );

      return result;
    } catch (e) {
      Logger('ACK/NACK - Error: $e');
      return null;
    }
  }

  /// Sends the listening command (0x1004) to start listening
  Future<void> _sendListeningCommand() async {
    Logger('BLE Listening Command - Sending listening command');
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice == null) {
      Logger('BLE Listening Command - No device connected');
      return;
    }

    try {
      // Create listening command frame with command 0x1004
      final frame = await _createListeningCommandFrame(
        payloadSize: 10, // 10 bytes of zeros
      );

      Logger('BLE Listening Command - Frame created: ${frame.toList()}');

      // Send the frame
      bool writeSuccess = false;
      await _btUtils.writeData(
        connectedDevice,
        frame.toList(),
        dataWritten: (bool success) {
          writeSuccess = success;
          if (success) {
            Logger(
              'BLE Listening Command - Listening command sent successfully',
            );
          } else {
            Logger('BLE Listening Command - Failed to send listening command');
          }
        },
      );

      if (writeSuccess) {
        // Wait for ACK/NACK response
        Logger('BLE Listening Command - Waiting for ACK/NACK...');
        final ackResult = await _waitForAckNack(
          expectedCommand: 0x1004,
          timeout: const Duration(seconds: 5),
        );

        if (ackResult == true) {
          Logger('BLE Listening Command - ACK received - Command successful');
        } else if (ackResult == false) {
          Logger('BLE Listening Command - NACK received - Command failed');
        } else {
          Logger(
            'BLE Listening Command - No response received (timeout or error)',
          );
        }
      }
    } catch (e) {
      Logger('BLE Listening Command - Error: $e');
    }
  }

  Future<void> _sendBleCommand() async {
    if (_handshakeState != HandshakeState.completed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for handshake to complete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Logger('BLE Command - Sending BLE command');
    // Check if device is connected
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No BLE device connected. Please connect first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Create BLE frame with all zeros as payload
      final frame = await _createBleFrameWithZeroPayload(
        payloadSize: 10, // 10 bytes of zeros
        command: BleCommandsList.BLE_PANEL_CONFIG_CMD.value,
      );

      Logger('BLE Command - Frame created: ${frame.toList()}');

      // Send the frame
      bool writeSuccess = false;
      await _btUtils.writeData(
        connectedDevice,
        frame.toList(),
        dataWritten: (bool success) {
          writeSuccess = success;
          if (success) {
            Logger('BLE Command - Command sent successfully');
          } else {
            Logger('BLE Command - Failed to send command');
          }
        },
      );

      if (writeSuccess) {
        // Wait for ACK/NACK response
        Logger('BLE Command - Waiting for ACK/NACK...');
        final ackResult = await _waitForAckNack(
          expectedCommand: BleCommandsList.BLE_PANEL_CONFIG_CMD.value,
          timeout: const Duration(seconds: 5),
        );

        if (mounted) {
          setState(() {
            _isSending = false;
          });

          String message;
          Color backgroundColor;

          if (ackResult == true) {
            message = 'BLE command sent successfully - ACK received';
            backgroundColor = Colors.green;
            Logger('BLE Command - ACK received - Command successful');
          } else if (ackResult == false) {
            message = 'BLE command failed - NACK received';
            backgroundColor = Colors.orange;
            Logger('BLE Command - NACK received - Command failed');
          } else {
            message = 'BLE command sent - No response received';
            backgroundColor = Colors.blue;
            Logger('BLE Command - No response received (timeout or error)');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: backgroundColor),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSending = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send BLE command'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      Logger('BLE Command - Frame sent to device');
    } catch (e) {
      Logger('BLE Command - Error: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending command: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sends the stop EMC test command (0x1006)
  Future<void> _sendStopEmcTestCommand() async {
    if (_handshakeState != HandshakeState.completed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for handshake to complete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    Logger('BLE Stop EMC Test Command - Sending stop EMC test command');
    final connectedDevice = await _btUtils.getConnectedDevices();
    if (connectedDevice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No BLE device connected. Please connect first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSendingStopEmc = true;
    });

    try {
      // Create BLE frame with command 0x1006 and all zeros as payload
      final frame = await _createBleFrameWithZeroPayload(
        payloadSize: 10, // 10 bytes of zeros
        command: BleCommandsList.BLE_PANEL_DOWNLOAD_CONFIG_FROM_BLE_CMD.value,
      );

      Logger('BLE Stop EMC Test Command - Frame created: ${frame.toList()}');

      // Send the frame
      bool writeSuccess = false;
      await _btUtils.writeData(
        connectedDevice,
        frame.toList(),
        dataWritten: (bool success) {
          writeSuccess = success;
          if (success) {
            Logger('BLE Stop EMC Test Command - Command sent successfully');
          } else {
            Logger('BLE Stop EMC Test Command - Failed to send command');
          }
        },
      );

      if (writeSuccess) {
        // Wait for ACK/NACK response
        Logger('BLE Stop EMC Test Command - Waiting for ACK/NACK...');
        final ackResult = await _waitForAckNack(
          expectedCommand:
              BleCommandsList.BLE_PANEL_DOWNLOAD_CONFIG_FROM_BLE_CMD.value,
          timeout: const Duration(seconds: 5),
        );

        if (mounted) {
          setState(() {
            _isSendingStopEmc = false;
          });

          String message;
          Color backgroundColor;

          if (ackResult == true) {
            message = 'Stop EMC test command sent - ACK received';
            backgroundColor = Colors.green;
            Logger(
              'BLE Stop EMC Test Command - ACK received - Command successful',
            );
          } else if (ackResult == false) {
            message = 'Stop EMC test command failed - NACK received';
            backgroundColor = Colors.orange;
            Logger(
              'BLE Stop EMC Test Command - NACK received - Command failed',
            );
          } else {
            message = 'Stop EMC test command sent - No response received';
            backgroundColor = Colors.blue;
            Logger(
              'BLE Stop EMC Test Command - No response received (timeout or error)',
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: backgroundColor),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSendingStopEmc = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send stop EMC test command'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      Logger('BLE Stop EMC Test Command - Frame sent to device');
    } catch (e) {
      Logger('BLE Stop EMC Test Command - Error: $e');
      if (mounted) {
        setState(() {
          _isSendingStopEmc = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending stop EMC test command: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_searching,
                  size: 80,
                  color: Color(0xFFEC1D24),
                ),
                SizedBox(height: 32),
                Text(
                  'TechnoSwitch BLE Test',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Connect and listen to BLE data continuously',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                // Connection status card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: _isConnected ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _connectionStatus,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D3D3D),
                              ),
                            ),
                            if (_isConnected && _connectedDevice != null)
                              Text(
                                _btUtils.getBTDeviceName(_connectedDevice!),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!_isConnected && !_isConnecting)
                        ElevatedButton(
                          onPressed: _connectToBle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEC1D24),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text('Connect'),
                        ),
                      if (_isConnecting)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFEC1D24),
                            ),
                          ),
                        ),
                      if (_isConnected)
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: _disconnect,
                          tooltip: 'Disconnect',
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                // ElevatedButton(
                //   onPressed:
                //       (_isConnected &&
                //               _handshakeState == HandshakeState.completed)
                //           ? () async {
                //             // Navigate to listener screen
                //             if (mounted) {
                //               Navigator.of(context).push(
                //                 MaterialPageRoute(
                //                   builder:
                //                       (context) => const BleListenerScreen(),
                //                 ),
                //               );
                //             }
                //           }
                //           : null,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Color(0xFFEC1D24),
                //     foregroundColor: Colors.white,
                //     padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     elevation: 4,
                //   ),
                //   child: Text(
                //     'Start Listening',
                //     style: GoogleFonts.inter(
                //       fontSize: 18,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      (_isSending ||
                              !_isConnected ||
                              _handshakeState != HandshakeState.completed)
                          ? null
                          : () async {
                            // Send listening command
                            _sendListeningCommand();
                            // Navigate to listener screen
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => const BleListenerScreen(),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child:
                      _isSending
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Start Listening',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      (_isSending ||
                              !_isConnected ||
                              _handshakeState != HandshakeState.completed)
                          ? null
                          : _sendBleCommand,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child:
                      _isSending
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Start EMC Test',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
                SizedBox(height: 24),
                // ElevatedButton(
                //   onPressed:
                //       (_isSendingStopEmc ||
                //               !_isConnected ||
                //               _handshakeState != HandshakeState.completed)
                //           ? null
                //           : _sendStopEmcTestCommand,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Color(0xFFFF9800),
                //     foregroundColor: Colors.white,
                //     padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     elevation: 4,
                //   ),
                //   child:
                //       _isSendingStopEmc
                //           ? SizedBox(
                //             width: 20,
                //             height: 20,
                //             child: CircularProgressIndicator(
                //               strokeWidth: 2,
                //               valueColor: AlwaysStoppedAnimation<Color>(
                //                 Colors.white,
                //               ),
                //             ),
                //           )
                //           : Text(
                //             'Stop EMC Test (0x1006)',
                //             style: GoogleFonts.inter(
                //               fontSize: 18,
                //               fontWeight: FontWeight.w600,
                //             ),
                //           ),
                // ),
                SizedBox(height: 16),
                Text(
                  'Sends a new BLE frame with all zeros as payload',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
