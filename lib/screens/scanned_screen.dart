import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/access_code_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScannedScreen extends StatefulWidget {
  final List<dynamic>
  discoveredDevices; // Can hold both UsbDevice and ScanResult
  final ScanType scanType;

  const ScannedScreen({
    super.key,
    this.discoveredDevices = const [],
    required this.scanType,
  });

  @override
  State<ScannedScreen> createState() => _ScannedScreenState();
}

class _ScannedScreenState extends State<ScannedScreen> {
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
        child: SingleChildScrollView(
          child: Column(
            children: [_buildHeader(context), _buildDevicesIdentified()],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffEC1D24).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset('assets/svgs/background_1.svg'),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ScanningScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFBDEE1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          'assets/svgs/logo.svg',
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            Color(0xFFEC1D24),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Tap to Scan Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesIdentified() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devices Identified',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  Text(
                    '${widget.scanType == ScanType.usb ? 'USB' : 'Bluetooth'} Scan Results',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918F8F),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      widget.discoveredDevices.isEmpty
                          ? Colors.orange
                          : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.discoveredDevices.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          widget.discoveredDevices.isEmpty
              ? _buildNoDevicesFound()
              : _buildDevicesList(),
        ],
      ),
    );
  }

  Widget _buildNoDevicesFound() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            widget.scanType == ScanType.usb
                ? Icons.usb_off
                : Icons.bluetooth_disabled,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No ${widget.scanType == ScanType.usb ? 'USB' : 'Bluetooth'} Devices Found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.scanType == ScanType.usb
                ? 'Make sure your solar devices are connected via USB and powered on.'
                : 'Make sure Bluetooth is enabled and solar devices are in pairing mode.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.discoveredDevices.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final device = widget.discoveredDevices[index];
        return GestureDetector(
          onTap: () {
            // Pass the selected device to AccessCodeScreen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => AccessCodeScreen(
                      selectedDevice: device,
                      scanType: widget.scanType,
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Color(0xFFB9B9B9).withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (widget.scanType == ScanType.usb
                              ? Color(0xFFEC1D24)
                              : Colors.blue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.scanType == ScanType.usb
                          ? Icons.usb
                          : Icons.bluetooth,
                      color:
                          widget.scanType == ScanType.usb
                              ? Color(0xFFEC1D24)
                              : Colors.blue,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDeviceName(device),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                        Text(
                          _getDeviceInfo(device),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF918F8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset('assets/svgs/arrow_right_colored_icon.svg'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDeviceName(dynamic device) {
    if (widget.scanType == ScanType.usb && device is UsbDevice) {
      return device.productName ?? 'USB Solar Device';
    } else if (widget.scanType == ScanType.bluetooth && device is ScanResult) {
      return device.device.platformName.isNotEmpty
          ? device.device.platformName
          : 'BLE Solar Device';
    }
    return 'Unknown Device';
  }

  String _getDeviceInfo(dynamic device) {
    if (widget.scanType == ScanType.usb && device is UsbDevice) {
      return 'VID: ${device.vid?.toRadixString(16) ?? 'Unknown'} | PID: ${device.pid?.toRadixString(16) ?? 'Unknown'}';
    } else if (widget.scanType == ScanType.bluetooth && device is ScanResult) {
      return 'MAC: ${device.device.remoteId} | RSSI: ${device.rssi} dBm';
    }
    return 'No information available';
  }
}
