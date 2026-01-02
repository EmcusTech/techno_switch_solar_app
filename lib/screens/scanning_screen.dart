// scanning_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/scanned_screen.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart';

enum ScanType { usb, bluetooth }

class ScanningScreen extends StatefulWidget {
  final bool? isLiveEvent;
  const ScanningScreen({super.key, this.isLiveEvent = false});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  Timer? _scanTimer;
  Timer? _autoStopTimer;
  Timer? _countdownTimer;
  List<dynamic> _discoveredDevices = [];
  bool _isScanning = false;
  bool _showSelection = true;
  ScanType? _selectedScanType;
  static const int _scanDurationSeconds = 30; // longer so logs are visible
  int _remainingSeconds = _scanDurationSeconds;

  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription? _bleResultsSub;

  late final AnimationController _sweepController;

  // Slot assignment (stable positions)
  final Map<String, int> _assignedSlot = {}; // deviceKey -> slotIndex
  final Map<int, String> _slotToDevice = {}; // slotIndex -> deviceKey
  final Map<String, DateTime> _lastSeen = {}; // deviceKey -> last seen

  final int maxSlots = 12;
  final int staleTimeoutSeconds = 20; // longer to avoid flapping

  // UI: track which keys were just assigned to pulse them
  final Map<String, bool> _justAssigned = {};

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startScanning(ScanType.bluetooth);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();
    _bleResultsSub?.cancel();
    _bluetoothService.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  Future<void> _startScanning(ScanType scanType) async {
    setState(() {
      _selectedScanType = scanType;
      _showSelection = false;
      _isScanning = true;
      _remainingSeconds = _scanDurationSeconds;
    });

    await _requestPermissions(scanType);

    if (scanType == ScanType.bluetooth) {
      try {
        await _bluetoothService.requestPermissions();
      } catch (_) {}

      final poweredOn = await _bluetooth_service_ensureSafe();
      if (poweredOn) {
        await _bleResultsSub?.cancel();
        _bleResultsSub = _bluetooth_service_scanListener();
        try {
          await _bluetoothService.startScanning();
        } catch (_) {}
      }
    }

    if (scanType == ScanType.usb) {
      _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (_isScanning) await _scanForDevices();
      });
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });

    // _autoStopTimer = Timer(const Duration(seconds: _scanDurationSeconds), () {
    //   _stopScanning();
    // });
  }

  // small wrapper to get stream subscription with proper casting
  StreamSubscription _bluetooth_service_scanListener() {
    return _bluetoothService.scanResultsStream.listen((results) {
      if (mounted) _handleNewScanResults(results.cast<dynamic>());
    });
  }

  Future<bool> _bluetooth_service_ensureSafe() async {
    try {
      return await _bluetoothService.ensurePoweredOn();
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestPermissions(ScanType scanType) async {
    if (scanType == ScanType.usb) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _scanForDevices() async {
    try {
      if (_selectedScanType == ScanType.usb) {
        final devices = await UsbSerial.listDevices();
        if (mounted) _handleNewScanResults(devices.cast<dynamic>());
      }
    } catch (e) {
      debugPrint('DBG_RADAR: USB scan error: $e');
    }
  }

  // --- KEY PART: robust device key extraction (unchanged) ---
  String? _computeStableKey(dynamic device) {
    try {
      if (device == null) return null;

      if (device is Map) {
        final map = device;
        final candidates = <String?>[
          map['address']?.toString(),
          map['id']?.toString(),
          map['deviceId']?.toString(),
          map['mac']?.toString(),
          map['uuid']?.toString(),
          map['peripheralId']?.toString(),
        ];
        for (var c in candidates) {
          if (c != null && c.isNotEmpty) return 'field:$c';
        }
        if (map.containsKey('advertisementData')) {
          final ad = map['advertisementData'];
          try {
            if (ad is Map && ad.containsKey('manufacturerData')) {
              final manu = ad['manufacturerData'];
              if (manu != null) {
                final hex = _bytesToHex(manu);
                if (hex.isNotEmpty) return 'manu:$hex';
              }
            }
          } catch (_) {}
        }
      }

      final dyn = device;
      try {
        final a = (dyn as dynamic).address;
        if (a != null && a.toString().isNotEmpty) return 'address:$a';
      } catch (_) {}
      try {
        final i = (dyn as dynamic).id;
        if (i != null && i.toString().isNotEmpty) return 'id:$i';
      } catch (_) {}
      try {
        final mac = (dyn as dynamic).macAddress;
        if (mac != null && mac.toString().isNotEmpty) return 'mac:$mac';
      } catch (_) {}
      try {
        final uuid = (dyn as dynamic).uuid;
        if (uuid != null && uuid.toString().isNotEmpty) return 'uuid:$uuid';
      } catch (_) {}

      try {
        final ad = (dyn as dynamic).advertisementData;
        if (ad != null) {
          final manu = (ad as dynamic).manufacturerData;
          if (manu != null) {
            final hex = _bytesToHex(manu);
            if (hex.isNotEmpty) return 'manu:$hex';
          }
          final su = (ad as dynamic).serviceUuids;
          if (su != null) {
            final s = su.toString();
            if (s.isNotEmpty) return 'svc:$s';
          }
        }
      } catch (_) {}

      try {
        final name = (dyn as dynamic).name;
        if (name != null && name.toString().isNotEmpty) {
          return 'name:${name.toString()}';
        }
      } catch (_) {}

      try {
        final full = device.toString();
        if (full.isNotEmpty) {
          final h = _simpleHash(full);
          return 'ts:$h';
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('DBG_RADAR: computeStableKey error: $e');
    }
    return null;
  }

  String _bytesToHex(dynamic b) {
    try {
      if (b == null) return '';
      if (b is List<int>) {
        return b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      }
      if (b is Uint8List) {
        return b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      }
      if (b is Map) {
        final vals = <int>[];
        for (var entry in b.entries) {
          final v = entry.value;
          if (v is int) vals.add(v);
        }
        return vals.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      }
      final s = b.toString();
      if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return s;
      return '';
    } catch (_) {
      return '';
    }
  }

  int _simpleHash(String s) {
    int h = 0;
    for (int i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }

  // ----- RE-ADDED HELPERS: _findFreeSlot and _hashToSlot -----
  int? _findFreeSlot() {
    for (int i = 0; i < maxSlots; i++) {
      if (!_slotToDevice.containsKey(i)) return i;
    }
    return null;
  }

  int _hashToSlot(String key) {
    final h = _simpleHash(key);
    return h % maxSlots;
  }
  // ----------------------------------------------------------

  // --- Handle scan results and assign slots (unchanged behavior) ---
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

          // mark as just assigned to pulse UI
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

    // Remove stale
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

  String? _deviceKeyByObject(dynamic device) {
    return _computeStableKey(device);
  }

  String _deviceLabel(dynamic device) {
    try {
      final dyn = device;
      try {
        final ad = (dyn as dynamic).advertisementData;
        if (ad != null) {
          final advName = (ad as dynamic).advName ?? (ad as dynamic).localName;
          if (advName != null && advName.toString().isNotEmpty) {
            return advName.toString();
          }
        }
      } catch (_) {}
      if (device is Map) {
        return (device['name'] ?? device['id'] ?? 'unknown').toString();
      }
      final name = (dyn as dynamic).name;
      final id = (dyn as dynamic).id;
      return (name ?? id ?? 'unknown').toString();
    } catch (_) {
      return device.toString();
    }
  }

  // Builds a small details widget to show under the image
  Widget _deviceDetailsWidget(String label, String meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _stopScanning() {
    if (mounted) setState(() => _isScanning = false);

    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();

    if (_selectedScanType == ScanType.bluetooth) {
      _bluetoothService.stopScanning();
    }

    Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ScannedScreen(
                discoveredDevices: _discoveredDevices,
                scanType: _selectedScanType!,
                isLiveEvent: widget.isLiveEvent,
              ),
        ),
      );
    }
  }

  void _goBackToSelection() {
    _bleResultsSub?.cancel();
    _bluetoothService.stopScanning();
    Navigator.pop(context);
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
            const Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset('assets/svgs/background_1.svg'),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: Center(child: SvgPicture.asset('assets/svgs/logo.svg')),
            ),
            const SizedBox(height: 40),
            Text(
              'Choose Scan Type',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select the type of devices you want to scan for',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3A3A3A),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => _startScanning(ScanType.usb),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.usb, color: Color(0xFFEC1D24)),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('USB/Serial Devices'),
                              Text('Scan for connected USB solar devices'),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () => _startScanning(ScanType.bluetooth),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth, color: Colors.blue),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bluetooth (BLE) Devices'),
                              Text('Scan for nearby Bluetooth solar devices'),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
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
    const double radarSize = 340; // slightly larger for more space
    final double center = radarSize / 2;
    final double fixedRadius = radarSize * 0.38;
    const double cardWidth = 120;
    const double cardHeight = 150;

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            const Spacer(),
            Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset('assets/svgs/background_1.svg'),
            ),
          ],
        ),
        // Center(
        //   child: SizedBox(
        //     width: radarSize,
        //     height: radarSize,
        //     child: Stack(
        //       children: [
        //         Positioned.fill(
        //           child: CustomPaint(
        //             painter: _RadarPainter(sweepAnimation: _sweepController),
        //           ),
        //         ),
        //         Positioned.fill(
        //           child: AnimatedBuilder(
        //             animation: _sweep_controller_proxy(),
        //             builder:
        //                 (c, _) => CustomPaint(
        //                   painter: _SweepPainter(
        //                     progress: _sweepController.value,
        //                   ),
        //                 ),
        //           ),
        //         ),
        //         ..._buildSlotWidgets(
        //           radarSize,
        //           center,
        //           fixedRadius,
        //           cardWidth,
        //           cardHeight,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        Align(alignment: Alignment.center, child: ScanningAnimation()),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
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
            // if (_discoveredDevices.isNotEmpty)
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 28),
            //   child: Container(
            //     width: double.infinity,
            //     padding: const EdgeInsets.all(16),
            //     margin: const EdgeInsets.only(bottom: 20),
            //     decoration: BoxDecoration(
            //       color: Colors.green.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(12),
            //       border: Border.all(color: Colors.green.withOpacity(0.3)),
            //     ),
            //     child: Text(
            //       '${_discoveredDevices.length} device(s) found',
            //       textAlign: TextAlign.center,
            //       style: GoogleFonts.inter(
            //         fontSize: 14,
            //         fontWeight: FontWeight.w600,
            //         color: Colors.green[700],
            //       ),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: _stopScanning,
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
            const SizedBox(height: 20),
            Text(
              'Please wait till scan identifies the devices....',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF3A3A3A),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        Center(
          child: SizedBox(
            width: radarSize,
            height: radarSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarPainter(sweepAnimation: _sweepController),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweep_controller_proxy(),
                    builder:
                        (c, _) => CustomPaint(
                          painter: _SweepPainter(
                            progress: _sweepController.value,
                          ),
                        ),
                  ),
                ),
                // ..._buildSlotWidgets(
                //   radarSize,
                //   center,
                //   fixedRadius,
                //   cardWidth,
                //   cardHeight,
                // ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.2,
          left: 20,
          width: radarSize,
          height: radarSize,
          child: Stack(
            children: [..._buildGridSlotWidgets(maxWidth: radarSize)],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGridSlotWidgets({required double maxWidth}) {
    const int columns = 3;
    const double spacing = 12;
    const double cardWidth = 120;
    const double cardHeight = 150;

    final widgets = <Widget>[];

    // Sort slots so order is stable
    final slots = _slotToDevice.keys.toList()..sort();

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final deviceKey = _slotToDevice[slot];
      if (deviceKey == null) continue;

      final device = _discoveredDevices.firstWhere(
        (d) => _deviceKeyByObject(d) == deviceKey,
        orElse: () => null,
      );
      if (device == null) continue;

      final row = i ~/ columns;
      final col = i % columns;

      final left = col * (cardWidth + spacing);
      final top = row * (cardHeight + spacing);

      final justAssigned = _justAssigned.containsKey(deviceKey);

      widgets.add(
        AnimatedPositioned(
          key: ValueKey(deviceKey),
          left: left,
          top: top,
          width: cardWidth,
          height: cardHeight,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: _AnimatedGridCard(
            child: _buildDeviceCard(device),
            highlight: justAssigned,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDeviceCard(dynamic device) {
    final label = _deviceLabel(device);

    return GestureDetector(
      onTap: () {
        if (_isScanning) _stopScanning();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => DeviceConnectingScreen(
                  selectedDevice: device,
                  scanType: _selectedScanType!,
                  isLiveEvent: widget.isLiveEvent,
                ),
          ),
        );
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: SvgPicture.asset('assets/svgs/panel_icon.svg'),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small proxy function so analyzer doesn't complain about using controller directly in AnimatedBuilder
  Animation<double> _sweep_controller_proxy() => _sweepController;

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
      if (deviceKey != null && _lastSeen.containsKey(deviceKey)) {
        final device = _discoveredDevices.firstWhere(
          (d) => _deviceKeyByObject(d) == deviceKey,
          orElse: () => null,
        );
        if (device != null) {
          final label = _deviceLabel(device);
          final justAssigned = _justAssigned.containsKey(deviceKey);

          // Card position: center the card at dx,dy (clamped)
          final left = (dx - cardWidth / 2).clamp(4.0, radarSize - cardWidth);
          final top = (dy - cardHeight / 2).clamp(4.0, radarSize - cardHeight);

          widgets.add(
            Positioned(
              key: ValueKey('card-$deviceKey'),
              left: left,
              top: top,
              width: cardWidth,
              height: cardHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: 1.0,
                child: AnimatedScale(
                  scale: justAssigned ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  child: GestureDetector(
                    onTap: () {
                      print("hey hey hey");
                      // Stop scanning before connecting
                      if (_isScanning) {
                        _stopScanning();
                      }

                      // Navigate to device connecting screen
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DeviceConnectingScreen(
                                  selectedDevice: device,
                                  scanType: _selectedScanType!,
                                  isLiveEvent: widget.isLiveEvent,
                                ),
                          ),
                        );
                      }
                    },
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
                            // image area (top)
                            Container(
                              height: cardHeight * 0.6,
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
                                    width: cardWidth * 0.5,
                                    height: cardWidth * 0.5,
                                  ),
                                ),
                              ),
                            ),

                            // details area (bottom)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _deviceDetailsWidget(
                                      label,
                                      _shortMeta(device),
                                    ),
                                  ],
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
      }
    }
    return widgets;
  }

  // Create a short meta string (e.g., id or address) for the card
  String _shortMeta(dynamic device) {
    try {
      final dyn = device;
      try {
        final ad = (dyn as dynamic).advertisementData;
        if (ad != null) {
          final tx = (ad as dynamic).txPowerLevel;
          final advName = (ad as dynamic).advName ?? (ad as dynamic).localName;
          final r = (dyn as dynamic).rssi;
          final partRssi = r != null ? 'RSSI ${r.toString()}' : '';
          if (advName != null) {
            return advName.toString();
          }
          if (tx != null) return 'Tx $tx ${partRssi}';
        }
      } catch (_) {}
      if (device is Map) {
        return (device['id'] ?? device['address'] ?? '').toString();
      }
      final id = (dyn as dynamic).id ?? (dyn as dynamic).address;
      return id?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  double _angleForSlot(int slotIndex) {
    return (slotIndex * (2 * pi / maxSlots));
  }

  // helper to show a short represention of device for logs (kept for debug if needed)
  String _shortRepr(dynamic d) {
    try {
      if (d == null) return 'null';
      if (d is Map) {
        final n = d['name'] ?? d['id'] ?? d['address'];
        return 'Map(${n ?? 'no-name'})';
      } else {
        final dyn = d;
        final name =
            (dyn as dynamic).name ??
            (dyn as dynamic).id ??
            (dyn as dynamic).address;
        return '${d.runtimeType}(${name ?? d.toString().split('(').first})';
      }
    } catch (e) {
      return d.toString();
    }
  }
}

// Painters (unchanged)
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

class _AnimatedGridCard extends StatefulWidget {
  final Widget child;
  final bool highlight;

  const _AnimatedGridCard({required this.child, required this.highlight});

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [widget.child, if (widget.highlight) const _PulseGlow()],
        ),
      ),
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow();

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.25 * (1 - _controller.value),
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
