// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
// import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
// import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
// import 'package:techno_switch_solar_app/utils/logger.dart';

// class BleListenerScreen extends StatefulWidget {
//   const BleListenerScreen({super.key});

//   @override
//   State<BleListenerScreen> createState() => _BleListenerScreenState();
// }

// class _BleListenerScreenState extends State<BleListenerScreen> {
//   final BtUtils _btUtils = BtUtils();
//   BluetoothDevice? _connectedDevice;
//   StreamSubscription<List<int>>? _notificationSubscription;
//   final List<String> _receivedData = [];
//   bool _isConnected = false;
//   String _connectionStatus = 'Not connected';
//   final ScrollController _scrollController = ScrollController();
//   bool _isListening = false;
//   bool _isSendingStopCommand = false;

//   static const int PREAMBLE_FIRST_BYTE = 0xAA;
//   static const int PREAMBLE_SECOND_BYTE = 0x55;
//   static const int DATA_PACKET_FRAME_TYPE_BYTE = 0x02;
//   static const int END_OF_FRAME_FIRST_BYTE = 0xEE;
//   static const int END_OF_FRAME_SECOND_BYTE = 0xBB;

//   @override
//   void initState() {
//     super.initState();
//     _checkExistingConnection();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_isListening) {
//       _checkExistingConnection();
//     }
//   }

//   Future<void> _checkExistingConnection() async {
//     final connectedDevice = await _btUtils.getConnectedDevices();
//     if (connectedDevice != null) {
//       setState(() {
//         _connectedDevice = connectedDevice;
//         _isConnected = true;
//         _connectionStatus =
//             'Connected to: ${_btUtils.getBTDeviceName(connectedDevice)}';
//       });
//       _startListening();
//     } else {
//       setState(() {
//         _isConnected = false;
//         _connectionStatus = 'Not connected. Please connect from home screen.';
//       });
//     }
//   }

//   void _startListening() {
//     if (_connectedDevice == null || _isListening) return;

//     _isListening = true;

//     _btUtils.enableNotifications(
//       _connectedDevice!,
//       (List<int> data) {
//         _onDataReceived(data);
//       },
//       notifyEnabledcallback: (bool enabled) {
//         if (enabled) {
//           setState(() {
//             _connectionStatus = 'Listening for data...';
//           });
//           Logger('BLE Listener - Notifications enabled');
//         } else {
//           setState(() {
//             _connectionStatus = 'Failed to enable notifications';
//             _isListening = false;
//           });
//           Logger('BLE Listener - Failed to enable notifications');
//         }
//       },
//     );
//   }

//   void _onDataReceived(List<int> rawData) {
//     if (rawData.isEmpty) return;

//     final timestamp = DateTime.now();
//     final hexString = rawData
//         .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
//         .join(' ');

//     _parseAndDisplayData(rawData, hexString, timestamp);
//   }

//   List<int> _extractPayloadBytes(List<int> decryptedData) {
//     try {
//       if (decryptedData.length < 9) return [];

//       int payloadLen = decryptedData[6] | (decryptedData[5] << 8);

//       Logger('Payload Length: $payloadLen');

//       if (payloadLen == 0 || decryptedData.length < 7 + payloadLen + 4) {
//         return [];
//       }

//       return decryptedData.sublist(7, 7 + payloadLen);
//     } catch (e) {
//       return [];
//     }
//   }

//   String decimalsToAscii(List<int> codes) {
//     for (final code in codes) {
//       if (code < 0 || code > 255) {
//         throw ArgumentError('Invalid ASCII code: $code');
//       }
//     }
//     return String.fromCharCodes(codes);
//   }

//   Future<void> _parseAndDisplayData(
//     List<int> rawData,
//     String hexString,
//     DateTime timestamp,
//   ) async {
//     String displayData = '';
//     Logger('BLE Listener - Raw data: $rawData');

//     String hexStringData = bytesToHex(rawData);
//     List<int>? decryptedData = await EncryptionUtils().decryptData(
//       hexStringData,
//     );

//     displayData = decimalsToAscii(_extractPayloadBytes(decryptedData!));

//     if (mounted) {
//       setState(() {
//         _receivedData.insert(
//           0,
//           '[${timestamp.hour.toString().padLeft(2, '0')}:'
//           '${timestamp.minute.toString().padLeft(2, '0')}:'
//           '${timestamp.second.toString().padLeft(2, '0')}.'
//           '${timestamp.millisecond.toString().padLeft(3, '0')}] $displayData',
//         );

//         if (_receivedData.length > 100) {
//           _receivedData.removeLast();
//         }
//       });

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             0,
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     }

//     Logger('BLE Listener - Payload (ASCII): $displayData');
//   }

//   Future<void> _disconnect() async {
//     await _notificationSubscription?.cancel();
//     _isListening = false;
//     await _btUtils.disconnect();
//     setState(() {
//       _connectedDevice = null;
//       _isConnected = false;
//       _connectionStatus = 'Disconnected';
//       _receivedData.clear();
//     });
//   }

//   Future<Uint8List> _createStopListeningCommandFrame({
//     int payloadSize = 10,
//   }) async {
//     List<int> payload = List.filled(payloadSize, 0);
//     int command = 0x1007;

//     Uint8List newBleFrame = Uint8List.fromList(<int>[
//       PREAMBLE_FIRST_BYTE,
//       PREAMBLE_SECOND_BYTE,
//       (command >> 8) & 0xFF,
//       command & 0xFF,
//       DATA_PACKET_FRAME_TYPE_BYTE,
//       (payloadSize >> 8) & 0xFF,
//       payloadSize & 0xFF,
//       ...payload,
//     ]);

//     int calculatedCRC = convertCrc16(newBleFrame);

//     List<int> completeBleFrame = newBleFrame.toList();
//     completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
//     completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
//     completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);

//     Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
//       data: completeBleFrame,
//     );

//     return encryptedDataPacket;
//   }

//   Future<void> _sendStopListeningCommand() async {
//     Logger('Stop Listening Command - Sending...');
//     final connectedDevice = await _btUtils.getConnectedDevices();
//     if (connectedDevice == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('No BLE device connected'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isSendingStopCommand = true);

//     try {
//       final frame = await _createStopListeningCommandFrame(payloadSize: 10);

//       bool writeSuccess = false;
//       await _btUtils.writeData(
//         connectedDevice,
//         frame.toList(),
//         dataWritten: (bool success) {
//           writeSuccess = success;
//         },
//       );

//       if (writeSuccess) {
//         setState(() {
//           _isSendingStopCommand = false;
//           _isListening = false;
//           _connectionStatus = 'Listening stopped';
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Stop listening sent'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         setState(() => _isSendingStopCommand = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send command'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() => _isSendingStopCommand = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }

//   // ------------------------------------------------------------
//   // 🚀 EXPORT TXT FILE — COMPLETE METHOD
//   // ------------------------------------------------------------
//   Future<void> _exportReceivedDataAsTxt() async {
//     try {
//       if (_receivedData.isEmpty) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("No data to export")));
//         return;
//       }

//       final String content = _receivedData.join("\n");

//       final Directory dir = await getApplicationDocumentsDirectory();

//       final File file = File(
//         "${dir.path}/ble_logs_${DateTime.now().millisecondsSinceEpoch}.txt",
//       );

//       await file.writeAsString(content);

//       await Share.shareXFiles([XFile(file.path)], text: "BLE Logs Export");

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("TXT file exported")));
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
//     }
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _isListening = false;
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'TechnoSwitch BLE Test',
//           style: GoogleFonts.inter(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Color(0xFFEC1D24),
//         foregroundColor: Colors.white,
//         actions: [
//           if (_isConnected)
//             IconButton(
//               icon: Icon(Icons.stop),
//               onPressed: _disconnect,
//               tooltip: 'Disconnect',
//             ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF6EBEB), Colors.white],
//           ),
//         ),
//         child: Column(
//           children: [
//             Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.1),
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     _isConnected
//                         ? Icons.bluetooth_connected
//                         : Icons.bluetooth_disabled,
//                     color: _isConnected ? Colors.green : Colors.grey,
//                     size: 32,
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _connectionStatus,
//                           style: GoogleFonts.inter(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF3D3D3D),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             if (_isConnected && _isListening)
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16),
//                 child: ElevatedButton(
//                   onPressed:
//                       _isSendingStopCommand ? null : _sendStopListeningCommand,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFFFF5722),
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 4,
//                   ),
//                   child:
//                       _isSendingStopCommand
//                           ? SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 Colors.white,
//                               ),
//                             ),
//                           )
//                           : Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.stop_circle, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Stop Listening',
//                                 style: GoogleFonts.inter(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                 ),
//               ),

//             SizedBox(height: 16),

//             // ----------------------------
//             // 🚀 Download TXT Button
//             // ----------------------------
//             if (_receivedData.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: ElevatedButton.icon(
//                   onPressed: _exportReceivedDataAsTxt,
//                   icon: Icon(Icons.download),
//                   label: Text("Download .txt"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ),

//             SizedBox(height: 16),

//             Expanded(
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.1),
//                       blurRadius: 4,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Received Data',
//                             style: GoogleFonts.inter(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF3D3D3D),
//                             ),
//                           ),
//                           if (_receivedData.isNotEmpty)
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _receivedData.clear();
//                                 });
//                               },
//                               child: Text('Clear'),
//                             ),
//                         ],
//                       ),
//                     ),
//                     Divider(height: 1),
//                     Expanded(
//                       child:
//                           _receivedData.isEmpty
//                               ? Center(
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.bluetooth_searching,
//                                       size: 64,
//                                       color: Colors.grey[400],
//                                     ),
//                                     SizedBox(height: 16),
//                                     Text(
//                                       _isConnected
//                                           ? 'Waiting for data...'
//                                           : 'Connect to start listening',
//                                       style: GoogleFonts.inter(
//                                         fontSize: 16,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                               : ListView.builder(
//                                 controller: _scrollController,
//                                 reverse: false,
//                                 padding: EdgeInsets.all(16),
//                                 itemCount: _receivedData.length,
//                                 itemBuilder: (context, index) {
//                                   return Container(
//                                     margin: EdgeInsets.only(bottom: 12),
//                                     padding: EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: Color(0xFFF5F5F5),
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(
//                                         color: Color(
//                                           0xFFEC1D24,
//                                         ).withValues(alpha: 0.2),
//                                       ),
//                                     ),
//                                     child: SelectableText(
//                                       _receivedData[index],
//                                       style: GoogleFonts.inter(
//                                         fontSize: 12,
//                                         color: Color(0xFF3D3D3D),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }
