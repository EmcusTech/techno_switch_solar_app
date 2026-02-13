import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart'
    show UpdatesController;
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/screens/log_history_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart'
    hide ble;
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/settings_screen.dart';
import 'package:techno_switch_solar_app/screens/test_mode_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/setting_bottom_sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/firmware_upgrade_bottom_sheet.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final String panelVersionNo;
  final String panelName;
  final int? siteId;
  final String? siteName;
  final DiscoveredDevice selectedDevice;
  const ProjectDashboardScreen({
    super.key,
    required this.panelVersionNo,
    required this.panelName,
    this.siteId,
    this.siteName,
    required this.selectedDevice,
  });

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  int _selectedIndex = 0;

  /// Holds the device with real manufacturerData after reconnect; survives tab switches.
  DiscoveredDevice? _currentDevice;

  void _onDeviceReconnected(DiscoveredDevice device) {
    setState(() {
      _currentDevice = device;
    });
  }

  List<Widget> get _screens => [
    _ProjectDashboardContent(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
      selectedDevice: _currentDevice ?? widget.selectedDevice,
      onDeviceReconnected: _onDeviceReconnected,
    ),
    SettingsScreen(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
    ),
    const TestModeScreen(),
    LogHistoryScreen(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
      siteId: widget.siteId,
    ),
  ];

  void _onItemTapped(int index) {
    if (index == 1 || index == 2) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    print(
      'DEBUG: ProjectDashboardScreen initState: ${widget.selectedDevice.manufacturerData}',
    );
  }

  @override
  Widget build(BuildContext context) {
    const disabledIndexes = [1, 2];

    Color itemColor(int index) {
      if (disabledIndexes.contains(index)) {
        return Colors.grey;
      }
      return _selectedIndex == index ? Colors.white : Colors.black;
    }

    Widget navItem({
      required int index,
      required String label,
      required String asset,
    }) {
      final color = itemColor(index);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset,
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight:
                  _selectedIndex == index ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xffEC1D24),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) {
              if (disabledIndexes.contains(index)) return; // 🚫 disabled
              _onItemTapped(index);
            },
            items: [
              BottomNavigationBarItem(
                icon: navItem(
                  index: 0,
                  label: 'Dashboard',
                  asset: 'assets/svgs/dashboard_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 1,
                  label: 'Settings',
                  asset: 'assets/svgs/setting_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 2,
                  label: 'Test Mode',
                  asset: 'assets/svgs/test_mode_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 3,
                  label: 'Log History',
                  asset: 'assets/svgs/log_history_icon.svg',
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create a separate widget for the EventLog content
class _ProjectDashboardContent extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  final DiscoveredDevice selectedDevice;
  final void Function(DiscoveredDevice)? onDeviceReconnected;

  const _ProjectDashboardContent({
    required this.panelName,
    required this.panelVersionNo,
    required this.selectedDevice,
    this.onDeviceReconnected,
  });

  @override
  State<_ProjectDashboardContent> createState() =>
      _ProjectDashboardContentState();
}

class _ProjectDashboardContentState extends State<_ProjectDashboardContent> {
  // Prevent multiple navigations while dialog rebuilds
  bool _navigatingToDeviceConnecting = false;

  // Connection state
  bool _isConnecting = false;
  StreamSubscription? _scanSubscription;
  final BluetoothService _bluetoothService = BluetoothService();
  final bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();
  late DiscoveredDevice _selectedDevice;

  Future<bool> _confirmAndDisconnect() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Disconnect device?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Going back will disconnect the device. Are you sure?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Disconnect',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDisconnect == true) {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothService.stopScanning();
    super.dispose();
  }

  void _showConnectingDialog({
    required DiscoveredDevice device,
    required BuildContext context,
  }) {
    final bleController = Get.find<BleLogController>();
    final connectionNotifier = bleController.bleManager.isConnectedNotifier;
    final maxBleConnectionRetriesReachedNotifier =
        bleController.bleManager.maxBleConnectionRetriesReached;
    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      maxBleConnectionRetriesReachedNotifier,
    ]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: mergedListenable,
          builder: (context, _) {
            final isConnected = connectionNotifier.value;
            final maxBleConnectionRetriesReached =
                maxBleConnectionRetriesReachedNotifier.value;

            // When connected, wait 2 seconds then close dialog
            if (isConnected && !hasNavigated) {
              hasNavigated = true;
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted && hasNavigated) {
                  Navigator.of(dialogContext).pop();
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            isConnected
                                ? Colors.green.withValues(alpha: 0.1)
                                : Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            isConnected
                                ? Icon(
                                  Icons.check_circle,
                                  size: 32,
                                  color: Colors.green,
                                )
                                : Lottie.asset(
                                  'assets/jsons/ble_connecting.json',
                                  animate: !maxBleConnectionRetriesReached,
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Title
                    Text(
                      isConnected
                          ? 'Device Connected!'
                          : maxBleConnectionRetriesReached
                          ? 'Max Connection Retries Reached!'
                          : 'Connecting...',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Subtitle
                    Text(
                      isConnected
                          ? 'Preparing...'
                          : maxBleConnectionRetriesReached
                          ? 'Please try connecting again'
                          : 'Please wait while we connect to ${device.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF918F8F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    if (maxBleConnectionRetriesReached)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC1D24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.5),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'OK',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _connectToDeviceByName() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    bool dialogShown = false;

    try {
      final deviceName = widget.selectedDevice.name;
      print('deviceName: $deviceName');
      print('hey hey TECHNOSWITCH_${widget.panelName.split('_').last}');
      if (deviceName.isEmpty) {
        throw Exception('Device name is empty');
      }

      // Show connecting dialog
      _showConnectingDialog(device: widget.selectedDevice, context: context);
      dialogShown = true;

      // Request permissions and ensure Bluetooth is on
      await _bluetoothService.requestPermissions();
      final poweredOn = await _bluetoothService.ensurePoweredOn();
      if (!poweredOn) {
        throw Exception('Bluetooth is not enabled');
      }

      // Start scanning
      await _bluetoothService.startScanning();

      // Set up scan listener to find device by name
      final Completer<DiscoveredDevice?> deviceFoundCompleter =
          Completer<DiscoveredDevice?>();

      _scanSubscription = _bluetoothService.scanResultsStream.listen((results) {
        for (var result in results) {
          // Match by device name
          if (result.name ==
              'TECHNOSWITCH_${widget.panelName.split('_').last}') {
            if (!deviceFoundCompleter.isCompleted) {
              deviceFoundCompleter.complete(result);
            }
            break;
          }
        }
      });

      // Wait for device to be found (timeout after 15 seconds)
      final foundDeviceFuture = deviceFoundCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      final device = await foundDeviceFuture;
      await _scanSubscription?.cancel();
      await _bluetoothService.stopScanning();

      if (device == null) {
        throw Exception('Device "$deviceName" not found');
      }

      // Connect to the found device
      final bleController = Get.find<BleLogController>();
      await bleController.connectToDevice(device: device);

      setState(() {
        _selectedDevice = device;
      });

      widget.onDeviceReconnected?.call(device);

      // The dialog will automatically close when connection is established
      // via the ListenableBuilder listening to connectionNotifier

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        // Close dialog if it was shown
        if (dialogShown) {
          try {
            Navigator.of(context).pop();
          } catch (_) {
            // Dialog might have already been closed
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _scanSubscription?.cancel();
      await _bluetoothService.stopScanning();
    }
  }

  @override
  initState() {
    super.initState();
    _selectedDevice = widget.selectedDevice;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (bleController.isConnected) {
          final shouldPop = await _confirmAndDisconnect();
          return shouldPop;
        } else {
          return true;
        }
      },
      child: Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (bleController.isConnected) {
                              final shouldPop = await _confirmAndDisconnect();
                              if (shouldPop && mounted) {
                                Navigator.of(context).pop();
                              }
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
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
                        SizedBox(width: 12),
                        Text(
                          'Project Dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildDashboardContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showBootloaderModeDialog({required BuildContext context}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Device is in bootloader mode',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on Update to update the firmware.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          navigator.pop(); // close dialog
                          if (!Get.isRegistered<UpdatesController>()) {
                            Get.put(UpdatesController());
                          }
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            isDismissible: false,
                            enableDrag: false,
                            builder:
                                (context) => FirmwareUpgradeBottomSheet(
                                  connectedDevice: widget.selectedDevice,
                                ),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Update',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showBluetootohOffDialog({required BuildContext context}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Device not connected',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'BLE device is not connected. Tap on Connect to connect again.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          navigator.pop(); // close dialog
                          await _connectToDeviceByName();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Connect',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showApplySuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9), // Light green background
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/check_circle_icon.svg',
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  "$message Applied",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'The $message has been successfully applied to the device.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Dismiss Button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                      ble.bleProcess.isExtOutApplyDone.value = false;
                      ble.bleProcess.isInputSetupApplyDone.value = false;
                      ble.bleProcess.isRelaySetupApplyDone.value = false;
                      ble.bleProcess.isZoneSetupApplyDone.value = false;
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFEC1D24),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPasswordPopup({
    required Function() onCall,
    bool? isExtOut = false,
    bool? isInputSetup = false,
    bool? isRelaySetup = false,
    bool? isZoneSetup = false,
  }) {
    // Reset navigation guard each time the dialog opens
    _navigatingToDeviceConnecting = false;

    // Reset previous access-key validation state
    final bleProcess = Get.find<BleLogController>().bleProcess;
    bleProcess.isAccessKeyValid.value = null;
    bleProcess.accessKey.value = "";

    Timer? accessKeyValidationTimer;
    void cancelAccessKeyTimer() {
      accessKeyValidationTimer?.cancel();
      accessKeyValidationTimer = null;
    }

    final TextEditingController _controller = TextEditingController();
    final FocusNode _focusNode = FocusNode();
    final ValueNotifier<String?> errorText = ValueNotifier(null);
    final accessKey = bleProcess.accessKey;
    final ValueNotifier<bool?> isAccessKeyValid = bleProcess.isAccessKeyValid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/lock_icon.svg',
                      height: 32,
                      width: 32,
                      colorFilter: ColorFilter.mode(
                        Color(0xFFEC1D24),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  'Enter 4-Digit Password',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'Please enter the password to continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Password Input Field + CTA
                ValueListenableBuilder<bool?>(
                  valueListenable: isAccessKeyValid,
                  builder: (_, isAccessKeyValidValue, __) {
                    if (isAccessKeyValidValue != null) {
                      cancelAccessKeyTimer();
                    }
                    // Auto-close on success and navigate, but defer to next frame
                    // to avoid build-phase setState/overlay errors.
                    if (isAccessKeyValidValue == true &&
                        !_navigatingToDeviceConnecting) {
                      _navigatingToDeviceConnecting = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!mounted) return;
                        // Briefly show success before navigating
                        await Future.delayed(const Duration(seconds: 1));
                        if (!mounted) return;
                        Navigator.of(dialogContext, rootNavigator: true).pop();
                        if (ble.bleProcess.isExtOutApplyDone.value) {
                          showApplySuccessDialog(
                            context,
                            'Extinguishing Output',
                          );
                        } else if (ble.bleProcess.isInputSetupApplyDone.value) {
                          showApplySuccessDialog(context, 'Inputs');
                        } else if (ble.bleProcess.isRelaySetupApplyDone.value &&
                            mounted) {
                          showApplySuccessDialog(context, 'Relays');
                        } else if (ble.bleProcess.isZoneSetupApplyDone.value &&
                            mounted) {
                          showApplySuccessDialog(context, 'Zones');
                        } else if (isInputSetup == true) {
                          showInputSetupBottomSheet(
                            context: context,
                            onCall: () {
                              showPasswordPopup(
                                onCall: () {
                                  ble.bleProcess.isInputSetupApplyActive.value =
                                      true;
                                  bleController.startInputSetupApply();
                                },
                              );
                            },
                          );
                        } else if (isExtOut == true) {
                          showExtOutBottomSheet(
                            context: context,
                            onCall: () {
                              showPasswordPopup(
                                onCall: () {
                                  ble
                                      .bleProcess
                                      .isExtOutCommandApplyActive
                                      .value = true;
                                  bleController.startExtOutApply();
                                },
                              );
                            },
                          );
                        } else if (isRelaySetup == true) {
                          showRelaySetupBottomSheet(
                            context: context,
                            onCall: () {
                              showPasswordPopup(
                                onCall: () {
                                  ble
                                      .bleProcess
                                      .isRelaySetupCommandApplyActive
                                      .value = true;
                                  bleController.startRelaySetupApply();
                                },
                              );
                            },
                          );
                        } else if (isZoneSetup == true) {
                          showZoneSetupBottomSheet(
                            context: context,
                            onCall: () {
                              showPasswordPopup(
                                onCall: () {
                                  ble
                                      .bleProcess
                                      .isZoneSetupCommandApplyActive
                                      .value = true;
                                  bleController.startZoneSetupApply();
                                },
                              );
                            },
                          );
                        } else {
                          Navigator.of(dialogContext).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => LogRetrievalLoadingScreen(
                                    scanType: ScanType.bluetooth,
                                    selectedDevice: widget.selectedDevice,
                                    connectedDevice: widget.selectedDevice,
                                  ),
                            ),
                          );
                        }
                      });
                    }

                    return Column(
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                            color: Color(0xFF3D3D3D),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (val) {
                            accessKey.value = val;
                            if (val.length == 4) {
                              errorText.value = null;
                              // reset validation state for new attempt
                              // cancelAccessKeyTimer();
                              // accessKeyValidationTimer = Timer(
                              //   const Duration(seconds: 10),
                              //   () {
                              //     if (!mounted) return;
                              //     if (isAccessKeyValid.value == null) {
                              //       final navigator = Navigator.maybeOf(
                              //         dialogContext,
                              //         rootNavigator: true,
                              //       );
                              //       navigator?.maybePop();

                              //       WidgetsBinding.instance.addPostFrameCallback((
                              //         _,
                              //       ) {
                              //         if (!mounted) return;
                              //         Navigator.of(dialogContext).push(
                              //           MaterialPageRoute(
                              //             builder:
                              //                 (_) =>
                              //                     const LogRetrievalFailedScreen(),
                              //           ),
                              //         );
                              //       });
                              //     }
                              //   },
                              // );
                              bleProcess.isAccessKeyValid.value = null;
                              // Dismiss keyboard and start validation
                              FocusScope.of(dialogContext).unfocus();
                              // Provide immediate feedback while validating
                              bleProcess.processDesc.value =
                                  "Validating access key...";
                              onCall();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '••••',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8,
                              color: Color(0xFFD0D0D0),
                            ),
                            errorText:
                                isAccessKeyValidValue == false
                                    ? "Invalid access key. Try again."
                                    : null,
                            errorStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFEC1D24),
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: Color(0xFFF8F8F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isAccessKeyValidValue == false
                                        ? Color(0xFFEC1D24)
                                        : Color(0xFFD0D0D0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isAccessKeyValidValue == false
                                        ? Color(0xFFEC1D24)
                                        : Color(0xFFD0D0D0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Status text during validation/success
                        Builder(
                          builder: (_) {
                            String? status;
                            if (_controller.text.length == 4 &&
                                isAccessKeyValidValue == null) {
                              status = "Validating access key...";
                            } else if (isAccessKeyValidValue == true) {
                              status = "Validation success";
                            }
                            // If invalid, re-focus the field to show keyboard
                            if (isAccessKeyValidValue == false) {
                              // Clear previous entry on failure
                              if (_controller.text.isNotEmpty) {
                                _controller.clear();
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_focusNode.canRequestFocus) {
                                  _focusNode.requestFocus();
                                }
                              });
                            }
                            return status == null
                                ? const SizedBox.shrink()
                                : Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D3D3D),
                                  ),
                                );
                          },
                        ),

                        SizedBox(height: 16),

                        // Cancel Button only when not validating or already successful
                        if (!(_controller.text.length == 4 &&
                                isAccessKeyValidValue == null) &&
                            isAccessKeyValidValue != true)
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                cancelAccessKeyTimer();
                                Navigator.of(dialogContext).pop();
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Color(0xFFEC1D24),
                                  borderRadius: BorderRadius.circular(24),
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
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildDashboard()),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Panel Information Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                height: 62,
                width: 62,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.panelName.split('_').first,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.panelName.split('_').last,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF979797),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    ValueListenableBuilder(
                      valueListenable: ble.isConnectedNotifier,
                      builder: (context, isConnected, child) {
                        if (isConnected) {
                          return RichText(
                            text: TextSpan(
                              children: [
                                // TextSpan(
                                //   text: 'Status : ',
                                //   style: GoogleFonts.inter(
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.w500,
                                //     color: Color(0xFF979797),
                                //   ),
                                // ),
                                TextSpan(
                                  text: 'Connected',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF00A706),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      // TextSpan(
                                      //   text: 'Status : ',
                                      //   style: GoogleFonts.inter(
                                      //     fontSize: 14,
                                      //     fontWeight: FontWeight.w500,
                                      //     color: Color(0xFF979797),
                                      //   ),
                                      // ),
                                      TextSpan(
                                        text: 'Disconnected',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFEC1D24),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              _isConnecting
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFEC1D24),
                                      ),
                                    ),
                                  )
                                  : GestureDetector(
                                    onTap: _connectToDeviceByName,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEC1D24),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Connect',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Spacer(),
              // Transform.rotate(
              //   angle: 180 * 3.14159 / 360,
              //   child: Icon(
              //     Icons.arrow_forward_ios,
              //     size: 18,
              //     color: Color(0xFF696969),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 10),
          _buildPeripheralOverview(),
          SizedBox(height: 42),
          _buildPanelActions(),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPeripheralOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peripheral Overview',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            // color: Colors.white,
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          height: 223,
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: 'Relays',
                iconPath: 'assets/svgs/peripheral_relay_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty && _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      ble.bleProcess.isRelaySetupFetchCommandActive.value =
                          true;
                      bleController.startRelaySetupFetch();
                    },
                    isRelaySetup: true,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Inputs',
                iconPath: 'assets/svgs/peripheral_input_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty && _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      ble.bleProcess.isInputSetupFetchCommandActive.value =
                          true;
                      bleController.startInputSetupFetch();
                    },
                    isInputSetup: true,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Zones',
                iconPath: 'assets/svgs/peripheral_zones_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty && _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      ble.bleProcess.isZoneSetupFetchCommandActive.value = true;
                      bleController.startZoneSetupFetch();
                    },
                    isZoneSetup: true,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Sounders',
                iconPath: 'assets/svgs/peripheral_sounder_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Prog/Hold',
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Aux',
                iconPath: 'assets/svgs/peripheral_aux_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'L-Bus',
                iconPath: 'assets/svgs/peripheral_l_bus_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Ext Out',
                iconPath: 'assets/svgs/peripheral_ext_out_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty && _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      ble.bleProcess.isExtOutCommandFetchActive.value = true;
                      bleController.startExtOutFetch();
                    },
                    isExtOut: true,
                  );
                  // showExtOutBottomSheet(
                  //   context: context,
                  //   onCall: () {
                  //     showPasswordPopup(
                  //       onCall: () {
                  //         bleController.startLogRetrieval();
                  //       },
                  //     );
                  //   },
                  // );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showExtOutBottomSheet({
    required BuildContext context,
    required Function() onCall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => ExtOutBottomSheet(onCall: onCall),
    );
  }

  void showInputSetupBottomSheet({
    required BuildContext context,
    required Function() onCall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => InputModeBottomSheet(onCall: onCall),
    );
  }

  void showRelaySetupBottomSheet({
    required BuildContext context,
    required Function() onCall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => RelayModeBottomSheet(onCall: onCall),
    );
  }

  void showZoneSetupBottomSheet({
    required BuildContext context,
    required Function() onCall,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => ZoneBottomSheet(onCall: onCall),
    );
  }

  Widget _peripheralTile({
    required String peripheralName,
    required String iconPath,
    VoidCallback? onTap,
    bool? isDisabled = false,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isDisabled == true) return;

        if (!bleController.isConnected) {
          await showBluetootohOffDialog(context: context);
        } else {
          onTap?.call();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF4F4F4),
                border: Border.all(color: Color(0xFFD7D7D7)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(
                    isDisabled == true
                        ? Color(0xFF666666).withValues(alpha: 0.2)
                        : Color(0xFFEC1D24),
                    BlendMode.srcIn,
                  ),
                  // height: 24,
                  // width: 24,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            peripheralName,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF696969),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel Actions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            // color: Colors.white,
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: 'Event Log',
                iconPath: 'assets/svgs/panel_action_event_log_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty && _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      bleController.startLogRetrieval();
                    },
                  );
                  // Get.find<BleLogController>().startLogRetrieval();
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder:
                  //         (context) => DeviceConnectingScreen(
                  //           scanType: ScanType.bluetooth,
                  //           selectedDevice: widget.selectedDevice,
                  //         ),
                  //   ),
                  // );
                },
              ),
              _peripheralTile(
                peripheralName: 'FW Upgrade',
                iconPath: 'assets/svgs/firmware_icon.svg',
                onTap: () {
                  // Ensure UpdatesController is registered
                  if (!Get.isRegistered<UpdatesController>()) {
                    Get.put(UpdatesController());
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    isDismissible: false,
                    enableDrag: false,
                    builder:
                        (context) => FirmwareUpgradeBottomSheet(
                          connectedDevice: widget.selectedDevice,
                        ),
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Service Due',
                iconPath: 'assets/svgs/panel_action_service_due_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Factory Prog',
                iconPath: 'assets/svgs/panel_action_factory_prog_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Config Log',
                iconPath: 'assets/svgs/panel_action_config_log_icon.svg',
                isDisabled: true,
              ),
              _peripheralTile(
                peripheralName: 'Test Mode',
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
                isDisabled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
