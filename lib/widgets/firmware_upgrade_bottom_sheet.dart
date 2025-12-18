import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/models/mcu_info.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/firmware_upgrade_service.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart'
    as app_bluetooth;
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';
import 'package:usb_serial/usb_serial.dart';

enum FirmwareType { mainPanel, bleChip }

enum FirmwareUpgradeStep {
  essentialSteps,
  connectDevice,
  chooseType,
  fileUpload,
  fileDetails,
  progress,
  result,
}

class FirmwareUpgradeBottomSheet extends StatefulWidget {
  const FirmwareUpgradeBottomSheet({super.key});

  @override
  State<FirmwareUpgradeBottomSheet> createState() =>
      _FirmwareUpgradeBottomSheetState();
}

class _FirmwareUpgradeBottomSheetState extends State<FirmwareUpgradeBottomSheet>
    with SingleTickerProviderStateMixin {
  final UpdatesController _controller = Get.find<UpdatesController>();
  late final BleNotifyDataHandler _bleHandler;
  FirmwareUpgradeStep _currentStep = FirmwareUpgradeStep.essentialSteps;
  FirmwareType? _selectedFirmwareType;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isUpgrading = false;
  String? _errorMessage;
  String? _currentBleStateMessage;

  // Test mode flag - set to true to skip BLE connection for testing file processing
  bool _testMode = true;

  // BLE connection state
  bool _isScanning = false;
  bool _isConnecting = false;
  List<dynamic> _discoveredDevices = []; // Can be ScanResult or BluetoothDevice
  DiscoveredDevice? _selectedDevice;
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  bool _handshakeComplete = false;
  String _connectionStatus = '';
  String? _passkeyError;
  final TextEditingController _passkeyController = TextEditingController();

  // Radar scanning state (from scanning_screen.dart)
  final app_bluetooth.BluetoothService _bluetoothService =
      app_bluetooth.BluetoothService();
  StreamSubscription? _bleResultsSub;
  late final AnimationController _sweepController;

  StreamSubscription<DeviceConnectionState>? _connectionSub;

  // Slot assignment (stable positions)
  final Map<String, int> _assignedSlot = {}; // deviceKey -> slotIndex
  final Map<int, String> _slotToDevice = {}; // slotIndex -> deviceKey
  final Map<String, DateTime> _lastSeen = {}; // deviceKey -> last seen
  final Map<String, bool> _justAssigned = {}; // deviceKey -> just assigned flag

  final int maxSlots = 12;
  final int staleTimeoutSeconds = 20;

  @override
  void initState() {
    super.initState();

    // Initialize sweep controller for radar animation
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Get BLE handler if available
    try {
      if (Get.isRegistered<BleNotifyDataHandler>()) {
        _bleHandler = Get.find<BleNotifyDataHandler>();
      } else {
        _bleHandler = Get.put(BleNotifyDataHandler());
      }
    } catch (e) {
      logger.Logger('BleNotifyDataHandler not available: $e');
      _bleHandler = Get.put(BleNotifyDataHandler());
    }

    // Listen to download status changes
    _controller.downloadingStatus.listen((status) {
      if (mounted) {
        if (status == DownloadStatus.upgrading) {
          setState(() {
            if (_currentStep == FirmwareUpgradeStep.fileDetails ||
                _currentStep == FirmwareUpgradeStep.progress) {
              _currentStep = FirmwareUpgradeStep.progress;
              _isUpgrading = true;
            }
          });
        } else if (status == DownloadStatus.completed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage = null;
          });
        } else if (status == DownloadStatus.failed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage = _errorMessage ?? 'Firmware upgrade failed';
          });
        }
      }
    });

    // Listen to BLE state changes for better feedback
    _bleHandler.currentBleState.listen((state) {
      if (mounted) {
        if (_isUpgrading) {
          setState(() {
            switch (state) {
              case BleStateMachine.mcuSelection:
                _currentBleStateMessage = 'Selecting MCU...';
                break;
              case BleStateMachine.eofImageData:
                _currentBleStateMessage = 'Sending EOF image data...';
                break;
              case BleStateMachine.dataSyncRequest:
                _currentBleStateMessage = 'Synchronizing data...';
                break;
              case BleStateMachine.sendingLargePacketOnGoing:
                _currentBleStateMessage = 'Sending firmware packets...';
                break;
              case BleStateMachine.dataEndRequest:
                _currentBleStateMessage = 'Finalizing upgrade...';
                break;
              case BleStateMachine.respondToEndPacket:
                _currentBleStateMessage = 'Upgrade completed!';
                break;
              default:
                // Don't update message for non-firmware states
                break;
            }
          });
        } else if (_currentStep == FirmwareUpgradeStep.connectDevice) {
          // Check if handshake is complete
          if (state == BleStateMachine.connected) {
            setState(() {
              _handshakeComplete = true;
              _connectionStatus = 'Device connected and authenticated';
            });
          }
        }
      }
    });

    // Check initial connection status
    _checkInitialConnection();
  }

  @override
  void dispose() {
    _handshakeSubscription?.cancel();
    _bleResultsSub?.cancel();
    _bluetoothService.dispose();
    _sweepController.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    final btUtils = BtUtils();
    final connectedDevice = await btUtils.getConnectedDevice();

    if (connectedDevice != null && Get.isRegistered<BleNotifyDataHandler>()) {
      final handler = Get.find<BleNotifyDataHandler>();
      if (handler.currentBleState.value == BleStateMachine.connected) {
        setState(() {
          _selectedDevice = connectedDevice;
          _handshakeComplete = true;
          _connectionStatus = 'Device already connected';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        // controller: scrollController,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildStepIndicator(),
              SizedBox(height: 24),
              _buildStepContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Firmware Upgrade',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        // Test Mode Toggle
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                _testMode
                    ? Color(0xFFEC1D24).withOpacity(0.1)
                    : Color(0xFFD9D9D9).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bug_report,
                size: 16,
                color: _testMode ? Color(0xFFEC1D24) : Color(0xFF979797),
              ),
              SizedBox(width: 8),
              Text(
                'Test Mode',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _testMode ? Color(0xFFEC1D24) : Color(0xFF979797),
                ),
              ),
              SizedBox(width: 8),
              Switch(
                value: _testMode,
                onChanged: (value) {
                  setState(() {
                    _testMode = value;
                    logger.Logger(
                      'Test Mode ${value ? "ENABLED" : "DISABLED"}',
                    );
                  });
                },
                activeColor: Color(0xFFEC1D24),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Steps',
      'Connect',
      'Type',
      'Upload',
      'Details',
      'Progress',
      'Result',
    ];
    final currentIndex = FirmwareUpgradeStep.values.indexOf(_currentStep);

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isActive
                          ? (isCurrent ? Color(0xFFEC1D24) : Color(0xFF00A706))
                          : Color(0xFFD9D9D9),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Color(0xFF979797),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                steps[index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Color(0xFF1B1F26) : Color(0xFF979797),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case FirmwareUpgradeStep.essentialSteps:
        return _buildEssentialSteps();
      case FirmwareUpgradeStep.connectDevice:
        return _buildConnectDevice();
      case FirmwareUpgradeStep.chooseType:
        return _buildChooseType();
      case FirmwareUpgradeStep.fileUpload:
        return _buildFileUpload();
      case FirmwareUpgradeStep.fileDetails:
        return _buildFileDetails();
      case FirmwareUpgradeStep.progress:
        return _buildProgress();
      case FirmwareUpgradeStep.result:
        return _buildResult();
    }
  }

  Widget _buildEssentialSteps() {
    final steps = [
      'Ensure the device is connected via Bluetooth',
      'Keep the device powered on throughout the upgrade',
      'Do not disconnect or turn off the device during upgrade',
      'Ensure sufficient battery level (recommended: >50%)',
      'Close other apps that might interfere with Bluetooth',
    ];

    return FutureBuilder<bool>(
      future: _checkBleConnection(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Essential Steps Before Firmware Upgrade',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            if (!isConnected)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFFC107)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Color(0xFFFF9800)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Device not connected. Please connect via Bluetooth before proceeding.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...steps.map(
              (step) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEC1D24).withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFFEC1D24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1B1F26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_testMode) {
                    // Skip connection step in test mode
                    _currentStep = FirmwareUpgradeStep.chooseType;
                    logger.Logger(
                      'TEST MODE: Skipping BLE connection step, going directly to Choose Type',
                    );
                  } else {
                    _currentStep = FirmwareUpgradeStep.connectDevice;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC1D24),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkBleConnection() async {
    try {
      final btUtils = BtUtils();
      final connectedDevice = await btUtils.getConnectedDevice();
      if (connectedDevice == null) return false;

      // Check if BLE handler is registered and state is connected
      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final handler = Get.find<BleNotifyDataHandler>();
        return handler.currentBleState.value == BleStateMachine.connected;
      }

      return false;
    } catch (e) {
      logger.Logger('Error checking BLE connection: $e');
      return false;
    }
  }

  Widget _buildConnectDevice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connect Device',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        if (_handshakeComplete && _selectedDevice != null)
          _buildConnectedDeviceCard()
        else if (_isConnecting)
          _buildConnectingView()
        else if (_isScanning || _discoveredDevices.isNotEmpty)
          Column(
            children: [
              _buildScanningView(),
              if (_discoveredDevices.isNotEmpty && !_isScanning) ...[
                SizedBox(height: 24),
                Text(
                  'Tap on a device card above to connect',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF979797),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                _buildDevicesList(),
              ],
            ],
          )
        else
          _buildScanPrompt(),
        if (_passkeyError != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFEC1D24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Color(0xFFEC1D24), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _passkeyError!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_handshakeComplete &&
            _selectedDevice != null &&
            _bleHandler.currentBleState.value == BleStateMachine.connected) ...[
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = FirmwareUpgradeStep.chooseType;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEC1D24),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF00A706).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF00A706)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF00A706)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDevice?.name ?? 'Connected Device',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B1F26),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _connectionStatus,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF979797),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return Column(
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1D24)),
        ),
        SizedBox(height: 16),
        Text(
          _connectionStatus.isNotEmpty
              ? _connectionStatus
              : 'Connecting to device...',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF979797),
          ),
          textAlign: TextAlign.center,
        ),
        if (_bleHandler.currentBleState.value ==
            BleStateMachine.requestedPasskey) ...[
          SizedBox(height: 24),
          _buildPasskeyInput(),
        ],
      ],
    );
  }

  Widget _buildScanningView() {
    const double radarSize = 280; // Smaller for bottom sheet
    final double center = radarSize / 2;
    final double fixedRadius = radarSize * 0.35;
    const double cardWidth = 100;
    const double cardHeight = 120;

    return Column(
      children: [
        SizedBox(
          height: radarSize,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radar background
              SizedBox(
                width: radarSize,
                height: radarSize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RadarPainter(
                            sweepAnimation: _sweepController,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _sweepController,
                          builder:
                              (c, _) => CustomPaint(
                                painter: _SweepPainter(
                                  progress: _sweepController.value,
                                ),
                              ),
                        ),
                      ),
                    ),
                    ..._buildSlotWidgets(
                      radarSize,
                      center,
                      fixedRadius,
                      cardWidth,
                      cardHeight,
                    ),
                  ],
                ),
              ),
              // Central scanning animation
              ScanningAnimation(),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Scanning for devices...',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF979797),
          ),
        ),
        if (_discoveredDevices.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_discoveredDevices.length} device(s) found - Tap on radar to connect',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF00A706),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (_isScanning) ...[
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: GestureDetector(
              onTap: () {
                _bluetoothService.stopScanning();
                setState(() {
                  _isScanning = false;
                });
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC1D24),
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Stop Scanning',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScanPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFFF6EBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFEC1D24).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 64,
                color: Color(0xFFEC1D24),
              ),
              SizedBox(height: 16),
              Text(
                'No device connected',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1F26),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Scan for nearby Bluetooth devices to connect',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF979797),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isScanning ? null : _startScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEC1D24),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Color(0xFFD9D9D9),
          ),
          child: Text(
            'Scan for Devices',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: _discoveredDevices.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = _discoveredDevices[index];
              DiscoveredDevice? bluetoothDevice;

              if (device is DiscoveredDevice) {
                bluetoothDevice = device;
              }

              if (bluetoothDevice == null) return SizedBox();

              final deviceName =
                  bluetoothDevice.name.isNotEmpty
                      ? bluetoothDevice.name
                      : 'Unknown Device';

              return GestureDetector(
                onTap: () => _connectToDevice(bluetoothDevice!),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth, color: Color(0xFFEC1D24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deviceName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1F26),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              bluetoothDevice.id,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF979797),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Color(0xFF979797),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            _bluetoothService.stopScanning();
            _startScan();
          },
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Color(0xFFEC1D24)),
          ),
          child: Text(
            'Scan Again',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEC1D24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasskeyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Level-3 Passkey',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1F26),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _passkeyController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            hintText: 'Enter 4-digit passkey',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: _passkeyError,
          ),
        ),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isConnecting ? null : _submitPasskey,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEC1D24),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Color(0xFFD9D9D9),
          ),
          child: Text(
            'Submit Passkey',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
      _errorMessage = null;
      _assignedSlot.clear();
      _slotToDevice.clear();
      _lastSeen.clear();
      _justAssigned.clear();
    });

    try {
      await _bluetoothService.requestPermissions();
      final poweredOn = await _bluetoothService.ensurePoweredOn();

      if (!poweredOn) {
        setState(() {
          _isScanning = false;
          _errorMessage =
              'Bluetooth is not enabled. Please enable Bluetooth and try again.';
        });
        return;
      }

      // Set up scan listener
      await _bleResultsSub?.cancel();
      _bleResultsSub = _bluetoothService.scanResultsStream.listen((results) {
        if (mounted) {
          _handleNewScanResults(results.map((r) => r as dynamic).toList());
        }
      });

      // Start scanning
      await _bluetoothService.startScanning();

      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isScanning) {
          _bluetoothService.stopScanning();
          setState(() {
            _isScanning = false;
            if (_discoveredDevices.isEmpty) {
              _errorMessage =
                  'No devices found. Please ensure the device is powered on and in range.';
            }
          });
        }
      });
    } catch (e) {
      logger.Logger('Error scanning for devices: $e');
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error scanning for devices: $e';
      });
    }
  }

  // Device key computation (from scanning_screen.dart)
  String? _computeStableKey(dynamic device) {
    if (device == null) {
      return null;
    }

    if (device is DiscoveredDevice) {
      return 'ble:${device.id}';
    }

    if (device is UsbDevice) {
      return 'usb:${device.vid}:${device.pid}';
    }

    if (device is Map) {
      final candidates = <String?>[
        device['id']?.toString(),
        device['deviceId']?.toString(),
        device['address']?.toString(),
        device['mac']?.toString(),
        device['uuid']?.toString(),
      ];

      for (final c in candidates) {
        if (c != null && c.isNotEmpty) {
          return 'map:$c';
        }
      }
    }

    return device.toString();

    // //
    // try {
    //   if (device == null) return null;

    //   if (device is ScanResult) {
    //     return device.device.remoteId.str;
    //   }

    //   if (device is Map) {
    //     final map = device;
    //     final candidates = <String?>[
    //       map['address']?.toString(),
    //       map['id']?.toString(),
    //       map['deviceId']?.toString(),
    //       map['mac']?.toString(),
    //       map['uuid']?.toString(),
    //     ];
    //     for (var c in candidates) {
    //       if (c != null && c.isNotEmpty) return 'field:$c';
    //     }
    //   }

    //   final dyn = device;
    //   try {
    //     final remoteId = (dyn as dynamic).remoteId;
    //     if (remoteId != null) {
    //       final str = (remoteId as dynamic).str;
    //       if (str != null && str.toString().isNotEmpty) return str.toString();
    //     }
    //   } catch (_) {}

    //   try {
    //     final id = (dyn as dynamic).id;
    //     if (id != null && id.toString().isNotEmpty) return 'id:$id';
    //   } catch (_) {}

    //   return device.toString();
    // } catch (e) {
    //   logger.Logger('Error computing stable key: $e');
    //   return null;
    // }
  }

  int? _findFreeSlot() {
    for (int i = 0; i < maxSlots; i++) {
      if (!_slotToDevice.containsKey(i)) return i;
    }
    return null;
  }

  int _hashToSlot(String key) {
    int h = 0;
    for (int i = 0; i < key.length; i++) {
      h = (h * 31 + key.codeUnitAt(i)) & 0x7fffffff;
    }
    return h % maxSlots;
  }

  void _handleNewScanResults(List<dynamic> results) {
    final Map<String, dynamic> keyToDevice = {};

    for (var d in results) {
      final key = _computeStableKey(d);
      if (key == null) continue;
      keyToDevice[key] = d;
      _lastSeen[key] = DateTime.now();

      if (!_assignedSlot.containsKey(key)) {
        final free = _findFreeSlot();
        if (free != null) {
          _assignedSlot[key] = free;
          _slotToDevice[free] = key;
          _justAssigned[key] = true;
          Timer(const Duration(milliseconds: 900), () {
            if (mounted) {
              setState(() {
                _justAssigned.remove(key);
              });
            }
          });
        } else {
          final fallback = _hashToSlot(key);
          _assignedSlot[key] = fallback;
          _slotToDevice[fallback] = key;
          _justAssigned[key] = true;
          Timer(const Duration(milliseconds: 900), () {
            if (mounted) {
              setState(() {
                _justAssigned.remove(key);
              });
            }
          });
        }
      }
    }

    // Remove stale devices
    final cutoff = DateTime.now().subtract(
      Duration(seconds: staleTimeoutSeconds),
    );
    final stale =
        _lastSeen.entries
            .where((e) => e.value.isBefore(cutoff))
            .map((e) => e.key)
            .toList();
    for (var sid in stale) {
      final slot = _assignedSlot.remove(sid);
      if (slot != null) _slotToDevice.remove(slot);
      _lastSeen.remove(sid);
      _justAssigned.remove(sid);
    }

    // Build ordered list of devices present (by slot order)
    final Map<int, dynamic> devicesBySlot = {};
    for (var entry in keyToDevice.entries) {
      final k = entry.key;
      final dev = entry.value;
      final slot = _assignedSlot[k];
      if (slot != null) devicesBySlot[slot] = dev;
    }

    if (mounted) {
      setState(() {
        final slots = devicesBySlot.keys.toList()..sort();
        _discoveredDevices = slots.map((s) => devicesBySlot[s]!).toList();
      });
    }
  }

  String _deviceLabel(dynamic device) {
    if (device is DiscoveredDevice) {
      if (device.name.isNotEmpty) {
        return device.name;
      }

      return 'BLE-${device.id.substring(0, 5)}';
    }

    if (device is UsbDevice) {
      return device.productName ?? 'USB Device';
    }

    if (device is Map) {
      final name = device['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    return 'Unknown Device';

    // //
    // try {
    //   if (device is ScanResult) {
    //     final name = device.device.platformName;
    //     if (name.isNotEmpty) return name;
    //     return device.device.remoteId.str;
    //   }

    //   final dyn = device;
    //   try {
    //     final platformName = (dyn as dynamic).platformName;
    //     if (platformName != null && platformName.toString().isNotEmpty) {
    //       return platformName.toString();
    //     }
    //   } catch (_) {}

    //   try {
    //     final name = (dyn as dynamic).name;
    //     if (name != null && name.toString().isNotEmpty) return name.toString();
    //   } catch (_) {}

    //   return 'Unknown Device';
    // } catch (_) {
    //   return device.toString();
    // }
  }

  List<Widget> _buildSlotWidgets(
    double radarSize,
    double center,
    double fixedRadius,
    double cardWidth,
    double cardHeight,
  ) {
    final widgets = <Widget>[];

    for (int slot = 0; slot < maxSlots; slot++) {
      final angle = _angleForSlot(slot);
      final dx = center + fixedRadius * cos(angle);
      final dy = center + fixedRadius * sin(angle);

      final deviceKey = _slotToDevice[slot];
      if (deviceKey == null || !_lastSeen.containsKey(deviceKey)) continue;

      DiscoveredDevice? device;
      try {
        device = _discoveredDevices.firstWhere(
          (d) => _computeStableKey(d) == deviceKey,
        );
      } catch (_) {
        device = null;
      }

      if (device == null) continue;

      final label = _deviceLabel(device);
      final justAssigned = _justAssigned.containsKey(deviceKey);

      // Center the card at dx/dy and clamp within radar
      final left = (dx - cardWidth / 2).clamp(4.0, radarSize - cardWidth);
      final top = (dy - cardHeight / 2).clamp(4.0, radarSize - cardHeight);

      widgets.add(
        Positioned(
          key: ValueKey('card-$deviceKey'),
          left: left,
          top: top,
          width: cardWidth,
          height: cardHeight,
          child: GestureDetector(
            onTap: () {
              // Stop scanning before connecting
              if (_isScanning) {
                _bluetoothService.stopScanning();
                setState(() {
                  _isScanning = false;
                });
              }
              _connectToDevice(device!);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              opacity: 1.0,
              child: AnimatedScale(
                scale: justAssigned ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                child: Material(
                  color: Colors.white.withOpacity(0.95),
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: cardHeight * 0.7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                'assets/svgs/panel_icon.svg',
                                width: cardWidth * 0.4,
                                height: cardWidth * 0.4,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  double _angleForSlot(int slotIndex) {
    return (slotIndex * (2 * pi / maxSlots));
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    // Stop scanning if still active
    if (_isScanning) {
      _bluetoothService.stopScanning();
      setState(() {
        _isScanning = false;
      });
    }

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
      _connectionStatus = 'Connecting to ${device.name}...';
      _errorMessage = null;
      _passkeyError = null;
    });

    // Listen to handshake events
    _handshakeSubscription?.cancel();
    _handshakeSubscription = AppServices.bleService.handshakeEvents.listen(
      _handleHandshakeEvent,
    );

    try {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });

      _connectionSub = AppServices.bleService
          .connectToDevice(device)
          .listen(
            (state) {
              switch (state) {
                case DeviceConnectionState.connecting:
                  setState(() {
                    _connectionStatus = 'Connecting...';
                  });
                  break;

                case DeviceConnectionState.connected:
                  setState(() {
                    _connectionStatus = 'Connected. Waiting for handshake...';
                    _isConnecting = false;
                  });
                  break;

                case DeviceConnectionState.disconnected:
                  setState(() {
                    _isConnecting = false;
                    _errorMessage = 'Device disconnected';
                  });
                  _connectionSub?.cancel();
                  break;
                default:
                  break;
              }
            },
            onError: (e) {
              logger.Logger('Error connecting to device: $e');
              setState(() {
                _isConnecting = false;
                _errorMessage = 'Connection error: $e';
              });
            },
          );
    } catch (e) {
      logger.Logger('Error connecting to device: $e');
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  void _handleHandshakeEvent(BleHandshakeEvent event) {
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
          _connectionStatus = 'Encryption key received';
        });
        break;
      case BleHandshakeEventType.authenticated:
        setState(() {
          _connectionStatus = 'Authenticated';
        });
        break;
      case BleHandshakeEventType.passkeyRequested:
        setState(() {
          _connectionStatus = 'Enter Level-3 passkey (30 seconds timeout)';
        });
        break;
      case BleHandshakeEventType.passkeyAccepted:
        setState(() {
          _connectionStatus = 'Passkey accepted';
          _handshakeComplete = true;
          _isConnecting = false;
        });
        break;
      case BleHandshakeEventType.error:
        setState(() {
          _errorMessage = event.message ?? 'Handshake error';
          _passkeyError = event.message;
          _isConnecting = false;
        });
        break;
    }
  }

  Future<void> _submitPasskey() async {
    final passkey = _passkeyController.text.trim();
    if (passkey.length != 4) {
      setState(() {
        _passkeyError = 'Please enter a 4-digit passkey';
      });
      return;
    }

    setState(() {
      _passkeyError = null;
      _connectionStatus = 'Submitting passkey...';
    });

    try {
      await AppServices.bleService.submitPasskey(passkey);
    } catch (e) {
      logger.Logger('Error submitting passkey: $e');
      setState(() {
        _passkeyError = 'Error submitting passkey: $e';
      });
    }
  }

  Widget _buildChooseType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose Firmware Type',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        _buildFirmwareTypeOption(
          title: 'Main Panel Firmware',
          description: 'Upgrade the main panel firmware',
          type: FirmwareType.mainPanel,
        ),
        SizedBox(height: 16),
        _buildFirmwareTypeOption(
          title: 'BLE Chip Firmware',
          description: 'Upgrade the Bluetooth chip firmware',
          type: FirmwareType.bleChip,
        ),
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.connectDevice;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Color(0xFFEC1D24)),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC1D24),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    _selectedFirmwareType == null
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileUpload;
                          });
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEC1D24),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Color(0xFFD9D9D9),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirmwareTypeOption({
    required String title,
    required String description,
    required FirmwareType type,
  }) {
    final isSelected = _selectedFirmwareType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFirmwareType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFEC1D24).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Color(0xFFEC1D24) : Color(0xFFD9D9D9),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFFEC1D24) : Color(0xFFD9D9D9),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEC1D24),
                          ),
                        ),
                      )
                      : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1F26),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF979797),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload Firmware File',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFFF6EBEB),
              border: Border.all(
                color: Color(0xFFEC1D24).withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: Color(0xFFEC1D24),
                ),
                SizedBox(height: 16),
                Text(
                  _selectedFile == null
                      ? 'Tap to select firmware file'
                      : _selectedFile!.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B1F26),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedFile != null) ...[
                  SizedBox(height: 8),
                  Text(
                    '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF979797),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isUploading) ...[
          SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: Color(0xFFD9D9D9),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1D24)),
          ),
        ],
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.chooseType;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Color(0xFFEC1D24)),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC1D24),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _selectedFile == null || _isUploading
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileDetails;
                          });
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEC1D24),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Color(0xFFD9D9D9),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileDetails() {
    if (_selectedFile == null) return SizedBox();

    return Obx(() {
      final isCrcMatched = _controller.isFileCrcMatched.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'File Details',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 24),
          _buildDetailRow('File Name', _selectedFile!.name),
          SizedBox(height: 12),
          _buildDetailRow(
            'File Size',
            '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            'Firmware Type',
            _selectedFirmwareType == FirmwareType.mainPanel
                ? 'Main Panel Firmware'
                : 'BLE Chip Firmware',
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            'CRC Status',
            isCrcMatched ? 'Valid' : 'Invalid',
            valueColor: isCrcMatched ? Color(0xFF00A706) : Color(0xFFEC1D24),
          ),
          SizedBox(height: 32),
          if (!isCrcMatched)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFEC1D24).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFEC1D24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _testMode
                          ? 'File CRC validation failed. Test mode: You can proceed anyway.'
                          : 'File CRC validation failed. Please select a valid firmware file.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFEC1D24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = FirmwareUpgradeStep.fileUpload;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Color(0xFFEC1D24)),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      (!isCrcMatched && !_testMode)
                          ? null
                          : () {
                            if (_testMode && !isCrcMatched) {
                              logger.Logger(
                                'TEST MODE: Proceeding despite CRC validation failure',
                              );
                            }
                            _startFirmwareUpgrade();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC1D24),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Color(0xFFD9D9D9),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF979797),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Color(0xFF1B1F26),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Obx(() {
      final progress = _controller.progressbarCount.value;
      final currentIndex = _controller.progressbarIndex.value;
      final totalPackets = _controller.totalPacketLength.value;
      final status = _controller.downloadingStatus.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Firmware Upgrade in Progress',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 32),
          Center(
            child: CircularPercentIndicator(
              radius: 80,
              lineWidth: 12,
              percent: progress.clamp(0.0, 1.0),
              center: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEC1D24),
                ),
              ),
              progressColor: Color(0xFFEC1D24),
              backgroundColor: Color(0xFFD9D9D9),
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          SizedBox(height: 24),
          if (totalPackets > 0)
            Text(
              'Packet $currentIndex of $totalPackets',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF979797),
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progress.clamp(0.0, 1.0),
            backgroundColor: Color(0xFFD9D9D9),
            progressColor: Color(0xFFEC1D24),
            barRadius: Radius.circular(4),
          ),
          SizedBox(height: 24),
          Text(
            _currentBleStateMessage ??
                (status == DownloadStatus.upgrading
                    ? 'Please wait while the firmware is being upgraded. Do not disconnect the device.'
                    : 'Processing...'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF979797),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  Widget _buildResult() {
    final isSuccess =
        _controller.downloadingStatus.value == DownloadStatus.completed;
    final message =
        _errorMessage ??
        (isSuccess
            ? 'Firmware upgrade completed successfully!'
            : 'Firmware upgrade failed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSuccess
                      ? Color(0xFF00A706).withOpacity(0.1)
                      : Color(0xFFEC1D24).withOpacity(0.1),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 48,
              color: isSuccess ? Color(0xFF00A706) : Color(0xFFEC1D24),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          isSuccess ? 'Success!' : 'Failed',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isSuccess ? Color(0xFF00A706) : Color(0xFFEC1D24),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1B1F26),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Reset state
            _controller.downloadingStatus.value = DownloadStatus.downloading;
            _controller.isFileCrcMatched.value = false;
            _controller.selectedFirmwareFile = null;
            _controller.progressbarIndex.value = 0;
            _controller.progressbarCount.value = 0.0;
            _controller.totalPacketLength.value = 0;
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEC1D24),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Done',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final platformFile = PlatformFile(
          name: result.files.single.name,
          path: result.files.single.path,
          size: await file.length(),
          bytes: await file.readAsBytes(),
        );

        _controller.selectFirmwareFile(platformFile);

        // Set firmware type in controller (0 = mainPanel, 1 = bleChip)
        _controller.selectedFirmwareType =
            _selectedFirmwareType == FirmwareType.bleChip ? 1 : 0;

        // Validate CRC for local file
        FirmwareUpgradeService().validateLocalFileCrc(platformFile);

        // Process the file as single MCU firmware
        try {
          await _controller.readAndSplitBinFile(result.files.single.path!);
        } catch (e) {
          logger.Logger('Error processing file: $e');
          // File might still be selected even if processing fails
        }

        setState(() {
          _selectedFile = platformFile;
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      logger.Logger('Error picking file: $e');
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _startFirmwareUpgrade() async {
    if (_selectedFile?.path == null) return;

    try {
      // Skip BLE connection check in test mode
      if (!_testMode) {
        // Check BLE connection before starting
        final btUtils = BtUtils();
        final connectedDevice = await btUtils.getConnectedDevice();

        if (connectedDevice == null) {
          setState(() {
            _errorMessage = 'Please connect to the device via Bluetooth first';
            _currentStep = FirmwareUpgradeStep.result;
          });
          return;
        }

        // Check if BLE state is connected
        if (_bleHandler.currentBleState.value != BleStateMachine.connected) {
          setState(() {
            _errorMessage =
                'Device is not fully connected. Please ensure the handshake is complete.';
            _currentStep = FirmwareUpgradeStep.result;
          });
          return;
        }
      } else {
        logger.Logger('TEST MODE: Skipping BLE connection checks');
      }

      // Set status to upgrading immediately
      _controller.downloadingStatus.value = DownloadStatus.upgrading;

      setState(() {
        _isUpgrading = true;
        _currentStep = FirmwareUpgradeStep.progress;
        _currentBleStateMessage = 'Initializing firmware upgrade...';
        _errorMessage = null;
      });

      // Process mismatched MCUs and start upgrade
      // For now, we'll process all MCUs
      final mismatchedIndexes = List.generate(
        _controller.mcuInfoList.length,
        (index) => index,
      );

      await _controller.processMismatchedMCUs(mismatchedIndexes);

      if (_testMode) {
        logger.Logger(
          'TEST MODE: File processing completed. Starting BLE simulation...',
        );
        // In test mode, simulate BLE responses to show progress
        // First, set up the MCU type data for simulation
        if (_controller.mismatchedMcuInfos.isNotEmpty) {
          final MCUInfo firstMcu = _controller.mismatchedMcuInfos[0];
          _controller.typeData = _controller.getTypeDataForMcu(
            firstMcu.mcuType,
          );
          _controller.mainMcuLast100Byte = firstMcu.last100Bytes;
        }
        // Start simulation (await to ensure it completes)
        await _controller.simulateBleFirmwareUpgrade();
      } else {
        // The upgrade process will be handled by the BLE state machine
        // Progress updates will come through the controller observables
        // BLE state changes will update _currentBleStateMessage
        // Start the actual BLE upgrade flow
        if (_controller.mismatchedMcuInfos.isNotEmpty) {
          final MCUInfo firstMcu = _controller.mismatchedMcuInfos[0];
          _controller.mismatchedMcuInfos.removeAt(0);
          _controller.readBinFile(firstMcu.byteData);
          _controller.selectedMcu(firstMcu.mcuType);
        }
      }
    } catch (e) {
      logger.Logger('Error starting firmware upgrade: $e');
      _controller.downloadingStatus.value = DownloadStatus.failed;
      setState(() {
        _errorMessage = 'Error starting upgrade: ${e.toString()}';
        _currentStep = FirmwareUpgradeStep.result;
        _isUpgrading = false;
      });
    }
  }
}

// Radar painters (from scanning_screen.dart)
class _RadarPainter extends CustomPainter {
  final Animation<double> sweepAnimation;
  _RadarPainter({required this.sweepAnimation})
    : super(repaint: sweepAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final int rings = 4;
    for (int i = 1; i <= rings; i++) {
      paint.color = Colors.green.withOpacity(0.12 + i * 0.03);
      canvas.drawCircle(center, (size.width / 2) * (i / (rings + 1)), paint);
    }

    final centerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(center, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

class _SweepPainter extends CustomPainter {
  final double progress;
  _SweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.green.withOpacity(0.22),
              Colors.green.withOpacity(0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.fill;

    final angle = progress * 2 * pi;
    final double sweep = pi / 6;
    final path = Path()..moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      angle - sweep / 2,
      sweep,
      false,
    );
    path.close();

    canvas.drawPath(path, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
