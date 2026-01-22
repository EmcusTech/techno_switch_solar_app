import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'dart:async';
import 'package:techno_switch_solar_app/screens/access_code_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retreival_completed_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retreival_failed_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/utils/timestamp_converter.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Shared BLE instance used across screens
final BleManager ble = Get.find<BleManager>();

class LogRetrievalLoadingScreen extends StatefulWidget {
  final dynamic selectedDevice;
  final ScanType scanType;
  final bool? isLiveEvent;

  const LogRetrievalLoadingScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

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
  String _connectionStatus = "Initializing...";
  // ignore: unused_field
  bool _connectionFailed = false;
  String? _errorMessage;
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  StreamSubscription<DeviceConnectionState>? _connectionSub;
  bool _passkeyScreenOpened = false;
  Uuid primaryServiceGuid = BleUuids.primaryService;
  Uuid primaryReadCharGuid = BleUuids.primaryReadChar;
  Uuid primaryWriteCharGuid = BleUuids.primaryWriteChar;
  QualifiedCharacteristic? readCharacteristic;
  QualifiedCharacteristic? writeCharacteristic;
  bool _maxBleConnectionRetriesReached = false;
  bool _maxOtherPacketsRetriesReached = false;
  // ignore: unused_field
  bool _firstLogReceived = false;
  bool _hasNavigatedToEventLog = false;
  bool _navigatedToFailure = false;
  bool _allowExit = false;

  // Log retrieval state
  late SerialCommunicationService _serialService;
  List<LogModel> _retrievedLogs = [];
  int _logsCount = 0;
  StreamSubscription? _logSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _bleNotificationSubscription;
  String? _capturedPanelId; // Capture panel ID before potential disconnect
  static const int totalExpectedLogs = 1000; // Total logs expected

  // BLE handler
  BleNotifyDataHandler? _bleHandler;
  DiscoveredDevice? _connectedBleDevice;
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
    _capturedPanelId = _serialService.currentPanelId;

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

    // Reset state when screen is initialized (for retry scenarios)
    _firstLogReceived = false;
    _hasNavigatedToEventLog = false;

    // Listen for first valid log to show button
    ble.bleProcess.isValidLogRecieved.addListener(_onFirstValidLogReceived);

    // Listen for log retrieval completion (1000 logs read)
    ble.bleProcess.read1000LogsCount.addListener(_onLogRetrievalCompleted);

    ble.maxBleConnectionRetriesReached.addListener(
      _onMaxBleConnectionRetriesReached,
    );

    ble.maxOtherPacketsRetriesReached.addListener(
      _onMaxOtherPacketsRetriesReached,
    );

    // Keep notification handler referenced for analyzer and future wiring
    final _ = _handleBleNotification;

    // Start BLE connection flow with existing device selection
    // _connectToDevice();

    // Start log retrieval instead of animation
    // _startLogRetrieval();
  }

  // void _startLogRetrieval() async {
  //   // ========== NEW BLE LOG RETRIEVAL IMPLEMENTATION ==========
  //   // Check BLE connection first
  //   final btUtils = BtUtils();
  //   final connectedDevice = await btUtils.getConnectedDevices();

  //   if (connectedDevice != null && Get.isRegistered<BleNotifyDataHandler>()) {
  //     // BLE connection detected
  //     _bleHandler = Get.find<BleNotifyDataHandler>();

  //     // Verify BLE state is connected
  //     if (_bleHandler!.currentBleState.value == BleStateMachine.connected) {
  //       setState(() {
  //         _connectionStatus = "BLE Connected - Starting log retrieval...";
  //       });

  //       // Capture panel ID if available
  //       _capturedPanelId = connectedDevice.platformName;
  //       print("DEBUG: LogRetrieval - BLE Device: $_capturedPanelId");

  //       // Listen to handshake events for responses
  //       _handshakeSubscription = _bleHandler!.handshakeEvents.listen((event) {
  //         print("DEBUG: LogRetrieval - Handshake event: ${event.type}");
  //         if (event.type == BleHandshakeEventType.error) {
  //           setState(() {
  //             _connectionStatus = "Error: ${event.message ?? 'Unknown error'}";
  //           });
  //         }
  //       });

  //       // Store connected device for notification listening
  //       _connectedBleDevice = connectedDevice;

  //       // Set up BLE notification listener for log packets
  //       _setupBleNotificationListener();

  //       // Send CONTROL_RES_EVENT_REPORT command
  //       try {
  //         _bleHandler!.requestControlResEventReport();

  //         setState(() {
  //           _connectionStatus =
  //               "CONTROL_RES_EVENT_REPORT sent - Waiting for logs...";
  //           _isReceivingLogs = true;
  //         });

  //         // Set timeout for log retrieval (30 seconds)
  //         _logRetrievalTimeout = Timer(Duration(seconds: 30), () {
  //           if (mounted && _isReceivingLogs) {
  //             _completeLogRetrieval();
  //           }
  //         });
  //       } catch (e) {
  //         setState(() {
  //           _connectionStatus = "Error sending command: $e";
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         _connectionStatus =
  //             "BLE not fully connected. State: ${_bleHandler!.currentBleState.value.name}";
  //       });
  //     }
  //   }
  //   // ========== OLD USB SERIAL IMPLEMENTATION (COMMENTED OUT) ==========
  //   // Fallback to USB Serial if BLE not connected
  //   else if (AppServices.isConnected) {
  //     // // Check if already connected and start log retrieval
  //     // if (AppServices.isConnected) {
  //     //   // Capture the panel ID before starting log retrieval (before potential disconnect)
  //     //   _capturedPanelId = AppServices.serialService.currentPanelId;
  //     //   print("DEBUG: LogRetrieval - Captured panel ID: $_capturedPanelId");

  //     //   _connectionStatus = "Starting log retrieval...";

  //     //   // Listen to log stream
  //     //   _logSubscription = _serialService.logStream.listen((logModel) {
  //     //     setState(() {
  //     //       _retrievedLogs.add(logModel);
  //     //       _logsCount = _retrievedLogs.length;
  //     //       // Update progress based on logs retrieved out of total expected
  //     //       _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
  //     //     });
  //     //   });

  //     //   // Listen to status stream
  //     //   _statusSubscription = _serialService.statusStream.listen((status) {
  //     //     setState(() {
  //     //       _connectionStatus = status;
  //     //       print("DEBUG: LogRetrieval - Status: $status");

  //     //       // Check if log retrieval is completed
  //     //       if (status.contains("Completed") || status.contains("Disconnected")) {
  //     //         // Set progress to 100% if completed
  //     //         _progress = 1.0;
  //     //         // Small delay before navigation to show completion
  //     //         Future.delayed(Duration(milliseconds: 500), () {
  //     //           if (mounted) {
  //     //             // Navigate to EventLogScreen with retrieved logs and captured panel ID
  //     //             Navigator.of(context).pushReplacement(
  //     //               MaterialPageRoute(
  //     //                 builder:
  //     //                     (context) => EventLogScreen(
  //     //                       logDataList: _retrievedLogs,
  //     //                       panelName: 'RHINO2008',
  //     //                       panelVersionNo: '0.98',
  //     //                       isStandalone: true, // This is standalone mode
  //     //                       panelId:
  //     //                           _capturedPanelId, // Pass the captured panel ID
  //     //                     ),
  //     //               ),
  //     //             );
  //     //           }
  //     //         });
  //     //       }
  //     //     });
  //     //   });

  //     //   // Start the actual log retrieval process
  //     //   _serialService.startLogRetrieval();
  //     // } else {
  //     //   _connectionStatus = "Device not connected";
  //     //   // Fallback navigation after 5 seconds if not connected
  //     //   // _controller.forward();
  //     //   _controller.addStatusListener((status) {
  //     //     if (status == AnimationStatus.completed) {
  //     //       // Navigator.of(context).pushReplacement(
  //     //       //   MaterialPageRoute(
  //     //       //     builder:
  //     //       //         (context) => EventLogScreen(
  //     //       //           logDataList: [], // Empty list if not connected
  //     //       //           panelName: 'RHINO2008',
  //     //       //           panelVersionNo: '0.98',
  //     //       //         ),
  //     //       //   ),
  //     //       // );
  //     //     }
  //     //   });
  //     // }

  //     // Original USB serial flow
  //     _capturedPanelId = AppServices.serialService.currentPanelId;
  //     print("DEBUG: LogRetrieval - Captured panel ID: $_capturedPanelId");

  //     _connectionStatus = "Starting log retrieval...";

  //     _logSubscription = _serialService.logStream.listen((logModel) {
  //       setState(() {
  //         _retrievedLogs.add(logModel);
  //         _logsCount = _retrievedLogs.length;
  //         _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
  //       });
  //     });

  //     _statusSubscription = _serialService.statusStream.listen((status) {
  //       setState(() {
  //         _connectionStatus = status;
  //         print("DEBUG: LogRetrieval - Status: $status");

  //         if (status.contains("Completed") || status.contains("Disconnected")) {
  //           _progress = 1.0;
  //           Future.delayed(Duration(milliseconds: 500), () {
  //             if (mounted) {
  //               Navigator.of(context).pushReplacement(
  //                 MaterialPageRoute(
  //                   builder:
  //                       (context) => EventLogScreen(
  //                         logDataList: _retrievedLogs,
  //                         panelName: 'RHINO2008',
  //                         panelVersionNo: '0.98',
  //                         isStandalone: true,
  //                         panelId: _capturedPanelId,
  //                       ),
  //                 ),
  //               );
  //             }
  //           });
  //         }
  //       });
  //     });

  //     _serialService.startLogRetrieval();
  //   } else {
  //     _connectionStatus = "Device not connected";
  //     // Fallback navigation after 5 seconds if not connected
  //     // _controller.forward();
  //     _controller.addStatusListener((status) {
  //       if (status == AnimationStatus.completed) {
  //         // Navigator.of(context).pushReplacement(
  //         //   MaterialPageRoute(
  //         //     builder:
  //         //         (context) => EventLogScreen(
  //         //           logDataList: [], // Empty list if not connected
  //         //           panelName: 'RHINO2008',
  //         //           panelVersionNo: '0.98',
  //         //         ),
  //         //   ),
  //         // );
  //       }
  //     });
  //   }
  // }

  // // Set up BLE notification listener for log packets
  // void _setupBleNotificationListener() async {
  //   if (_connectedBleDevice == null) return;

  //   try {
  //     // Get the read characteristic directly
  //     final services = await _connectedBleDevice!.discoverServices();
  //     BluetoothCharacteristic? readChar;

  //     for (var service in services) {
  //       if (service.uuid.toString().toUpperCase() ==
  //           BtUtils().primaryServiceGuid.toString().toUpperCase()) {
  //         for (var char in service.characteristics) {
  //           if (char.uuid.toString().toUpperCase() ==
  //               BtUtils().primaryReadCharGuid.toString().toUpperCase()) {
  //             readChar = char;
  //             break;
  //           }
  //         }
  //         break;
  //       }
  //     }

  //     if (readChar != null && readChar.properties.notify) {
  //       // Listen to the characteristic stream directly
  //       _bleNotificationSubscription = readChar.onValueReceived.listen((
  //         List<int> data,
  //       ) {
  //         _handleBleNotification(data);
  //       });

  //       // Ensure notifications are enabled
  //       await readChar.setNotifyValue(true);
  //       print(
  //         "DEBUG: LogRetrieval - BLE notifications enabled for log packets",
  //       );
  //     } else {
  //       setState(() {
  //         _connectionStatus = "Failed to find read characteristic";
  //       });
  //     }
  //   } catch (e) {
  //     print("DEBUG: LogRetrieval - Error setting up notifications: $e");
  //     setState(() {
  //       _connectionStatus = "Error: $e";
  //     });
  //   }
  // }

  void _onMaxBleConnectionRetriesReached() {
    setState(() {
      _maxBleConnectionRetriesReached =
          ble.maxBleConnectionRetriesReached.value;
      if (_maxBleConnectionRetriesReached) {
        _connectionFailed = true;
        _errorMessage = "Maximum BLE connection retries reached";
        _connectionStatus = _errorMessage!;
      }
    });
  }

  void _onMaxOtherPacketsRetriesReached() {
    setState(() {
      _maxOtherPacketsRetriesReached = ble.maxOtherPacketsRetriesReached.value;
      if (_maxOtherPacketsRetriesReached) {
        _connectionFailed = true;
        _errorMessage = "Maximum packet retries reached";
        _connectionStatus = _errorMessage!;
      }
    });
  }

  void _onFirstValidLogReceived() {
    if (ble.bleProcess.isValidLogRecieved.value && mounted) {
      setState(() {
        _firstLogReceived = true;
      });
    }
  }

  // Add listener for log retrieval completion
  void _onLogRetrievalCompleted() {
    if (mounted &&
        ble.bleProcess.read1000LogsCount.value >= 1000 &&
        !_hasNavigatedToEventLog) {
      _hasNavigatedToEventLog = true;
      // Wait a brief moment for final processing, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToEventLogScreen();
        }
      });
    }
  }

  // Add method to navigate to EventLogScreen
  void _navigateToEventLogScreen() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);

    // Ensure any open popups (e.g., Cancel dialog) are closed before navigating
    if (navigator.canPop()) {
      navigator.popUntil((route) => route is PageRoute);
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => LogRetrievalCompletedScreen(
              logs: _retrievedLogs,
              panelId: _capturedPanelId ?? '',
              panelName: _getDeviceName(),
            ),
      ),
    );
  }

  void _navigateToFailureScreen() {
    if (!mounted || _navigatedToFailure) return;
    _navigatedToFailure = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route is PageRoute);
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LogRetrievalFailedScreen()),
    );
  }

  //send stop control command
  Future<void> _sendStopControlCommand() async {
    ble.bleProcess.isOtaCompleted = true;
    ble.bleProcess.processNextOtaFrame = false;

    ble.otaProcessState = OtaProcessState.notInUse;
    ble.bleProcess.cancelRxTimeout();

    ble.bleProcess.processDesc.value = "";

    await ble.sendStopCntrlCmdPkt();
    _allowExit = true;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Show confirmation dialog before stopping log retrieval
  Future<void> _showStopConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEC1D24),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stop Log Retrieval',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to stop the log retrieval process? This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC1D24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.5),
                ),
                elevation: 0,
              ),
              child: Text(
                'Yes, Stop',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _sendStopControlCommand();
    }
  }

  Future<void> _connectToDevice() async {
    if (widget.selectedDevice == null) {
      _handleConnectionFailure("No Device selected");
      return;
    }

    if (widget.scanType == ScanType.bluetooth &&
        widget.selectedDevice is! DiscoveredDevice) {
      _handleConnectionFailure("Invalid BLE Device selected");
      return;
    }

    setState(() {
      _connectionStatus = "Connecting to ${_getDeviceName()}";
    });

    try {
      if (widget.scanType == ScanType.bluetooth) {
        final DiscoveredDevice device =
            widget.selectedDevice as DiscoveredDevice;
        _connectedBleDevice = device;

        /// listen to handshake events only once
        _handshakeSubscription ??= AppServices.bleService.handshakeEvents
            .listen(_handleHandshakeEvent);

        setState(() {
          _connectionStatus = "Establishing Bluetooth connection...";
        });

        /// 🔥 LISTEN to the BLE connection stream
        _connectionSub = AppServices.bleService
            .connectToDevice(device)
            .listen(
              (DeviceConnectionState state) async {
                switch (state) {
                  case DeviceConnectionState.connecting:
                    setState(() {
                      _connectionStatus = "Connecting...";
                    });
                    break;

                  case DeviceConnectionState.connected:
                    setState(() {
                      _connectionStatus =
                          "Connected. Waiting for BLE handshake...";
                    });
                    readCharacteristic = QualifiedCharacteristic(
                      characteristicId: primaryReadCharGuid,
                      serviceId: primaryServiceGuid,
                      deviceId: device.id,
                    );

                    writeCharacteristic = QualifiedCharacteristic(
                      characteristicId: primaryWriteCharGuid,
                      serviceId: primaryServiceGuid,
                      deviceId: device.id,
                    );
                    break;

                  case DeviceConnectionState.disconnected:
                    _handleConnectionFailure("Device disconnected");
                    await _connectionSub?.cancel();
                    break;
                  default:
                    print("reached defualt when connecting");
                    break;
                }
              },
              onError: (e) {
                _handleConnectionFailure("Connection error: $e");
              },
            );
      } else {
        // USB path (unchanged logic)
        setState(() {
          _connectionStatus = "Establishing USB connection...";
        });

        // await AppServices.serialService.connectToDevice();
      }
    } catch (e) {
      _handleConnectionFailure("Connection error: $e");
    }
  }

  void _handleHandshakeEvent(BleHandshakeEvent event) async {
    if (!mounted) return;

    switch (event.type) {
      case BleHandshakeEventType.stateChanged:
        if (event.message != null) {
          setState(() {
            _connectionStatus = event.message!;
          });
        }
        break;

      case BleHandshakeEventType.encryptionKeyReceived:
        setState(() {
          _connectionStatus = "Encryption key received";
        });
        break;

      case BleHandshakeEventType.authenticated:
        setState(() {
          _connectionStatus = "Device authenticated successfully";
        });

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        if (widget.isLiveEvent == false) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => AccessCodeScreen(
                    scanType: widget.scanType,
                    selectedDevice: widget.selectedDevice,
                    isLiveEvent: widget.isLiveEvent,
                  ),
            ),
          );
        }
        break;

      case BleHandshakeEventType.passkeyRequested:
        setState(() {
          _connectionStatus = "Submitting passkey automatically...";
        });

        if (!_passkeyScreenOpened) {
          _passkeyScreenOpened = true;

          Future.microtask(() async {
            if (!mounted) return;
            try {
              await AppServices.bleService.submitPasskey("1974");
              setState(() {
                _connectionStatus = "Passkey submitted: 1974";
              });
            } catch (e) {
              setState(() {
                _connectionStatus = "Error submitting passkey: $e";
              });
            }
          });
        }
        break;

      case BleHandshakeEventType.passkeyAccepted:
        setState(() {
          _connectionStatus = "Passkey accepted";
        });
        break;

      case BleHandshakeEventType.error:
        _handleConnectionFailure(event.message ?? "Handshake error");
        break;
    }
  }

  void _handleConnectionFailure(String error) {
    setState(() {
      _connectionFailed = true;
      _errorMessage = error;
      _connectionStatus = "Connection Failed";
    });
    _controller.stop();
    _navigateToFailureScreen();
  }

  String _getDeviceName() {
    final device = widget.selectedDevice ?? _connectedBleDevice;

    if (device == null) {
      return "Unknown Device";
    }

    if (widget.scanType == ScanType.bluetooth) {
      if (device is DiscoveredDevice) {
        if (device.name.isNotEmpty) {
          return device.name;
        }
        return "BLE-${device.id.substring(0, 5)}";
      }
      return "BLE Device";
    }

    return "Unknown Device";
  }

  // ignore: unused_element
  // Handle incoming BLE notifications
  void _handleBleNotification(List<int> rxData) async {
    if (rxData.isEmpty || !_isReceivingLogs) return;

    try {
      /// CLEANUP need to move this to head ble file, need to check if we get thus situtaion ever
      // Decrypt the frame if encryption is enabled
      final bool shouldDecrypt =
          _bleHandler != null &&
          _bleHandler!.encryptionDecryptionState.value ==
              EncryptionDecryptionState.enabled;

      FrameData? frame;
      if (shouldDecrypt) {
        try {
          /// CLEANUP need to move this to head ble file
          frame = await DataHandler().decryptTheDataPacketWithoutConversion(
            rxData,
          );
        } catch (e) {
          print("DEBUG: LogRetrieval - Failed to decrypt frame: $e");
          return;
        }
      } else {
        /// CLEANUP need to move this to head ble file
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
          _navigateToEventLogScreen();
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(
          //     builder:
          //         (context) => EventLogScreen(
          //           logDataList: _retrievedLogs,
          //           panelName: 'RHINO2008',
          //           panelVersionNo: '0.98',
          //           isStandalone: true,
          //           panelId: _capturedPanelId,
          //         ),
          //   ),
          // );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowExit,
      child: Scaffold(
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
                              _showStopConfirmationDialog();
                            },
                            child: SvgPicture.asset(
                              'assets/svgs/arrow_back_icon.svg',
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Event Log',
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
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  'Retrieving Logs...',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF918F8F),
                  ),
                ),
              ),
            ),
            Lottie.asset(
              'assets/jsons/fetching_log.json',
              height: 320,
              width: 320,
            ),
            // CupertinoActivityIndicator(
            //   radius: 20,
            //   color: Color(0xFFEC1D24),
            //   // animating:
            //   //     !_connectionFailed &&
            //   //     !_maxBleConnectionRetriesReached &&
            //   //     !_maxOtherPacketsRetriesReached,
            // ),
            // Padding(
            //   padding: const EdgeInsets.only(top: 100),
            //   child: Text(
            //     'Please Wait...',
            //     style: GoogleFonts.inter(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w400,
            //     ),
            //   ),
            // ),
            // Show connection status
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: ValueListenableBuilder<String>(
                valueListenable: ble.processDesc,
                builder: (context, value, _) {
                  final statusText =
                      value.isNotEmpty ? value : _connectionStatus;
                  return Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: ble.bleProcess.read1000LogsCount,
                      builder: (context, readCount, _) {
                        final percent =
                            (readCount / 1000.0).clamp(0.0, 1.0).toDouble();
                        final displayProgress =
                            readCount == 0 ? _progress : percent;
                        return Column(
                          children: [
                            Text(
                              '${(percent * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              maxLines: 1,
                            ),
                            SizedBox(height: 23),
                            LinearPercentIndicator(
                              lineHeight: 11.0,
                              percent: displayProgress,
                              backgroundColor: Color(0xFFD9D9D9),
                              progressColor: Color(0xFFEC1D24),
                              barRadius: Radius.circular(20),
                            ),
                            SizedBox(height: 10),
                            // Align(
                            //   alignment: Alignment.centerLeft,
                            //   child: Padding(
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 10,
                            //     ),
                            //     child: Text(
                            //       'Fetching Logs...',
                            //       style: GoogleFonts.inter(
                            //         fontSize: 14,
                            //         fontWeight: FontWeight.w400,
                            //       ),
                            //       maxLines: 1,
                            //     ),
                            //   ),
                            // ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: _buildCancelLogRetrievalButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add button widget for canceling log retrieval
  Widget _buildCancelLogRetrievalButton() {
    return GestureDetector(
      onTap: _showStopConfirmationDialog,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFEC1D24),
          borderRadius: BorderRadius.circular(28.5),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFEC1D24).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
    _connectionSub?.cancel();
    ble.bleProcess.isValidLogRecieved.removeListener(_onFirstValidLogReceived);
    ble.bleProcess.read1000LogsCount.removeListener(_onLogRetrievalCompleted);
    ble.maxBleConnectionRetriesReached.removeListener(
      _onMaxBleConnectionRetriesReached,
    );
    ble.maxOtherPacketsRetriesReached.removeListener(
      _onMaxOtherPacketsRetriesReached,
    );
    super.dispose();
  }
}
