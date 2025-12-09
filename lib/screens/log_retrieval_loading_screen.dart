import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'dart:async';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/utils/timestamp_converter.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class LogRetrievalLoadingScreen extends StatefulWidget {
  const LogRetrievalLoadingScreen({super.key});

  @override
  State<LogRetrievalLoadingScreen> createState() =>
      _LogRetrievalLoadingScreenState();
}

class _LogRetrievalLoadingScreenState extends State<LogRetrievalLoadingScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _accessCodeController;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _progress = 0.0;
  Timer? _timer;

  // Log retrieval state
  late SerialCommunicationService _serialService;
  List<LogModel> _retrievedLogs = [];
  String _connectionStatus = "Disconnected";
  int _logsCount = 0;
  StreamSubscription? _logSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _handshakeSubscription;
  StreamSubscription? _bleNotificationSubscription;
  String? _capturedPanelId; // Capture panel ID before potential disconnect
  static const int totalExpectedLogs = 1000; // Total logs expected

  // BLE handler
  BleNotifyDataHandler? _bleHandler;
  BluetoothDevice? _connectedBleDevice;
  bool _isReceivingLogs = false;
  int _logEvtSearchNumber = 999; // Start from 999 and decrement
  Timer? _logRetrievalTimeout;

  @override
  void initState() {
    super.initState();
    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(() {
      setState(() {});
    });

    // Initialize serial service
    _serialService = AppServices.serialService;

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          _progress = _animation.value;
        });
      });

    // Start log retrieval instead of animation
    _startLogRetrieval();
  }

  void _startLogRetrieval() async {
    // ========== NEW BLE LOG RETRIEVAL IMPLEMENTATION ==========
    // Check BLE connection first
    final btUtils = BtUtils();
    final connectedDevice = await btUtils.getConnectedDevices();

    if (connectedDevice != null && Get.isRegistered<BleNotifyDataHandler>()) {
      // BLE connection detected
      _bleHandler = Get.find<BleNotifyDataHandler>();

      // Verify BLE state is connected
      if (_bleHandler!.currentBleState.value == BleStateMachine.connected) {
        setState(() {
          _connectionStatus = "BLE Connected - Starting log retrieval...";
        });

        // Capture panel ID if available
        _capturedPanelId = connectedDevice.platformName;
        print("DEBUG: LogRetrieval - BLE Device: $_capturedPanelId");

        // Listen to handshake events for responses
        _handshakeSubscription = _bleHandler!.handshakeEvents.listen((event) {
          print("DEBUG: LogRetrieval - Handshake event: ${event.type}");
          if (event.type == BleHandshakeEventType.error) {
            setState(() {
              _connectionStatus = "Error: ${event.message ?? 'Unknown error'}";
            });
          }
        });

        // Store connected device for notification listening
        _connectedBleDevice = connectedDevice;

        // Set up BLE notification listener for log packets
        _setupBleNotificationListener();

        // Send CONTROL_RES_EVENT_REPORT command
        try {
          _bleHandler!.requestControlResEventReport();

          setState(() {
            _connectionStatus =
                "CONTROL_RES_EVENT_REPORT sent - Waiting for logs...";
            _isReceivingLogs = true;
          });

          // Set timeout for log retrieval (30 seconds)
          _logRetrievalTimeout = Timer(Duration(seconds: 30), () {
            if (mounted && _isReceivingLogs) {
              _completeLogRetrieval();
            }
          });
        } catch (e) {
          setState(() {
            _connectionStatus = "Error sending command: $e";
          });
        }
      } else {
        setState(() {
          _connectionStatus =
              "BLE not fully connected. State: ${_bleHandler!.currentBleState.value.name}";
        });
      }
    }
    // ========== OLD USB SERIAL IMPLEMENTATION (COMMENTED OUT) ==========
    // Fallback to USB Serial if BLE not connected
    else if (AppServices.isConnected) {
      // // Check if already connected and start log retrieval
      // if (AppServices.isConnected) {
      //   // Capture the panel ID before starting log retrieval (before potential disconnect)
      //   _capturedPanelId = AppServices.serialService.currentPanelId;
      //   print("DEBUG: LogRetrieval - Captured panel ID: $_capturedPanelId");

      //   _connectionStatus = "Starting log retrieval...";

      //   // Listen to log stream
      //   _logSubscription = _serialService.logStream.listen((logModel) {
      //     setState(() {
      //       _retrievedLogs.add(logModel);
      //       _logsCount = _retrievedLogs.length;
      //       // Update progress based on logs retrieved out of total expected
      //       _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
      //     });
      //   });

      //   // Listen to status stream
      //   _statusSubscription = _serialService.statusStream.listen((status) {
      //     setState(() {
      //       _connectionStatus = status;
      //       print("DEBUG: LogRetrieval - Status: $status");

      //       // Check if log retrieval is completed
      //       if (status.contains("Completed") || status.contains("Disconnected")) {
      //         // Set progress to 100% if completed
      //         _progress = 1.0;
      //         // Small delay before navigation to show completion
      //         Future.delayed(Duration(milliseconds: 500), () {
      //           if (mounted) {
      //             // Navigate to EventLogScreen with retrieved logs and captured panel ID
      //             Navigator.of(context).pushReplacement(
      //               MaterialPageRoute(
      //                 builder:
      //                     (context) => EventLogScreen(
      //                       logDataList: _retrievedLogs,
      //                       panelName: 'RHINO2008',
      //                       panelVersionNo: '0.98',
      //                       isStandalone: true, // This is standalone mode
      //                       panelId:
      //                           _capturedPanelId, // Pass the captured panel ID
      //                     ),
      //               ),
      //             );
      //           }
      //         });
      //       }
      //     });
      //   });

      //   // Start the actual log retrieval process
      //   _serialService.startLogRetrieval();
      // } else {
      //   _connectionStatus = "Device not connected";
      //   // Fallback navigation after 5 seconds if not connected
      //   // _controller.forward();
      //   _controller.addStatusListener((status) {
      //     if (status == AnimationStatus.completed) {
      //       // Navigator.of(context).pushReplacement(
      //       //   MaterialPageRoute(
      //       //     builder:
      //       //         (context) => EventLogScreen(
      //       //           logDataList: [], // Empty list if not connected
      //       //           panelName: 'RHINO2008',
      //       //           panelVersionNo: '0.98',
      //       //         ),
      //       //   ),
      //       // );
      //     }
      //   });
      // }

      // Original USB serial flow
      _capturedPanelId = AppServices.serialService.currentPanelId;
      print("DEBUG: LogRetrieval - Captured panel ID: $_capturedPanelId");

      _connectionStatus = "Starting log retrieval...";

      _logSubscription = _serialService.logStream.listen((logModel) {
        setState(() {
          _retrievedLogs.add(logModel);
          _logsCount = _retrievedLogs.length;
          _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
        });
      });

      _statusSubscription = _serialService.statusStream.listen((status) {
        setState(() {
          _connectionStatus = status;
          print("DEBUG: LogRetrieval - Status: $status");

          if (status.contains("Completed") || status.contains("Disconnected")) {
            _progress = 1.0;
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => EventLogScreen(
                          logDataList: _retrievedLogs,
                          panelName: 'RHINO2008',
                          panelVersionNo: '0.98',
                          isStandalone: true,
                          panelId: _capturedPanelId,
                        ),
                  ),
                );
              }
            });
          }
        });
      });

      _serialService.startLogRetrieval();
    } else {
      _connectionStatus = "Device not connected";
      // Fallback navigation after 5 seconds if not connected
      // _controller.forward();
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(
          //     builder:
          //         (context) => EventLogScreen(
          //           logDataList: [], // Empty list if not connected
          //           panelName: 'RHINO2008',
          //           panelVersionNo: '0.98',
          //         ),
          //   ),
          // );
        }
      });
    }
  }

  // Set up BLE notification listener for log packets
  void _setupBleNotificationListener() async {
    if (_connectedBleDevice == null) return;

    try {
      // Get the read characteristic directly
      final services = await _connectedBleDevice!.discoverServices();
      BluetoothCharacteristic? readChar;

      for (var service in services) {
        if (service.uuid.toString().toUpperCase() ==
            BtUtils().primaryServiceGuid.toString().toUpperCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toUpperCase() ==
                BtUtils().primaryReadCharGuid.toString().toUpperCase()) {
              readChar = char;
              break;
            }
          }
          break;
        }
      }

      if (readChar != null && readChar.properties.notify) {
        // Listen to the characteristic stream directly
        _bleNotificationSubscription = readChar.onValueReceived.listen((
          List<int> data,
        ) {
          _handleBleNotification(data);
        });

        // Ensure notifications are enabled
        await readChar.setNotifyValue(true);
        print(
          "DEBUG: LogRetrieval - BLE notifications enabled for log packets",
        );
      } else {
        setState(() {
          _connectionStatus = "Failed to find read characteristic";
        });
      }
    } catch (e) {
      print("DEBUG: LogRetrieval - Error setting up notifications: $e");
      setState(() {
        _connectionStatus = "Error: $e";
      });
    }
  }

  // Handle incoming BLE notifications
  void _handleBleNotification(List<int> rxData) async {
    if (rxData.isEmpty || !_isReceivingLogs) return;

    try {
      // Decrypt the frame if encryption is enabled
      final bool shouldDecrypt =
          _bleHandler != null &&
          _bleHandler!.encryptionDecryptionState.value ==
              EncryptionDecryptionState.enabled;

      FrameData? frame;
      if (shouldDecrypt) {
        try {
          frame = await DataHandler().decryptTheDataPacketWithoutConversion(
            rxData,
          );
        } catch (e) {
          print("DEBUG: LogRetrieval - Failed to decrypt frame: $e");
          return;
        }
      } else {
        // Parse non-encrypted frame
        frame = DataTransferManager().parseRxFrame(rxData);
      }

      if (frame == null) {
        print("DEBUG: LogRetrieval - Failed to parse frame");
        return;
      }

      // Extract nested Technoswitch frame from payload
      List<int> technoswitchFrameBytes = convertStringListToHex(
        frame.payloadData,
      );

      // Validate Technoswitch frame structure (should be 216 bytes)
      if (technoswitchFrameBytes.length != 216) {
        print(
          "DEBUG: LogRetrieval - Invalid frame length: ${technoswitchFrameBytes.length}",
        );
        return;
      }

      // Validate frame markers
      const int frameSot = 0xFE;
      const int frameEot = 0xFD;
      if (technoswitchFrameBytes[0] != frameSot ||
          technoswitchFrameBytes[215] != frameEot) {
        print("DEBUG: LogRetrieval - Invalid frame markers");
        return;
      }

      // Check if this is a log packet
      // Log packets have: pktTyp=NRM (0x01), mode=2 (dbSetupReq), cmd=2 (eventStatusCmd)
      int pktTyp = technoswitchFrameBytes[3];
      int mode = technoswitchFrameBytes[10];
      int cmd = technoswitchFrameBytes[12];

      const int packetTypeNrm = 1; // NRM packet type
      const int dbSetupReq = 2; // Mode for database setup request
      const int eventStatusCmd = 2; // Command for event status

      if (pktTyp == packetTypeNrm &&
          mode == dbSetupReq &&
          cmd == eventStatusCmd) {
        // This is a log packet - process it
        print("DEBUG: LogRetrieval - Log packet received");
        _processLogPacket(technoswitchFrameBytes);

        // Decrement search number
        if (_logEvtSearchNumber > 0) {
          _logEvtSearchNumber--;
        } else {
          // Reached end of logs
          _completeLogRetrieval();
        }
      } else {
        print(
          "DEBUG: LogRetrieval - Non-log packet: pktTyp=$pktTyp, mode=$mode, cmd=$cmd",
        );
      }
    } catch (e) {
      print("DEBUG: LogRetrieval - Error processing notification: $e");
    }
  }

  // Process log packet and convert to LogModel
  void _processLogPacket(List<int> evtData) {
    try {
      // Extract timestamp (bytes 12-16)
      List<int> timestamp = evtData.sublist(12, 16);
      int timestampDecimal =
          timestamp[3] |
          (timestamp[2] << 8) |
          (timestamp[1] << 16) |
          (timestamp[0] << 24);

      // Use current time if timestamp is invalid
      DateTime eventTime =
          timestampDecimal != 0x00
              ? TimestampConverter.clockTimeFromTimeStamp(timestampDecimal)
              : DateTime.now();

      // Extract Event ID (bytes 126-129)
      int eventId =
          (evtData[126] << 24) |
          (evtData[127] << 16) |
          (evtData[128] << 8) |
          (evtData[129] << 0);

      // Extract event text (bytes 42-124)
      String evtTextAscii;
      List<int> evtText = evtData.sublist(42, 124);
      if (evtText.length > 1 && evtText[1] != 0x00) {
        int textLen = evtText[1];
        List<int> evtTextValue = evtText.sublist(2, 2 + textLen);
        evtTextAscii = String.fromCharCodes(evtTextValue);
      } else {
        evtTextAscii = "NO-TEXT";
      }

      // Extract panel source
      String panelSource;
      if (evtData[9] == EventConstants.evtTypeNetworkAddress) {
        panelSource =
            evtData[29] == 0
                ? "Module"
                : evtData[29] == 1
                ? "Panel No. ${evtData[30]}"
                : evtData[29] == 2
                ? "Repeater No. ${evtData[30]}"
                : evtData[29] == 3
                ? "SOLAR"
                : evtData[29] == 4
                ? "Server No. ${evtData[30]}"
                : "";
      } else if (evtData[9] == EventConstants.evtTypeAccess) {
        panelSource =
            evtData[29] == 0
                ? "Control"
                : evtData[29] == 1
                ? "Keyboard"
                : evtData[29] == 2
                ? "SOLAR"
                : evtData[29] == 3
                ? "Server"
                : "";
      } else {
        panelSource = "";
      }

      // Create LogModel if event ID is valid
      if (eventId != 0) {
        LogModel logModel = LogModel(
          panelText: panelSource,
          eventId: (eventId + 1).toString(),
          eventDateTime: eventTime,
          panelNo: evtData[0].toString(),
          lBusNo: evtData[1].toString(),
          moduleNo: evtData[2].toString(),
          eventStatus: EventConstants.getEventStatusValue(evtData[10]),
          eventClass: EventConstants.getEventClassValue(evtData[7]),
          eventSource: panelSource,
          eventType: EventConstants.getEventType(evtData[9]),
          eventSubType: EventConstants.getEventDescription(
            evtData[9],
            evtData[11],
          ),
          identifier: EventConstants.getEventIdentifier(
            evtData[9],
            evtData[29],
            evtData[30],
            evtData[31],
          ),
          text: evtTextAscii,
          isValid: timestampDecimal != 0x00,
          retrievedAt: DateTime.now(),
        );

        // Add log to list and update UI
        if (mounted) {
          setState(() {
            _retrievedLogs.add(logModel);
            _logsCount = _retrievedLogs.length;
            _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
            _connectionStatus =
                "Receiving logs... $_logsCount logs received (${(_progress * 100).toInt()}%)";
          });
        }

        print(
          "DEBUG: LogRetrieval - Log $_logsCount received: ${logModel.eventType}",
        );
      }
    } catch (e) {
      print("DEBUG: LogRetrieval - Error processing log packet: $e");
    }
  }

  // Complete log retrieval and navigate to EventLogScreen
  void _completeLogRetrieval() {
    if (!_isReceivingLogs) return;

    _isReceivingLogs = false;
    _logRetrievalTimeout?.cancel();

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _connectionStatus = "Log retrieval completed. Total: $_logsCount logs";
      });

      // Small delay before navigation to show completion
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => EventLogScreen(
                    logDataList: _retrievedLogs,
                    panelName: 'RHINO2008',
                    panelVersionNo: '0.98',
                    isStandalone: true,
                    panelId: _capturedPanelId,
                  ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Disconnect Bluetooth when going back
                            await NavigationService.navigateBackToScanning(
                              context,
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/svgs/arrow_back_icon.svg',
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Event Log Retrieval ',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  _buildRetrievingLogsContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrievingLogsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: SvgPicture.asset('assets/svgs/background_2.svg'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Retrieving',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF918F8F),
                      ),
                    ),
                    Text(
                      'Event Log',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A3A3A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CupertinoActivityIndicator(radius: 20, color: Color(0xFFEC1D24)),
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Text(
                'Please Wait...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Show connection status
            Padding(
              padding: const EdgeInsets.only(top: 130),
              child: Text(
                _connectionStatus,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF918F8F),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                    // SizedBox(height: 8),
                    // Text(
                    //   '$_logsCount / $totalExpectedLogs logs',
                    //   style: GoogleFonts.inter(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w500,
                    //     color: Color(0xFF918F8F),
                    //   ),
                    //   maxLines: 1,
                    // ),
                    SizedBox(height: 23),
                    LinearPercentIndicator(
                      lineHeight: 11.0,
                      percent: _progress,
                      backgroundColor: Color(0xFFD9D9D9),
                      progressColor: Color(0xFFEC1D24),
                      barRadius: Radius.circular(20),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Fetching Logs...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBottomBar() {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       children: [
  //         Opacity(
  //           opacity: 0.2,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: Color(0xFFEFEEEE),
  //               borderRadius: BorderRadius.circular(28.5),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.only(
  //                 top: 18,
  //                 bottom: 18,
  //                 left: 16,
  //                 right: 34,
  //               ),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.arrow_back, color: Color(0xFF49454F)),
  //                   SizedBox(width: 6),
  //                   Text(
  //                     'Back',
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //         Spacer(),
  //         GestureDetector(
  //           onTap: () {
  //             if (_accessCodeController.text.isEmpty) {
  //               return;
  //             }
  //           },
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color:
  //                   _accessCodeController.text.isEmpty
  //                       ? Color(0xFFDADADA)
  //                       : Color(0xFFEC1D24),
  //               borderRadius: BorderRadius.circular(28.5),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.only(
  //                 top: 18,
  //                 bottom: 18,
  //                 left: 27,
  //                 right: 23,
  //               ),
  //               child: Row(
  //                 children: [
  //                   Text(
  //                     'Retrieve Data',
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                   SizedBox(width: 13),
  //                   Icon(Icons.arrow_forward, color: Colors.white),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _controller.dispose();
    _timer?.cancel();
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _handshakeSubscription?.cancel();
    _bleNotificationSubscription?.cancel();
    _logRetrievalTimeout?.cancel();
    super.dispose();
  }
}
