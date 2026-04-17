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
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/access_code_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/diagnostic_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/module_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/radio_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/setting_bottom_sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/utils/peripheral_cache_to_ble.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/config_log_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/walk_test_zone_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/firmware_upgrade_bottom_sheet.dart';
import 'package:techno_switch_solar_app/widgets/panel_access_code_dialog.dart';

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
              if (disabledIndexes.contains(index)) return;
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

  // Refresh triggers for peripheral bottom sheets (increment when download completes)
  final ValueNotifier<int> _relayRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _inputRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _zoneRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _extOutRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _sounderRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _serviceDueRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _accessCodeRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _panelInfoRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> _generalModuleRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<ConfigCompareResult?> _configLogCompareResult =
      ValueNotifier(null);
  final ValueNotifier<bool> _configLogWorking = ValueNotifier(false);

  // Connection state
  bool _isConnecting = false;
  StreamSubscription? _scanSubscription;
  final BluetoothService _bluetoothService = BluetoothService();
  final bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();
  late DiscoveredDevice _selectedDevice;

  /// Tracks prior connection so we only react to real disconnects (not initial "never connected").
  bool _hadBleConnection = false;

  /// When the user explicitly disconnects (e.g. back + confirm), skip the unexpected-loss dialog.
  bool _suppressUnexpectedBleDisconnectUi = false;

  void _closeModalOverlaysAboveDashboard() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    Navigator.of(context).popUntil((r) => r == route);
  }

  void _showUnexpectedBleDisconnectDialog() {
    if (!mounted) return;
    showDialog<void>(
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
                      Icons.bluetooth_disabled,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bluetooth disconnected',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The connection to the device was lost. Any open panels were closed. Use Connect when you are ready to reconnect.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC1D24),
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

  void _onBleConnectivityChanged() {
    if (!mounted) return;
    final connected = _bleManager.isConnectedNotifier.value;
    final lostConnection = _hadBleConnection && !connected;
    if (lostConnection) {
      _closeModalOverlaysAboveDashboard();
      if (_suppressUnexpectedBleDisconnectUi) {
        _suppressUnexpectedBleDisconnectUi = false;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showUnexpectedBleDisconnectDialog();
        });
      }
    }
    _hadBleConnection = connected;
  }

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
        _suppressUnexpectedBleDisconnectUi = true;
        await _bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _bleManager.isConnectedNotifier.removeListener(_onBleConnectivityChanged);
    _scanSubscription?.cancel();
    _bluetoothService.stopScanning();
    _configLogCompareResult.dispose();
    _configLogWorking.dispose();
    super.dispose();
  }

  void _showConnectingDialog({
    required DiscoveredDevice device,
    required BuildContext context,
  }) {
    final bleController = Get.find<BleLogController>();
    final connectionNotifier = bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        bleController.bleManager.handshakeCompleteNotifier;
    final maxBleConnectionRetriesReachedNotifier =
        bleController.bleManager.maxBleConnectionRetriesReached;
    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
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
            final handshakeComplete = handshakeCompleteNotifier.value;
            final maxBleConnectionRetriesReached =
                maxBleConnectionRetriesReachedNotifier.value;

            // Close dialog when handshake is complete (encryption + auth done)
            if (handshakeComplete && !hasNavigated) {
              hasNavigated = true;
              Future.delayed(const Duration(milliseconds: 500), () {
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
                            handshakeComplete
                                ? Colors.green.withValues(alpha: 0.1)
                                : Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete
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
                      handshakeComplete
                          ? 'Device Connected!'
                          : maxBleConnectionRetriesReached
                          ? 'Max Connection Retries Reached!'
                          : isConnected
                          ? 'Establishing secure connection...'
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
                      handshakeComplete
                          ? 'Ready'
                          : maxBleConnectionRetriesReached
                          ? 'Please try connecting again'
                          : isConnected
                          ? 'Encrypting and authenticating...'
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
          // Match by full BLE name
          if (result.name == widget.panelName) {
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

      if (mounted) {
        setState(() {
          _selectedDevice = device;
          _isConnecting = false;
        });
      }

      widget.onDeviceReconnected?.call(device);

      // The connecting dialog closes when handshake completes (~500ms delay).
      // Match the home/scanned flow: require access-code validation after reconnect
      // (e.g. idle disconnect) so session state and tiles behave like a fresh entry.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      bleController.bleProcess.clearSessionAccessCode();
      final ok = await showPanelAccessCodeGatewayDialog(
        context: context,
        onStartValidation:
            () => bleController.startSessionAccessCodeValidation(),
      );

      if (!ok || !context.mounted) {
        bleController.bleManager.disconnectConnectedDevice();
        return;
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
    _hadBleConnection = _bleManager.isConnectedNotifier.value;
    _bleManager.isConnectedNotifier.addListener(_onBleConnectivityChanged);
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

  void showApplySuccessDialog(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final String resolvedSubtitle =
            subtitle ??
            'The $message has been successfully applied to the device.';

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            ble.bleProcess.isExtOutApplyDone.value = false;
            ble.bleProcess.isInputSetupApplyDone.value = false;
            ble.bleProcess.isRelaySetupApplyDone.value = false;
            ble.bleProcess.isZoneSetupApplyDone.value = false;
            ble.bleProcess.isLBusSetupApplyDone.value = false;
            ble.bleProcess.isRadioSetupApplyDone.value = false;
            ble.bleProcess.isLBusSetupApplyDone.value = false;
            ble.bleProcess.isSounderSetupApplyDone.value = false;
            ble.bleProcess.isServiceDueApplyDone.value = false;
            ble.bleProcess.isAccessCodeSetupApplyDone.value = false;
            ble.bleProcess.isPanelInfoSetupApplyDone.value = false;
            ble.bleProcess.isGeneralModuleSetupApplyDone.value = false;
          }
        });
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
                  resolvedSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),

                // SizedBox(height: 24),

                // // Dismiss Button
                // SizedBox(
                //   width: double.infinity,
                //   child: GestureDetector(
                //     onTap: () {
                //       Navigator.of(dialogContext, rootNavigator: true).pop();
                //       ble.bleProcess.isExtOutApplyDone.value = false;
                //       ble.bleProcess.isInputSetupApplyDone.value = false;
                //       ble.bleProcess.isRelaySetupApplyDone.value = false;
                //       ble.bleProcess.isZoneSetupApplyDone.value = false;
                //       ble.bleProcess.isLBusSetupApplyDone.value = false;
                //       ble.bleProcess.isRadioSetupApplyDone.value = false;
                //       ble.bleProcess.isLBusSetupApplyDone.value = false;
                //       ble.bleProcess.isSounderSetupApplyDone.value = false;
                //       ble.bleProcess.isServiceDueApplyDone.value = false;
                //       ble.bleProcess.isAccessCodeSetupApplyDone.value = false;
                //       ble.bleProcess.isPanelInfoSetupApplyDone.value = false;
                //       ble.bleProcess.isGeneralModuleSetupApplyDone.value =
                //           false;
                //     },
                //     child: Container(
                //       height: 48,
                //       decoration: BoxDecoration(
                //         color: Color(0xFFEC1D24),
                //         borderRadius: BorderRadius.circular(24),
                //       ),
                //       child: Center(
                //         child: Text(
                //           'OK',
                //           style: GoogleFonts.inter(
                //             fontSize: 16,
                //             fontWeight: FontWeight.w600,
                //             color: Colors.white,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDownloadSuccessDialog(BuildContext context, String message) {
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
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
                Text(
                  message == "Diagnostics"
                      ? "Live Diagnostics Active"
                      : "$message Downloaded",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Visibility(
                  visible: !ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    message == "Diagnostics"
                        ? 'Live data is being streamed from the device in real time.'
                        : 'The $message has been successfully downloaded from the device.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible: ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    'There was an error downloading',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible: ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    'L-Bus ${ble.bleProcess.lbusFetchErrors.value.join(", ")} - Comms Fault',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFEC1D24),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // SizedBox(height: 24),
                // Visibility(
                //   visible: message != "Diagnostics",
                //   child: SizedBox(
                //     width: double.infinity,
                //     child: GestureDetector(
                //       onTap: () {
                //         Navigator.of(dialogContext, rootNavigator: true).pop();
                //       },
                //       child: Container(
                //         height: 48,
                //         decoration: BoxDecoration(
                //           color: Color(0xFFEC1D24),
                //           borderRadius: BorderRadius.circular(24),
                //         ),
                //         child: Center(
                //           child: Text(
                //             'OK',
                //             style: GoogleFonts.inter(
                //               fontSize: 16,
                //               fontWeight: FontWeight.w600,
                //               color: Colors.white,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _waitUntilNotifierQuiet(ValueNotifier<bool> busy) async {
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    var sawBusy = busy.value;
    while (DateTime.now().isBefore(deadline)) {
      if (busy.value) sawBusy = true;
      if (sawBusy && !busy.value) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    throw TimeoutException(
      'Bluetooth operation timed out',
      const Duration(seconds: 120),
    );
  }

  ValueNotifier<bool> _fetchBusyFor(PeripheralConfigSection s) {
    final bp = ble.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        return bp.isModuleSetupFetchCommandActive;
      case PeripheralConfigSection.panelInfo:
        return bp.isPanelInfoSetupFetchCommandActive;
      case PeripheralConfigSection.generalModule:
        return bp.isGeneralModuleSetupFetchCommandActive;
      case PeripheralConfigSection.accessCode:
        return bp.isAccessCodeSetupFetchCommandActive;
      case PeripheralConfigSection.serviceDue:
        return bp.isServiceDueFetchCommandActive;
      case PeripheralConfigSection.input:
        return bp.isInputSetupFetchCommandActive;
      case PeripheralConfigSection.relay:
        return bp.isRelaySetupFetchCommandActive;
      case PeripheralConfigSection.zone:
        return bp.isZoneSetupFetchCommandActive;
      case PeripheralConfigSection.sounder:
        return bp.isSounderSetupFetchCommandActive;
      case PeripheralConfigSection.radio:
        return bp.isRadioSetupFetchCommandActive;
      case PeripheralConfigSection.lBus:
        return bp.isLBusSetupFetchCommandActive;
      case PeripheralConfigSection.extOut:
        return bp.isExtOutCommandFetchActive;
    }
  }

  void _startFetchSection(PeripheralConfigSection s) {
    final bp = ble.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        bp.isModuleSetupFetchCommandActive.value = true;
        bleController.startModuleSetupFetch();
        break;
      case PeripheralConfigSection.panelInfo:
        bp.isPanelInfoSetupFetchCommandActive.value = true;
        bleController.startPanelInfoSetupFetch();
        break;
      case PeripheralConfigSection.generalModule:
        bp.isGeneralModuleSetupFetchCommandActive.value = true;
        bleController.startGeneralModuleSetupFetch();
        break;
      case PeripheralConfigSection.accessCode:
        bp.isAccessCodeSetupFetchCommandActive.value = true;
        bleController.startAccessCodeSetupFetch();
        break;
      case PeripheralConfigSection.serviceDue:
        bp.isServiceDueFetchCommandActive.value = true;
        bleController.startServiceDueFetch();
        break;
      case PeripheralConfigSection.input:
        bp.isInputSetupFetchCommandActive.value = true;
        bleController.startInputSetupFetch();
        break;
      case PeripheralConfigSection.relay:
        bp.isRelaySetupFetchCommandActive.value = true;
        bleController.startRelaySetupFetch();
        break;
      case PeripheralConfigSection.zone:
        bp.isZoneSetupFetchCommandActive.value = true;
        bleController.startZoneSetupFetch();
        break;
      case PeripheralConfigSection.sounder:
        bp.isSounderSetupFetchCommandActive.value = true;
        bleController.startSounderSetupFetch();
        break;
      case PeripheralConfigSection.radio:
        bp.isRadioSetupFetchCommandActive.value = true;
        bleController.startRadioSetupFetch();
        break;
      case PeripheralConfigSection.lBus:
        bp.isLBusSetupFetchCommandActive.value = true;
        bleController.startLBusSetupFetch();
        break;
      case PeripheralConfigSection.extOut:
        bp.isExtOutCommandFetchActive.value = true;
        bleController.startExtOutFetch();
        break;
    }
  }

  Future<void> _runConfigLogFetchRemaining() async {
    for (final s in kPeripheralConfigFetchOrder.skip(1)) {
      _startFetchSection(s);
      await _waitUntilNotifierQuiet(_fetchBusyFor(s));
      if (s == PeripheralConfigSection.lBus &&
          ble.bleProcess.isLbusFetchHasErrors.value) {
        final errs = ble.bleProcess.lbusFetchErrors.value.join(', ');
        throw StateError('L-Bus download failed: $errs');
      }
    }
  }

  ValueNotifier<bool> _applyBusyFor(PeripheralConfigSection s) {
    final bp = ble.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        return bp.isModuleSetupFetchCommandActive;
      case PeripheralConfigSection.panelInfo:
        return bp.isPanelInfoSetupApplyCommandActive;
      case PeripheralConfigSection.generalModule:
        return bp.isGeneralModuleSetupApplyCommandActive;
      case PeripheralConfigSection.accessCode:
        return bp.isAccessCodeSetupApplyCommandActive;
      case PeripheralConfigSection.serviceDue:
        return bp.isServiceDueApplyCommandActive;
      case PeripheralConfigSection.input:
        return bp.isInputSetupApplyActive;
      case PeripheralConfigSection.relay:
        return bp.isRelaySetupCommandApplyActive;
      case PeripheralConfigSection.zone:
        return bp.isZoneSetupCommandApplyActive;
      case PeripheralConfigSection.sounder:
        return bp.isSounderSetupApplyCommandActive;
      case PeripheralConfigSection.radio:
        return bp.isRadioSetupCommandApplyActive;
      case PeripheralConfigSection.lBus:
        return bp.isLBusSetupApplyCommandActive;
      case PeripheralConfigSection.extOut:
        return bp.isExtOutCommandApplyActive;
    }
  }

  void _startApplySection(PeripheralConfigSection s) {
    final bp = ble.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        break;
      case PeripheralConfigSection.panelInfo:
        bp.isPanelInfoSetupApplyCommandActive.value = true;
        bleController.startPanelInfoSetupApply();
        break;
      case PeripheralConfigSection.generalModule:
        bp.isGeneralModuleSetupApplyCommandActive.value = true;
        bleController.startGeneralModuleSetupApply();
        break;
      case PeripheralConfigSection.accessCode:
        bp.isAccessCodeSetupApplyCommandActive.value = true;
        bleController.startAccessCodeSetupApply();
        break;
      case PeripheralConfigSection.serviceDue:
        bp.isServiceDueApplyCommandActive.value = true;
        bleController.startServiceDueApply();
        break;
      case PeripheralConfigSection.input:
        bp.isInputSetupApplyActive.value = true;
        bleController.startInputSetupApply();
        break;
      case PeripheralConfigSection.relay:
        bp.isRelaySetupCommandApplyActive.value = true;
        bleController.startRelaySetupApply();
        break;
      case PeripheralConfigSection.zone:
        bp.isZoneSetupCommandApplyActive.value = true;
        bleController.startZoneSetupApply();
        break;
      case PeripheralConfigSection.sounder:
        bp.isSounderSetupApplyCommandActive.value = true;
        bleController.startSounderSetupApply();
        break;
      case PeripheralConfigSection.radio:
        bp.isRadioSetupCommandApplyActive.value = true;
        bleController.startRadioSetupApply();
        break;
      case PeripheralConfigSection.lBus:
        bp.isLBusSetupApplyCommandActive.value = true;
        bleController.startLBusSetupApply();
        break;
      case PeripheralConfigSection.extOut:
        bp.isExtOutCommandApplyActive.value = true;
        bleController.startExtOutApply();
        break;
    }
  }

  Future<void> _runConfigLogApplyRemaining() async {
    for (final s in kPeripheralConfigApplyOrder.skip(1)) {
      _startApplySection(s);
      await _waitUntilNotifierQuiet(_applyBusyFor(s));
    }
  }

  Future<void> _saveAllPeripheralCachesFromBle() async {
    await _saveRelayCacheAndNotifyRefresh();
    await _saveInputCacheAndNotifyRefresh();
    await _saveZoneCacheAndNotifyRefresh();
    await _saveExtOutCacheAndNotifyRefresh();
    await _saveSounderCacheAndNotifyRefresh();
    await _saveServiceDueCacheAndNotifyRefresh();
    await _saveModuleCacheAndNotifyRefresh();
    await _saveLBusCacheAndNotifyRefresh();
    await _saveAccessCodeCacheAndNotifyRefresh();
    await _savePanelInfoCacheAndNotifyRefresh();
    await _saveGeneralModuleCacheAndNotifyRefresh();
  }

  void _onConfigLogDownloadAndCompare() {
    _configLogCompareResult.value = null;
    showPasswordPopup(
      onCall: () {
        ble.bleProcess.isModuleSetupFetchCommandActive.value = true;
        bleController.startModuleSetupFetch();
      },
      mode: 'bottomsheet_download',
      isConfigLogBulk: true,
      downloadSuccessMessage: 'Configuration',
      onDownloadComplete: () async {
        try {
          await _runConfigLogFetchRemaining();
          _configLogCompareResult.value = PeripheralConfigSnapshot.compare(
            panelBySection: PeripheralConfigSnapshot.fromBleManager(
              _bleManager,
            ),
            localBySection: await PeripheralConfigSnapshot.fromCache(
              _selectedDevice.id,
            ),
          );
        } catch (e, st) {
          debugPrint('$e\n$st');
          _configLogCompareResult.value = ConfigCompareResult.withError(
            e is TimeoutException
                ? 'Operation timed out. Stay close to the device and try again.'
                : e.toString(),
          );
        }
      },
    );
  }

  Future<void> _onConfigLogUsePanelDataInApp() async {
    await _saveAllPeripheralCachesFromBle();
    _configLogCompareResult.value = PeripheralConfigSnapshot.compare(
      panelBySection: PeripheralConfigSnapshot.fromBleManager(_bleManager),
      localBySection: await PeripheralConfigSnapshot.fromCache(
        _selectedDevice.id,
      ),
    );
  }

  void _onConfigLogApplyLocalToPanel() {
    showPasswordPopup(
      onCall: () {
        ble.bleProcess.isPanelInfoSetupApplyCommandActive.value = true;
        bleController.startPanelInfoSetupApply();
      },
      isPanelInfoSetup: true,
      mode: 'bottomsheet_apply',
      isConfigLogBulkApply: true,
    );
  }

  void showConfigLogBottomSheet({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => ConfigLogBottomSheet(
            deviceId: _selectedDevice.id,
            compareResult: _configLogCompareResult,
            isWorking: _configLogWorking,
            onDownloadAndCompare: _onConfigLogDownloadAndCompare,
            onUsePanelDataInApp: _onConfigLogUsePanelDataInApp,
            onApplyLocalToPanel: _onConfigLogApplyLocalToPanel,
          ),
    ).whenComplete(() {
      if (!mounted) return;
      _configLogCompareResult.value = null;
      _configLogWorking.value = false;
    });
  }

  void showPasswordPopup({
    required Function() onCall,
    bool? isExtOut = false,
    bool? isInputSetup = false,
    bool? isRelaySetup = false,
    bool? isZoneSetup = false,
    bool? isSounderSetup = false,
    bool? isServiceDueSetup = false,
    bool? isAccessCodeSetup = false,
    bool? isPanelInfoSetup = false,
    bool? isGeneralModuleSetup = false,
    bool? isAdcSetup = false,
    bool isConfigLogBulk = false,
    bool isConfigLogBulkApply = false,
    String? mode,
    Future<void> Function()? onDownloadComplete,
    String? downloadSuccessMessage,
  }) {
    final bleProcess = ble.bleProcess;
    final bool useCachedSessionAccess =
        bleProcess.sessionAccessCodeReady.value &&
        bleProcess.accessKey.value.isNotEmpty;

    // Reset navigation guard each time the dialog opens
    _navigatingToDeviceConnecting = false;

    // Reset previous access-key validation state (keep cached access key when reusing session)
    bleProcess.isAccessKeyValid.value = null;
    if (useCachedSessionAccess) {
      // Start in the same UI state as after tapping Verify: verifying, no field, no buttons.
      bleProcess.processDesc.value = "Validating";
    } else {
      bleProcess.accessKey.value = "";
      bleProcess.processDesc.value = "";
    }

    Timer? accessKeyValidationTimer;
    void cancelAccessKeyTimer() {
      accessKeyValidationTimer?.cancel();
      accessKeyValidationTimer = null;
    }

    final TextEditingController _controller = TextEditingController();
    final FocusNode _focusNode = FocusNode();
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
                // Lock icon — red while entering code; green when field hidden (verifying / granted)
                ValueListenableBuilder<bool?>(
                  valueListenable: isAccessKeyValid,
                  builder: (_, isAccessKeyValidValue, __) {
                    return ValueListenableBuilder<String>(
                      valueListenable: bleProcess.processDesc,
                      builder: (_, processDescValue, __) {
                        final bool hideInput =
                            (processDescValue.isNotEmpty &&
                                isAccessKeyValidValue != false) ||
                            isAccessKeyValidValue == true;
                        final Color iconColor =
                            hideInput
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFEC1D24);
                        final Color circleColor =
                            hideInput
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFBDEE1);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOutCubic,
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svgs/lock_icon.svg',
                              height: 32,
                              width: 32,
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: 16),

                // Password input (title below animates: Enter → Verifying / Access granted)
                ValueListenableBuilder<bool?>(
                  valueListenable: isAccessKeyValid,
                  builder: (_, isAccessKeyValidValue, __) {
                    if (isAccessKeyValidValue != null) {
                      cancelAccessKeyTimer();
                    }
                    if (isAccessKeyValidValue == true &&
                        !_navigatingToDeviceConnecting) {
                      _navigatingToDeviceConnecting = true;
                      bleProcess.setSessionAccessCode(
                        bleProcess.accessKey.value,
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!mounted) return;
                        await Future.delayed(const Duration(seconds: 1));
                        if (!mounted) return;
                        Navigator.of(dialogContext, rootNavigator: true).pop();
                        if (isConfigLogBulkApply &&
                            mode == 'bottomsheet_apply') {
                          _configLogWorking.value = true;
                          try {
                            await _runConfigLogApplyRemaining();
                            await _saveAllPeripheralCachesFromBle();
                            if (mounted) {
                              _configLogCompareResult
                                  .value = PeripheralConfigSnapshot.compare(
                                panelBySection:
                                    PeripheralConfigSnapshot.fromBleManager(
                                      _bleManager,
                                    ),
                                localBySection:
                                    await PeripheralConfigSnapshot.fromCache(
                                      _selectedDevice.id,
                                    ),
                              );
                            }
                            if (mounted) {
                              showApplySuccessDialog(
                                context,
                                'Configuration',
                                subtitle:
                                    'Your saved setup has been applied to the panel.',
                              );
                            }
                          } catch (e, st) {
                            debugPrint('$e\n$st');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not apply configuration: $e',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            _configLogWorking.value = false;
                            _navigatingToDeviceConnecting = false;
                          }
                        } else if (mode == 'bottomsheet_download') {
                          if (isConfigLogBulk) {
                            _configLogWorking.value = true;
                            try {
                              await onDownloadComplete?.call();
                              if (mounted) {
                                final message =
                                    downloadSuccessMessage ?? 'Configuration';
                                showDownloadSuccessDialog(context, message);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                              }
                            } finally {
                              _configLogWorking.value = false;
                              _navigatingToDeviceConnecting = false;
                            }
                          } else {
                            await onDownloadComplete?.call();
                            if (mounted) {
                              final message =
                                  downloadSuccessMessage ??
                                  (isExtOut == true
                                      ? 'Extinguishing Output'
                                      : isInputSetup == true
                                      ? 'Inputs'
                                      : isRelaySetup == true
                                      ? 'Relays'
                                      : isZoneSetup == true
                                      ? 'Zones'
                                      : isSounderSetup == true
                                      ? 'Sounders'
                                      : isServiceDueSetup == true
                                      ? 'Service Due'
                                      : isAccessCodeSetup == true
                                      ? 'Access Code'
                                      : isPanelInfoSetup == true
                                      ? 'Panel Info'
                                      : isGeneralModuleSetup == true
                                      ? 'General Module'
                                      : isAdcSetup == true
                                      ? 'Diagnostics'
                                      : 'Configuration');
                              showDownloadSuccessDialog(context, message);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            }
                          }
                        } else if (ble.bleProcess.isExtOutApplyDone.value) {
                          ble.bleProcess.isExtOutApplyButtonActive.value = true;
                          await _saveExtOutCacheAndNotifyRefresh();
                          if (mounted) {
                            showApplySuccessDialog(
                              context,
                              'Extinguishing Output',
                            );
                          }
                        } else if (ble.bleProcess.isInputSetupApplyDone.value) {
                          await _saveInputCacheAndNotifyRefresh();
                          if (mounted) {
                            showApplySuccessDialog(context, 'Inputs');
                          }
                        } else if (ble.bleProcess.isRelaySetupApplyDone.value &&
                            mounted) {
                          await _saveRelayCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Relays');
                        } else if (ble.bleProcess.isZoneSetupApplyDone.value &&
                            mounted) {
                          await _saveZoneCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Zones');
                        } else if (ble.bleProcess.isRadioSetupApplyDone.value &&
                            mounted) {
                          await _saveRadioCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Radio');
                        } else if (ble.bleProcess.isLBusSetupApplyDone.value &&
                            mounted) {
                          await _saveLBusCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'L-Bus');
                        } else if (ble
                                .bleProcess
                                .isSounderSetupApplyDone
                                .value &&
                            mounted) {
                          await _saveSounderCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Sounders');
                        } else if (ble.bleProcess.isServiceDueApplyDone.value &&
                            mounted) {
                          await _saveServiceDueCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Service Due');
                        } else if (ble
                                .bleProcess
                                .isAccessCodeSetupApplyDone
                                .value &&
                            mounted) {
                          await _saveAccessCodeCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Access Code');
                        } else if (ble
                                .bleProcess
                                .isPanelInfoSetupApplyDone
                                .value &&
                            mounted) {
                          await _savePanelInfoCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'Panel Info');
                        } else if (ble
                                .bleProcess
                                .isGeneralModuleSetupApplyDone
                                .value &&
                            mounted) {
                          await _saveGeneralModuleCacheAndNotifyRefresh();
                          showApplySuccessDialog(context, 'General Module');
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

                    return ValueListenableBuilder<String>(
                      valueListenable: bleProcess.processDesc,
                      builder: (_, processDescValue, __) {
                        final bool hideInput =
                            (processDescValue.isNotEmpty &&
                                isAccessKeyValidValue != false) ||
                            isAccessKeyValidValue == true;
                        if (hideInput) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_focusNode.hasFocus) {
                              _focusNode.unfocus();
                            }
                          });
                        }

                        const Duration animDuration = Duration(
                          milliseconds: 280,
                        );

                        final String dialogTitle =
                            !hideInput
                                ? 'Enter Access Code'
                                : (isAccessKeyValidValue == true
                                    ? mode == "bottomsheet_download"
                                        ? 'Downloading...'
                                        : mode == "bottomsheet_apply"
                                        ? "Applying..."
                                        : "Validated"
                                    : (processDescValue == 'Validating' ||
                                        processDescValue.toLowerCase().contains(
                                          'validat',
                                        ))
                                    ? (bleProcess.sessionAccessCodeReady.value
                                        ? 'Initiating'
                                        : 'Verifying access')
                                    : (mode == "bottomsheet_download"
                                        ? 'Downloading...'
                                        : mode == "bottomsheet_apply"
                                        ? "Applying..."
                                        : "Validated"));

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedSwitcher(
                                duration: animDuration,
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: offsetAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  dialogTitle,
                                  key: ValueKey<String>(dialogTitle),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D3D3D),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            AnimatedSize(
                              duration: animDuration,
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.hardEdge,
                              child:
                                  hideInput
                                      ? const SizedBox.shrink()
                                      : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 24),
                                          TextField(
                                            controller: _controller,
                                            focusNode: _focusNode,
                                            keyboardType: TextInputType.number,
                                            obscureText: true,
                                            maxLength: 8,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 8,
                                              color: Color(0xFF3D3D3D),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            onTap: () {
                                              if (bleProcess
                                                      .isAccessKeyValid
                                                      .value ==
                                                  false) {
                                                bleProcess.processDesc.value =
                                                    '';
                                                bleProcess
                                                    .isAccessKeyValid
                                                    .value = null;
                                              }
                                            },
                                            onChanged: (val) {
                                              final wasWrong =
                                                  bleProcess
                                                      .isAccessKeyValid
                                                      .value ==
                                                  false;
                                              accessKey.value = val;
                                              bleProcess
                                                  .isAccessKeyValid
                                                  .value = null;
                                              if (wasWrong) {
                                                bleProcess.processDesc.value =
                                                    '';
                                              }
                                            },
                                            decoration: InputDecoration(
                                              hintText: '••••••••',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 8,
                                                color: Color(0xFFD0D0D0),
                                              ),
                                              counterText: '',
                                              filled: true,
                                              fillColor: Color(0xFFF8F8F8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      isAccessKeyValidValue ==
                                                              false
                                                          ? Color(0xFFEC1D24)
                                                          : Color(0xFFD0D0D0),
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      isAccessKeyValidValue ==
                                                              false
                                                          ? Color(0xFFEC1D24)
                                                          : Color(0xFFD0D0D0),
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Color(0xFFEC1D24),
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Color(0xFFEC1D24),
                                                  width: 1,
                                                ),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFEC1D24),
                                                      width: 2,
                                                    ),
                                                  ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                            ),
                            // Status text during validation/success
                            Builder(
                              builder: (context) {
                                String? status;
                                if (isAccessKeyValidValue == false) {
                                  status =
                                      processDescValue.isNotEmpty
                                          ? processDescValue
                                          : 'Wrong password. Try again.';
                                } else if (isAccessKeyValidValue == null &&
                                    (processDescValue.isNotEmpty ||
                                        _controller.text.isNotEmpty)) {
                                  final bool validatingLike =
                                      processDescValue == 'Validating' ||
                                      processDescValue.toLowerCase().contains(
                                        'validat',
                                      );
                                  status =
                                      processDescValue.isNotEmpty
                                          ? (bleProcess
                                                      .sessionAccessCodeReady
                                                      .value &&
                                                  validatingLike
                                              ? ''
                                              : processDescValue)
                                          : 'Validating...';
                                } else if (isAccessKeyValidValue == true) {
                                  status =
                                      mode == "bottomsheet_download"
                                          ? "Processing..."
                                          : mode == "bottomsheet_apply"
                                          ? "Processing..."
                                          : "Fetching...";
                                  if (mounted) {
                                    bleProcess.processDesc.value = "Success";
                                  }
                                }
                                if (isAccessKeyValidValue == false) {
                                  if (_controller.text.isNotEmpty) {
                                    _controller.clear();
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_focusNode.canRequestFocus) {
                                      _focusNode.requestFocus();
                                    }
                                  });
                                }
                                return status == null || status.isEmpty
                                    ? const SizedBox(height: 8)
                                    : Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4,
                                        top: 12,
                                      ),
                                      child: Text(
                                        status,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isAccessKeyValidValue == false
                                                  ? const Color(0xFFEC1D24)
                                                  : const Color(0xFF3D3D3D),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                              },
                            ),

                            ValueListenableBuilder<String>(
                              valueListenable: bleProcess.processDesc,
                              builder: (_, processDescForButtons, __) {
                                // Show only before verify, or after wrong key. Never when success.
                                final bool showButtons =
                                    isAccessKeyValidValue != true &&
                                    (processDescForButtons.isEmpty ||
                                        isAccessKeyValidValue == false);
                                return showButtons
                                    ? Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 48,
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFFEC1D24),
                                                    side: const BorderSide(
                                                      color: Color(0xFFEC1D24),
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    cancelAccessKeyTimer();
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: SizedBox(
                                                height: 48,
                                                child: ListenableBuilder(
                                                  listenable: _controller,
                                                  builder: (context, _) {
                                                    final canVerify =
                                                        _controller.text
                                                            .trim()
                                                            .isNotEmpty;
                                                    return ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFEC1D24,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                24,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          canVerify
                                                              ? () async {
                                                                FocusScope.of(
                                                                  dialogContext,
                                                                ).unfocus();

                                                                bleProcess
                                                                    .isAccessKeyValid
                                                                    .value = null;
                                                                bleProcess
                                                                        .processDesc
                                                                        .value =
                                                                    "Validating";

                                                                accessKey
                                                                        .value =
                                                                    _controller
                                                                        .text;

                                                                if (isConfigLogBulkApply &&
                                                                    mode ==
                                                                        'bottomsheet_apply') {
                                                                  await PeripheralCacheToBle.applyToBleManager(
                                                                    _bleManager,
                                                                    _selectedDevice
                                                                        .id,
                                                                  );
                                                                }

                                                                onCall();
                                                              }
                                                              : null,
                                                      child: Text(
                                                        'Verify',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (useCachedSessionAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (isConfigLogBulkApply && mode == 'bottomsheet_apply') {
          await PeripheralCacheToBle.applyToBleManager(
            _bleManager,
            _selectedDevice.id,
          );
        }
        if (!mounted) return;
        onCall();
        // startExtOutFetch / etc. call resetProcessExtOutState which clears processDesc.
        // Keep verifying UI until the protocol sets progress (e.g. "Downloading …").
        if (bleProcess.processDesc.value.isEmpty) {
          bleProcess.processDesc.value = "Validating";
        }
      });
    }
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed header - Panel Information Row (out of scroll region)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPanelInfoHeader(),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _buildPeripheralOverview(),
                      SizedBox(height: 12),
                      _buildPanelActions(),
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

  Widget _buildPanelInfoHeader() {
    return Row(
      children: [
        SvgPicture.asset('assets/svgs/panel_icon.svg', height: 62, width: 62),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(widget.panelName),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ble.bleProcess.receivedPanelName.value.isEmpty
                    ? BleNameUtils.getDisplayIdFromBleName(widget.panelName)
                    : "${ble.bleProcess.receivedPanelName.value}~${BleNameUtils.getDisplayIdFromBleName(widget.panelName)}",
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
      ],
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
        SizedBox(height: 8),
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
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showRelaySetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isRelaySetupFetchCommandActive.value =
                              true;
                          bleController.startRelaySetupFetch();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveRelayCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isRelaySetupCommandApplyActive.value =
                              true;
                          bleController.startRelaySetupApply();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _relayRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Inputs',
                iconPath: 'assets/svgs/peripheral_input_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showInputSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isInputSetupFetchCommandActive.value =
                              true;
                          bleController.startInputSetupFetch();
                        },
                        isInputSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveInputCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isInputSetupApplyActive.value = true;
                          bleController.startInputSetupApply();
                        },
                        isInputSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _inputRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Zones',
                iconPath: 'assets/svgs/peripheral_zones_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showZoneSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isZoneSetupFetchCommandActive.value =
                              true;
                          bleController.startZoneSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveZoneCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isZoneSetupCommandApplyActive.value =
                              true;
                          bleController.startZoneSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Sounders',
                iconPath: 'assets/svgs/peripheral_sounder_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showSounderSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isSounderSetupFetchCommandActive
                              .value = true;
                          bleController.startSounderSetupFetch();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveSounderCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Sounder',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isSounderSetupApplyCommandActive
                              .value = true;
                          bleController.startSounderSetupApply();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _sounderRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Radio',
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
                isDisabled: true,
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showRadioSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isRadioSetupFetchCommandActive.value =
                              true;
                          bleController.startRadioSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveRadioCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Radio',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isRadioSetupCommandApplyActive.value =
                              true;
                          bleController.startRadioSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Module Info',
                iconPath: 'assets/svgs/peripheral_aux_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showModuleSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isModuleSetupFetchCommandActive.value =
                              true;
                          bleController.startModuleSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Module',
                      );
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'L-Bus',
                iconPath: 'assets/svgs/peripheral_l_bus_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showLBusSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isLBusSetupFetchCommandActive.value =
                              true;
                          bleController.startLBusSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveLBusCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'L-Bus',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isLBusSetupApplyCommandActive.value =
                              true;
                          bleController.startLBusSetupApply();
                        },
                        mode: 'bottomsheet_apply',
                        downloadSuccessMessage: 'L-Bus',
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Ext Out',
                iconPath: 'assets/svgs/peripheral_ext_out_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showExtOutBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isExtOutCommandFetchActive.value =
                              true;
                          bleController.startExtOutFetch();
                        },
                        isExtOut: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveExtOutCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isExtOutCommandApplyActive.value =
                              true;
                          bleController.startExtOutApply();
                        },
                        isExtOut: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _extOutRefreshTrigger,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showLBusSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => LBusBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showSounderSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => SounderModeBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showServiceDueSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => ServiceDueBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  showAccessCodeSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => AccessCodesBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  showPanelInfoSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => PanelInfoBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  showGeneralModuleSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => GeneralModuleBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showAdcDiagnosticsSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onStop,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => DiagnosticInfoBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onStop: onStop,
          ),
    );
  }

  // showAdcDiagnosticsSetupBottomSheet({
  //   required BuildContext context,
  //   required String deviceId,
  //   required VoidCallback onDownload,
  //   required VoidCallback onApply,
  //   required ValueNotifier<int> refreshTrigger,
  // }) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     barrierColor: Colors.black.withOpacity(0.4),
  //     builder:
  //         (_) => GeneralModuleBottomSheet(
  //           deviceId: deviceId,
  //           onDownload: onDownload,
  //           onApply: onApply,
  //           refreshTrigger: refreshTrigger,
  //         ),
  //   );
  // }

  void showModuleSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) =>
              ModuleInfoBottomSheet(deviceId: deviceId, onDownload: onDownload),
    );
  }

  void showExtOutBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => ExtOutBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showInputSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => InputModeBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showRelaySetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => RelayModeBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showZoneSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => ZoneBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showWalkTestZoneBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => WalkTestZoneBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showRadioSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) => RadioModeBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  Future<void> _saveRelayCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveRelaySetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.relayMap(m),
    );
    _relayRefreshTrigger.value++;
  }

  Future<void> _saveInputCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveInputSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.inputMap(m),
    );
    _inputRefreshTrigger.value++;
  }

  Future<void> _saveZoneCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveZoneSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.zoneMap(m),
    );
    _zoneRefreshTrigger.value++;
  }

  Future<void> _saveExtOutCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveExtOutSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.extOutMap(m),
    );
    _extOutRefreshTrigger.value++;
  }

  Future<void> _saveSounderCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveSounderSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.sounderMap(m),
    );
    _sounderRefreshTrigger.value++;
  }

  Future<void> _saveServiceDueCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveServiceDueSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.serviceDueMap(m),
    );
    _serviceDueRefreshTrigger.value++;
  }

  Future<void> _saveRadioCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveRadioSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.radioMap(m),
    );
    _zoneRefreshTrigger.value++;
  }

  Future<void> _saveModuleCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveModuleSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.moduleMap(m),
    );
  }

  Future<void> _saveLBusCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveLBusSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.lBusList(m),
    );
    _zoneRefreshTrigger.value++;
  }

  Future<void> _saveAccessCodeCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveAccessCodeSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.accessCodeList(m),
    );
    _accessCodeRefreshTrigger.value++;
  }

  Future<void> _savePanelInfoCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.savePanelInfoSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.panelInfoMap(m),
    );
    _panelInfoRefreshTrigger.value++;
  }

  Future<void> _saveGeneralModuleCacheAndNotifyRefresh() async {
    final m = _bleManager;
    await PeripheralSetupCache.saveGeneralModuleSetup(
      _selectedDevice.id,
      PeripheralConfigSnapshot.generalModuleMap(m),
    );
    _generalModuleRefreshTrigger.value++;
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
          ble.bleProcess.processDesc.value = "";
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
        SizedBox(height: 8),
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
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
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
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showServiceDueSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isServiceDueFetchCommandActive.value =
                              true;
                          bleController.startServiceDueFetch();
                        },
                        isServiceDueSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _saveServiceDueCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Service Due',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isServiceDueApplyCommandActive.value =
                              true;
                          bleController.startServiceDueApply();
                        },
                        isServiceDueSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _serviceDueRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Access Code',
                iconPath: 'assets/svgs/panel_action_access_code_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }

                  showAccessCodeSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isAccessCodeSetupFetchCommandActive
                              .value = true;
                          bleController.startAccessCodeSetupFetch();
                        },
                        isAccessCodeSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _saveAccessCodeCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Access Code',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isAccessCodeSetupApplyCommandActive
                              .value = true;
                          bleController.startAccessCodeSetupApply();
                        },
                        isAccessCodeSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _accessCodeRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Panel Info',
                iconPath: 'assets/svgs/panel_action_panel_info_icon.svg',
                onTap: () {
                  showPanelInfoSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isPanelInfoSetupFetchCommandActive
                              .value = true;
                          bleController.startPanelInfoSetupFetch();
                        },
                        isPanelInfoSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _savePanelInfoCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Panel Info',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isPanelInfoSetupApplyCommandActive
                              .value = true;
                          bleController.startPanelInfoSetupApply();
                        },
                        isPanelInfoSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _panelInfoRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'General',
                iconPath: 'assets/svgs/panel_action_general_module_icon.svg',
                onTap: () {
                  showGeneralModuleSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isGeneralModuleSetupFetchCommandActive
                              .value = true;
                          bleController.startGeneralModuleSetupFetch();
                        },
                        isGeneralModuleSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _saveGeneralModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'General Module',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble
                              .bleProcess
                              .isGeneralModuleSetupApplyCommandActive
                              .value = true;
                          bleController.startGeneralModuleSetupApply();
                        },
                        isGeneralModuleSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _generalModuleRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Diagnostics',
                iconPath: 'assets/svgs/diagnostic_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showAdcDiagnosticsSetupBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isAdcSetupFetchCommandActive.value =
                              true;
                          bleController.startAdcSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Diagnostics',
                      );
                    },
                    onStop: () {
                      ble.bleProcess.isAdcSetupFetchCommandActive.value = false;
                    },
                  );
                  // showPasswordPopup(
                  //   onCall: () {
                  //     ble.bleProcess.isAdcSetupFetchCommandActive.value = true;
                  //     bleController.startAdcSetupFetch();
                  //   },
                  // );
                },
              ),
              _peripheralTile(
                peripheralName: 'Walk Test',
                iconPath: 'assets/svgs/walk_test_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showWalkTestZoneBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isZoneSetupFetchCommandActive.value =
                              true;
                          bleController.startZoneSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete: _saveZoneCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isZoneSetupCommandApplyActive.value =
                              true;
                          bleController.startZoneSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'Config Log',
                iconPath: 'assets/svgs/panel_action_config_log_icon.svg',
                onTap: () {
                  if (_selectedDevice.manufacturerData.isNotEmpty &&
                      _selectedDevice.manufacturerData.last == 1) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showConfigLogBottomSheet(context: context);
                },
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
