// paste this entire file (replace your existing AccessCodeScreen.dart)
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';

class AccessCodeScreen extends StatefulWidget {
  final dynamic
  selectedDevice; // Can be BluetoothDevice or UsbDevice or ScanResult
  final ScanType scanType;
  final bool? isLiveEvent;

  const AccessCodeScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  late TextEditingController _accessCodeController;
  late ScrollController _scrollController;
  late FocusNode _accessFocusNode;
  final GlobalKey _textFieldKey = GlobalKey();

  bool _isConnecting = false;
  String _connectionStatus = "Not connected";

  // validation state
  bool _isAccessCodeValid = false;
  bool _showAccessCodeError = false;
  static const String _requiredAccessCode = "1974";

  @override
  void initState() {
    super.initState();

    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(_onAccessCodeChanged);

    _scrollController = ScrollController();
    _accessFocusNode = FocusNode();
    _accessFocusNode.addListener(_onFocusChange);

    // Check if already connected
    if (AppServices.isConnected) {
      _connectionStatus =
          "Connected to: ${AppServices.connectedDevice?.platformName ?? 'Device'}";
    } else {
      // Auto-connect to the selected device
      _connectToSelectedDevice();
    }
  }

  void _onFocusChange() {
    if (_accessFocusNode.hasFocus) {
      // ensure the text field is visible when keyboard opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_textFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        } else {
          // fallback: scroll to bottom
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onAccessCodeChanged() {
    final text = _accessCodeController.text.trim();
    final valid = text == _requiredAccessCode;
    setState(() {
      _isAccessCodeValid = valid;
      // Show error only when user typed something and it's invalid
      _showAccessCodeError = text.isNotEmpty && !valid;
    });
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
            const SizedBox(width: 8),
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
    // allow scaffold to resize when keyboard opens
    final themePrimary = Theme.of(context).primaryColor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 54,
                // add viewInsets.bottom so when keyboard opens there's extra space
                bottom: 120 + MediaQuery.of(context).viewInsets.bottom,
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
                      const SizedBox(width: 8),
                      Text(
                        'Event Log Retrieval ',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 52),
                  _buildConnectionStatus(),
                  const SizedBox(height: 16),
                  _buildAccesCodeContainer(themePrimary),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildAccesCodeContainer(Color themePrimary) {
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
                color: Color(0xFFEC1D24).withOpacity(0.08),
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
            const SizedBox(height: 41),
            Text(
              'Access Code Required',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 74),
            Text(
              'Enter your access code ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF696969),
              ),
            ),
            const SizedBox(height: 8),
            // TextField with dynamic border color based on validation state
            Container(
              key: _textFieldKey,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      _showAccessCodeError ? themePrimary : Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: TextField(
                  focusNode: _accessFocusNode,
                  textAlign: TextAlign.center,
                  controller: _accessCodeController,
                  maxLength: 4,
                  showCursor: true,
                  obscureText: true,
                  obscuringCharacter: "*",
                  keyboardType: TextInputType.number,
                  onTapOutside: (value) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: const InputDecoration(
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

            // Error message shown when code is invalid and user entered something
            if (_showAccessCodeError) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ïnvalid Access Code!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                  Text(
                    'Please Try Again',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isButtonDisabled =
        !_isAccessCodeValid || _isConnecting || !AppServices.isConnected;

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
                    const SizedBox(width: 6),
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
          const Spacer(),
          GestureDetector(
            onTap:
                isButtonDisabled
                    ? null
                    : () {
                      // Final guard: ensure code is valid before proceeding
                      if (!_isAccessCodeValid) {
                        setState(() {
                          _showAccessCodeError = true;
                        });
                        return;
                      }

                      // Ensure device connected (already checked in isButtonDisabled, but keep for safety)
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

                      // Clear and navigate
                      _accessCodeController.clear();
                      setState(() {
                        _isAccessCodeValid = false;
                        _showAccessCodeError = false;
                      });
                      if (widget.isLiveEvent == false) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => ProjectDashboardScreen(
                                  panelName: 'RHINO2008',
                                  panelVersionNo: '0.98',
                                ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LogRetrievalLoadingScreen(),
                          ),
                        );
                      }
                    },
            child: Container(
              decoration: BoxDecoration(
                color: isButtonDisabled ? Color(0xFFDADADA) : Color(0xFFEC1D24),
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
                    const SizedBox(width: 13),
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
    _accessFocusNode.removeListener(_onFocusChange);
    _accessFocusNode.dispose();
    _scrollController.dispose();
    AppServices.serialService.disconnect();
    super.dispose();
  }
}
