import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';

class AccessCodeScreen extends StatefulWidget {
  final dynamic
  selectedDevice; // Can be BluetoothDevice or UsbDevice or ScanResult
  final ScanType scanType;

  const AccessCodeScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
  });

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  late TextEditingController _accessCodeController;
  bool _isConnecting = false;
  String _connectionStatus = "Not connected";

  @override
  void initState() {
    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(() {
      setState(() {});
    });

    // Check if already connected
    if (AppServices.isConnected) {
      _connectionStatus =
          "Connected to: ${AppServices.connectedDevice?.platformName ?? 'Device'}";
    } else {
      // Auto-connect to the selected device
      _connectToSelectedDevice();
    }

    super.initState();
  }

  Future<void> _connectToSelectedDevice() async {
    if (widget.selectedDevice == null || AppServices.isConnected) return;

    setState(() {
      _isConnecting = true;
      _connectionStatus = "Connecting...";
    });

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
        connected = await AppServices.serialService.connectToSpecificDevice(
          device,
        );
      } else {
        // Handle USB device connection
        // For USB, we'd need to modify the service to handle USB devices too
        // For now, just try the general connect method
        connected = await AppServices.serialService.connectToDevice();
      }

      setState(() {
        _isConnecting = false;
        if (connected) {
          _connectionStatus = "Connected to: ${_getDeviceName()}";
        } else {
          _connectionStatus = "Connection failed";
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = "Connection error: $e";
      });
    }
  }

  String _getDeviceName() {
    if (widget.selectedDevice == null) return "Unknown Device";

    if (widget.scanType == ScanType.bluetooth) {
      if (widget.selectedDevice is ScanResult) {
        return (widget.selectedDevice as ScanResult).device.platformName;
      } else if (widget.selectedDevice is BluetoothDevice) {
        return (widget.selectedDevice as BluetoothDevice).platformName;
      }
    } else {
      if (widget.selectedDevice is UsbDevice) {
        return (widget.selectedDevice as UsbDevice).productName ?? "USB Device";
      }
    }

    return "Unknown Device";
  }

  Widget _buildConnectionStatus() {
    return Container(
      decoration: BoxDecoration(
        color: AppServices.isConnected ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
          color: AppServices.isConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _isConnecting
                  ? Icons.bluetooth_searching
                  : (AppServices.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled),
              color: AppServices.isConnected ? Colors.green : Colors.orange,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _connectionStatus,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      AppServices.isConnected
                          ? Colors.green[700]
                          : Colors.orange[700],
                ),
              ),
            ),
            if (_isConnecting)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 54,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
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
                    SizedBox(height: 52),
                    _buildConnectionStatus(),
                    SizedBox(height: 16),
                    _buildAccesCodeContainer(),
                  ],
                ),
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildAccesCodeContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 55,
          bottom: 85,
          left: 20,
          right: 20,
        ),
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Color(0xFFEC1D24).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/lock_icon.svg',
                  height: 48,
                  width: 48,
                ),
              ),
            ),
            SizedBox(height: 41),
            Text(
              'Access Code Required',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 74),
            Text(
              'Enter your access code ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF696969),
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _accessCodeController,
                  // maxLength: 4,
                  showCursor: false,
                  obscureText: true,
                  obscuringCharacter: "*",
                  onTapOutside: (value) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    counterText: '',
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFEFEEEE),
                borderRadius: BorderRadius.circular(28.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 18,
                  left: 16,
                  right: 34,
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              if (_accessCodeController.text.isEmpty) {
                return;
              }

              // Check if device is connected before proceeding
              if (!AppServices.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Device not connected. Current state: ${AppServices.connectionState}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _accessCodeController.clear();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LogRetrievalLoadingScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    _accessCodeController.text.isEmpty
                        ? Color(0xFFDADADA)
                        : Color(0xFFEC1D24),
                borderRadius: BorderRadius.circular(28.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 18,
                  bottom: 18,
                  left: 27,
                  right: 23,
                ),
                child: Row(
                  children: [
                    Text(
                      'Retrieve Data',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 13),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
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
    _accessCodeController.dispose();
    super.dispose();
  }
}
