import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

class BleListenerScreen extends StatefulWidget {
  const BleListenerScreen({super.key});

  @override
  State<BleListenerScreen> createState() => _BleListenerScreenState();
}

class _BleListenerScreenState extends State<BleListenerScreen> {
  final BtUtils _btUtils = BtUtils();
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _notificationSubscription;
  final List<String> _receivedData = [];
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false; // Add flag to prevent duplicate listeners

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only recheck if we're not already listening
    if (!_isListening) {
      _checkExistingConnection();
    }
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
      _startListening();
    } else {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Not connected. Please connect from home screen.';
      });
    }
  }

  void _startListening() {
    if (_connectedDevice == null || _isListening)
      return; // Prevent duplicate calls

    _isListening = true; // Set flag before enabling notifications

    // Enable notifications and listen for data
    _btUtils.enableNotifications(
      _connectedDevice!,
      (List<int> data) {
        _onDataReceived(data);
      },
      notifyEnabledcallback: (bool enabled) {
        if (enabled) {
          setState(() {
            _connectionStatus = 'Listening for data...';
          });
          Logger('BLE Listener - Notifications enabled');
        } else {
          setState(() {
            _connectionStatus = 'Failed to enable notifications';
            _isListening = false; // Reset flag on failure
          });
          Logger('BLE Listener - Failed to enable notifications');
        }
      },
    );
  }

  void _onDataReceived(List<int> rawData) {
    if (rawData.isEmpty) return;

    final timestamp = DateTime.now();
    final hexString = rawData
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');

    // Try to parse using new BLE protocol
    _parseAndDisplayData(rawData, hexString, timestamp);
  }

  /// Extracts payload bytes from decrypted frame data
  List<int> _extractPayloadBytes(List<int> decryptedData) {
    try {
      // Parse frame to get payload
      // Format: SOF (2) + CMD (2) + TOF (1) + PAYLOAD LEN (2) + PAYLOAD + CRC (2) + EOF (2)
      if (decryptedData.length < 9) return [];

      // Skip SOF (2 bytes), CMD (2 bytes), TOF (1 byte) = 5 bytes
      // Read payload length (2 bytes, little-endian)
      int payloadLen = decryptedData[6] | (decryptedData[5] << 8);

      Logger('Payload Length: $payloadLen');

      if (payloadLen == 0 || decryptedData.length < 7 + payloadLen + 4) {
        return [];
      }

      // Extract payload (skip 7 bytes header, take payloadLen bytes)
      return decryptedData.sublist(7, 7 + payloadLen);
    } catch (e) {
      return [];
    }
  }

  String decimalsToAscii(List<int> codes) {
    // Optional: validate input range
    for (final code in codes) {
      if (code < 0 || code > 255) {
        throw ArgumentError('All codes must be between 0 and 255. Got: $code');
      }
    }

    return String.fromCharCodes(codes);
  }

  Future<void> _parseAndDisplayData(
    List<int> rawData,
    String hexString,
    DateTime timestamp,
  ) async {
    String displayData = '';
    Logger('BLE Listener - Raw data: $rawData');
    String hexStringData = bytesToHex(rawData);
    List<int>? decryptedData = await EncryptionUtils().decryptData(
      hexStringData,
    );

    displayData = decimalsToAscii(_extractPayloadBytes(decryptedData!));

    // try {
    //   // Check if data follows new BLE protocol format
    //   // New BLE Format: SOF (0xAA 0x55) + CMD (2) + TOF (1) + PAYLOAD LEN (2) + PAYLOAD + CRC (2) + EOF (0xEE 0xBB)
    //   if (rawData.length >= 9 && rawData[0] == 0xAA && rawData[1] == 0x55) {
    //     // Try to decrypt if encryption is enabled
    //     try {
    //       // Decrypt directly without using GetX-dependent method
    //       String hexStringData = bytesToHex(rawData);
    //       List<int>? decryptedData = await EncryptionUtils().decryptData(
    //         hexStringData,
    //       );

    //       if (decryptedData != null && decryptedData.isNotEmpty) {
    //         // Extract payload bytes from decrypted data
    //         List<int> payloadBytes = _extractPayloadBytes(decryptedData);
    //         if (payloadBytes.isNotEmpty) {
    //           // Convert only payload to ASCII
    //           displayData = payloadBytes.toString();
    //         } else {
    //           displayData = 'No payload found';
    //         }
    //       } else {
    //         displayData = 'Decryption returned empty';
    //         // // Decryption returned empty, try parsing as non-encrypted
    //         // final DataTransferManager dataTransferManager =
    //         //     DataTransferManager();
    //         // final frame = dataTransferManager.parseRxFrame(rawData);

    //         // if (frame != null && frame.payloadData.isNotEmpty) {
    //         //   displayData = _payloadToAscii(frame.payloadData);
    //         // } else {
    //         //   displayData = _extractPayloadFromRaw(rawData);
    //         //   if (displayData.isEmpty) {
    //         //     displayData = 'No payload found';
    //         //   }
    //         // }
    //       }
    //     } catch (e) {
    //       // If decryption fails, try parsing as non-encrypted
    //       try {
    //         // Extract payload bytes from raw data and convert to ASCII
    //         List<int> payloadBytes = _extractPayloadBytes(rawData);
    //         if (payloadBytes.isNotEmpty) {
    //           displayData = decimalsToAscii(payloadBytes);
    //         } else {
    //           displayData = 'Decryption/parsing failed: $e';
    //         }
    //       } catch (parseError) {
    //         displayData = 'Error parsing data: $parseError';
    //       }
    //     }
    //   } else {
    //     // Old format or unknown format
    //     displayData = 'Unknown format';
    //   }
    // } catch (e) {
    //   displayData = 'Parse Error: $e';
    // }

    if (mounted) {
      setState(() {
        _receivedData.insert(
          0,
          '[${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}.'
          '${timestamp.millisecond.toString().padLeft(3, '0')}] $displayData',
        );

        // Keep only last 100 entries
        if (_receivedData.length > 100) {
          _receivedData.removeLast();
        }
      });

      // Auto-scroll to top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    Logger('BLE Listener - Payload (ASCII): $displayData');
  }

  Future<void> _disconnect() async {
    await _notificationSubscription?.cancel();
    _isListening = false; // Reset flag on disconnect
    await _btUtils.disconnect();
    setState(() {
      _connectedDevice = null;
      _isConnected = false;
      _connectionStatus = 'Disconnected';
      _receivedData.clear();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _isListening = false; // Reset flag on dispose
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TechnoSwitch BLE Test',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFEC1D24),
        foregroundColor: Colors.white,
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Connection status card
            Container(
              margin: EdgeInsets.all(16),
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
                            fontSize: 16,
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
                  if (!_isConnected)
                    Text(
                      'Not connected',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
                    ),
                ],
              ),
            ),

            // Data display area
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
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
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Received Data',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                          if (_receivedData.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _receivedData.clear();
                                });
                              },
                              child: Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child:
                          _receivedData.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bluetooth_searching,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _isConnected
                                          ? 'Waiting for data...'
                                          : 'Connect to start listening',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                reverse: false,
                                padding: EdgeInsets.all(16),
                                itemCount: _receivedData.length - 2,
                                itemBuilder: (context, index) {
                                  if (index == 0 || index == 1) {
                                    return Container();
                                  }
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Color(
                                          0xFFEC1D24,
                                        ).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: SelectableText(
                                      _receivedData[index],
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Color(0xFF3D3D3D),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
