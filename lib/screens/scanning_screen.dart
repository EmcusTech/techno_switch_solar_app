import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/scanned_screen.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

enum ScanType { usb, bluetooth }

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  Timer? _scanTimer;
  Timer? _autoStopTimer;
  Timer? _countdownTimer;
  List<dynamic> _discoveredDevices = []; // Can hold both UsbDevice and BluetoothDevice
  bool _isScanning = false;
  bool _showSelection = true;
  ScanType? _selectedScanType;
  static const int _scanDurationSeconds = 15; // Auto-stop after 15 seconds
  int _remainingSeconds = _scanDurationSeconds;

  @override
  void dispose() {
    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startScanning(ScanType scanType) async {
    setState(() {
      _selectedScanType = scanType;
      _showSelection = false;
      _isScanning = true;
      _remainingSeconds = _scanDurationSeconds;
    });

    // Request permissions
    await _requestPermissions(scanType);
    
    // Start periodic scanning
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isScanning) {
        await _scanForDevices();
      }
    });

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });

    // Auto-stop scanning after specified duration
    _autoStopTimer = Timer(const Duration(seconds: _scanDurationSeconds), () {
      _stopScanning();
    });
  }

  Future<void> _requestPermissions(ScanType scanType) async {
    if (scanType == ScanType.usb) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    } else if (scanType == ScanType.bluetooth) {
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothAdvertise.request();
      await Permission.location.request();
    }
  }

  Future<void> _scanForDevices() async {
    try {
      if (_selectedScanType == ScanType.usb) {
        List<UsbDevice> devices = await UsbSerial.listDevices();
        if (mounted) {
          setState(() {
            _discoveredDevices = devices.cast<dynamic>();
          });
        }
      } else if (_selectedScanType == ScanType.bluetooth) {
        // Check if Bluetooth is available and on
        if (await FlutterBluePlus.isSupported) {
          await FlutterBluePlus.turnOn();
          
          // Start scanning for BLE devices
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
          
          // Listen to scan results
          FlutterBluePlus.scanResults.listen((results) {
            if (mounted) {
              setState(() {
                _discoveredDevices = results.cast<dynamic>();
              });
            }
          });
        }
      }
      
      // If devices are found for the first time, give feedback
      if (_discoveredDevices.isNotEmpty) {
        print('Devices discovered: ${_discoveredDevices.length}');
      }
    } catch (e) {
      print('Error scanning for devices: $e');
      // Continue scanning even if there's an error
    }
  }

  void _stopScanning() {
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
    
    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();

    // Stop BLE scanning if active
    if (_selectedScanType == ScanType.bluetooth) {
      FlutterBluePlus.stopScan();
    }

    // Navigate to scanned screen with discovered devices
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedScreen(
            discoveredDevices: _discoveredDevices,
            scanType: _selectedScanType!,
          ),
        ),
      );
    }
  }

  void _goBackToSelection() {
    setState(() {
      _showSelection = true;
      _isScanning = false;
      _selectedScanType = null;
      _discoveredDevices.clear();
    });
    
    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Stop BLE scanning if active
    FlutterBluePlus.stopScan();
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
        child: _showSelection ? _buildSelectionView() : _buildScanningView(),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset('assets/svgs/background_1.svg'),
            ),
          ],
        ),
        
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: Center(
                child: SvgPicture.asset('assets/svgs/logo.svg'),
              ),
            ),
            
            SizedBox(height: 40),
            
            Text(
              'Choose Scan Type',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
            ),
            
            SizedBox(height: 12),
            
            Text(
              'Select the type of devices you want to scan for',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF3A3A3A),
              ),
            ),
            
            SizedBox(height: 40),
            
            // USB Scan Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => _startScanning(ScanType.usb),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE5E5E5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFFEC1D24).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.usb,
                            color: Color(0xFFEC1D24),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USB/Serial Devices',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3D3D3D),
                                ),
                              ),
                              Text(
                                'Scan for connected USB solar devices',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF918F8F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF918F8F),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Bluetooth Scan Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => _startScanning(ScanType.bluetooth),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE5E5E5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bluetooth (BLE) Devices',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3D3D3D),
                                ),
                              ),
                              Text(
                                'Scan for nearby Bluetooth solar devices',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF918F8F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF918F8F),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanningView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset('assets/svgs/background_1.svg'),
            ),
          ],
        ),
        
        Align(alignment: Alignment.center, child: ScanningAnimation()),
        
        // Back button
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: _goBackToSelection,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF3D3D3D),
                size: 18,
              ),
            ),
          ),
        ),
        
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Scan type indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: (_selectedScanType == ScanType.usb ? Color(0xFFEC1D24) : Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (_selectedScanType == ScanType.usb ? Color(0xFFEC1D24) : Colors.blue).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedScanType == ScanType.usb ? Icons.usb : Icons.bluetooth,
                      color: _selectedScanType == ScanType.usb ? Color(0xFFEC1D24) : Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Scanning ${_selectedScanType == ScanType.usb ? 'USB' : 'Bluetooth'} devices',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedScanType == ScanType.usb ? Color(0xFFEC1D24) : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Show discovered devices count
            if (_discoveredDevices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_discoveredDevices.length} device(s) found',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: _stopScanning,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFEC1D24),
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Stop Scanning',
                        style: GoogleFonts.inter(
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
            SizedBox(height: 20),
            
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 30),
            //   child: Text(
            //     _isScanning 
            //         ? 'Scanning for ${_selectedScanType == ScanType.usb ? 'USB' : 'Bluetooth'} devices... Auto-stop in ${_remainingSeconds}s'
            //         : 'Scan completed',
            //     textAlign: TextAlign.center,
            //     style: GoogleFonts.inter(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w400,
            //       color: Color(0xFF3A3A3A),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
