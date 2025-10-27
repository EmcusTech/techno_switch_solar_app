import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:techno_switch_solar_app/screens/access_code_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:lottie/lottie.dart';

class DeviceConnectingScreen extends StatefulWidget {
  final dynamic
  selectedDevice; // Can be BluetoothDevice or UsbDevice or ScanResult
  final ScanType scanType;
  final bool? isLiveEvent;

  const DeviceConnectingScreen({
    super.key,
    required this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

  @override
  State<DeviceConnectingScreen> createState() => _DeviceConnectingScreenState();
}

class _DeviceConnectingScreenState extends State<DeviceConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _connectionStatus = "Initializing...";
  bool _connectionFailed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start connection attempt
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    if (widget.selectedDevice == null) {
      _handleConnectionFailure("No device selected");
      return;
    }

    setState(() {
      _connectionStatus = "Connecting to ${_getDeviceName()}...";
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      bool connected = false;

      if (widget.scanType == ScanType.bluetooth) {
        // Handle BLE device connection
        BluetoothDevice device;
        if (widget.selectedDevice is ScanResult) {
          device = (widget.selectedDevice as ScanResult).device;
        } else {
          device = widget.selectedDevice as BluetoothDevice;
        }

        setState(() {
          _connectionStatus = "Establishing Bluetooth connection...";
        });

        connected = await AppServices.serialService.connectToSpecificDevice(
          device,
        );
      } else {
        // Handle USB device connection
        setState(() {
          _connectionStatus = "Establishing USB connection...";
        });

        connected = await AppServices.serialService.connectToDevice();
      }

      if (connected && AppServices.isConnected) {
        setState(() {
          _connectionStatus = "Connected successfully!";
        });

        // Wait a moment to show success message
        await Future.delayed(const Duration(milliseconds: 800));

        // Navigate to access code screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => AccessCodeScreen(
                    selectedDevice: widget.selectedDevice,
                    scanType: widget.scanType,
                    isLiveEvent: widget.isLiveEvent,
                  ),
            ),
          );
        }
      } else {
        _handleConnectionFailure("Failed to establish connection");
      }
    } catch (e) {
      _handleConnectionFailure("Connection error: $e");
    }
  }

  void _handleConnectionFailure(String error) {
    setState(() {
      _connectionFailed = true;
      _errorMessage = error;
      _connectionStatus = "Connection Failed";
    });
    _animationController.stop();
  }

  String _getDeviceName() {
    if (widget.selectedDevice == null) return "Unknown Device";

    if (widget.scanType == ScanType.bluetooth) {
      if (widget.selectedDevice is ScanResult) {
        final name = (widget.selectedDevice as ScanResult).device.platformName;
        return name.isNotEmpty ? name : "BLE Device";
      } else if (widget.selectedDevice is BluetoothDevice) {
        final name = (widget.selectedDevice as BluetoothDevice).platformName;
        return name.isNotEmpty ? name : "BLE Device";
      }
    } else {
      if (widget.selectedDevice is UsbDevice) {
        return (widget.selectedDevice as UsbDevice).productName ?? "USB Device";
      }
    }

    return "Unknown Device";
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
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      _buildConnectionAnimation(),
                      const SizedBox(height: 20),
                      _buildDeviceInfo(),
                      const SizedBox(height: 24),
                      _buildStatusText(),
                      if (_connectionFailed) ...[
                        const SizedBox(height: 16),
                        _buildErrorMessage(),
                      ],
                      const Spacer(),
                      if (_connectionFailed) _buildRetryButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Lottie.asset(
          'assets/jsons/ble_connecting.json',
          animate: !_connectionFailed,
        );
        // return Container(
        //   width: 150,
        //   height: 150,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color:
        //         _connectionFailed
        //             ? Color(0xFFEC1D24).withOpacity(0.1)
        //             : Color(0xFFEC1D24).withOpacity(0.08),
        //     boxShadow:
        //         _connectionFailed
        //             ? []
        //             : [
        //               BoxShadow(
        //                 color: Color(
        //                   0xFFEC1D24,
        //                 ).withOpacity(0.3 * (1 - _animationController.value)),
        //                 blurRadius: 30 * _animationController.value,
        //                 spreadRadius: 20 * _animationController.value,
        //               ),
        //             ],
        //   ),
        //   child: Center(
        //     child: Icon(
        //       _connectionFailed
        //           ? Icons.error_outline
        //           : (widget.scanType == ScanType.bluetooth
        //               ? Icons.bluetooth_searching
        //               : Icons.usb),
        //       size: 60,
        //       color: _connectionFailed ? Color(0xFFEC1D24) : Color(0xFFEC1D24),
        //     ),
        //   ),
        // );
      },
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFB9B9B9).withOpacity(0.31),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (widget.scanType == ScanType.usb
                      ? Color(0xFFEC1D24)
                      : Colors.blue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset('assets/svgs/panel_icon.svg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDeviceName(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                Text(
                  widget.scanType == ScanType.usb
                      ? 'USB Device'
                      : 'Bluetooth Device',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _connectionStatus,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _connectionFailed ? Color(0xFFEC1D24) : Color(0xFF3D3D3D),
          ),
        ),
        if (!_connectionFailed) ...[
          const SizedBox(height: 8),
          Text(
            'Please wait...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF918F8F),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFEC1D24).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFEC1D24).withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage ?? "Unknown error occurred",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEC1D24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please make sure the device is powered on and in range.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEFEEEE),
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                      const SizedBox(width: 8),
                      Text(
                        'Go Back',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF49454F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _connectionFailed = false;
                  _errorMessage = null;
                  _connectionStatus = "Retrying...";
                });
                _animationController.repeat();
                _connectToDevice();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEC1D24),
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Retry',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.refresh, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
