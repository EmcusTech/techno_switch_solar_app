import 'dart:async';
import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/screens/log_history_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart'
    hide ble;
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/settings_screen.dart';
import 'package:techno_switch_solar_app/screens/test_mode_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/commissioning_test_results_helper.dart';
import 'package:techno_switch_solar_app/utils/export_tile.dart';
import 'package:techno_switch_solar_app/utils/project_report_pdf_util.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
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
import 'package:techno_switch_solar_app/panel_config/panel_access_password_popup.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_feedback_dialogs.dart';
import 'package:techno_switch_solar_app/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/config_log_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_choice_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_relay_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_sounder_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/walk_test_zone_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/firmware_upgrade_bottom_sheet.dart';
import 'package:techno_switch_solar_app/widgets/panel_access_code_dialog.dart';
import 'package:techno_switch_solar_app/widgets/bootloader_connect_flow.dart';
import 'package:techno_switch_solar_app/widgets/ble_connecting_dialog.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

final BleManager ble = Get.find<BleManager>();

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
      siteId: widget.siteId,
      siteName: widget.siteName,
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
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
  }

  @override
  Widget build(BuildContext context) {
    const disabledIndexes = [1, 2];

    Color itemColor(int index) {
      if (disabledIndexes.contains(index)) {
        return Colors.grey;
      }
      return _selectedIndex == index ? ColorConstants.white : ColorConstants.blackMaterial;
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
      resizeToAvoidBottomInset: false,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.1),
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
            backgroundColor: ColorConstants.primary,
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
                  label: StringConstants.dashboard,
                  asset: 'assets/svgs/dashboard_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 1,
                  label: StringConstants.settings,
                  asset: 'assets/svgs/setting_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 2,
                  label: StringConstants.testMode,
                  asset: 'assets/svgs/test_mode_icon.svg',
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: navItem(
                  index: 3,
                  label: StringConstants.logHistory,
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

class _ProjectDashboardContent extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  final int? siteId;
  final String? siteName;
  final DiscoveredDevice selectedDevice;
  final void Function(DiscoveredDevice)? onDeviceReconnected;

  const _ProjectDashboardContent({
    required this.panelName,
    required this.panelVersionNo,
    this.siteId,
    this.siteName,
    required this.selectedDevice,
    this.onDeviceReconnected,
  });

  @override
  State<_ProjectDashboardContent> createState() =>
      _ProjectDashboardContentState();
}

class _ProjectDashboardContentState extends State<_ProjectDashboardContent> {
  bool _isUnexpectedDisconnectDialogOpen = false;
  final ValueNotifier<bool> _navigatingToDeviceConnecting = ValueNotifier<bool>(
    false,
  );

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

  bool _isConnecting = false;
  StreamSubscription? _scanSubscription;
  final BluetoothService _bluetoothService = BluetoothService();
  final bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();
  late DiscoveredDevice _selectedDevice;

  bool _hadEstablishedBleSession = false;

  bool _suppressUnexpectedBleDisconnectUi = false;

  void _closeModalOverlaysAboveDashboard() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    Navigator.of(context).popUntil((r) => r == route);
  }

  void _showUnexpectedBleDisconnectDialog() {
    if (!mounted || _isUnexpectedDisconnectDialogOpen) return;

    _isUnexpectedDisconnectDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: ColorConstants.errorIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bluetooth_disabled,
                        color: ColorConstants.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    StringConstants.bluetoothDisconnected,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StringConstants.theConnectionToTheDeviceWasLostAnyOpenPanelsWereClosedUseConnectWhenYouAreReadyToReconnect,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        _isUnexpectedDisconnectDialogOpen = false;
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            StringConstants.ok,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isUnexpectedDisconnectDialogOpen = false;
    });
  }

  void _onBleSessionChanged() {
    if (!mounted) return;

    final connected = _bleManager.isConnectedNotifier.value;
    final handshakeComplete = _bleManager.handshakeCompleteNotifier.value;
    final sessionActive = connected && handshakeComplete;
    final connectInProgress = _isConnecting || _bleManager.isConnectInProgress;

    if (sessionActive && _isUnexpectedDisconnectDialogOpen) {
      _isUnexpectedDisconnectDialogOpen = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    }

    if (sessionActive) {
      _hadEstablishedBleSession = true;
    }

    final lostEstablishedSession =
        _hadEstablishedBleSession && !sessionActive && !connectInProgress;

    if (lostEstablishedSession) {
      _hadEstablishedBleSession = false;

      final suppressForFirmware =
          BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value;

      if (!suppressForFirmware) {
        _closeModalOverlaysAboveDashboard();

        if (_suppressUnexpectedBleDisconnectUi) {
          _suppressUnexpectedBleDisconnectUi = false;
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showUnexpectedBleDisconnectDialog();
          });
        }
      } else {
        if (_suppressUnexpectedBleDisconnectUi) {
          _suppressUnexpectedBleDisconnectUi = false;
        }
      }
    }
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
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.disconnectDevice,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.textGray,
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
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.cancel,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.textGray,
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
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
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
                                color: ColorConstants.white,
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
        _hadEstablishedBleSession = false;
        await _bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  PanelConfigRefreshNotifiers get _panelRefreshNotifiers =>
      PanelConfigRefreshNotifiers(
        relay: _relayRefreshTrigger,
        input: _inputRefreshTrigger,
        zone: _zoneRefreshTrigger,
        extOut: _extOutRefreshTrigger,
        sounder: _sounderRefreshTrigger,
        serviceDue: _serviceDueRefreshTrigger,
        accessCode: _accessCodeRefreshTrigger,
        panelInfo: _panelInfoRefreshTrigger,
        generalModule: _generalModuleRefreshTrigger,
      );

  @override
  void dispose() {
    _bleManager.isConnectedNotifier.removeListener(_onBleSessionChanged);
    _bleManager.handshakeCompleteNotifier.removeListener(_onBleSessionChanged);
    _scanSubscription?.cancel();
    _bluetoothService.stopScanning();
    _configLogCompareResult.dispose();
    _configLogWorking.dispose();
    _navigatingToDeviceConnecting.dispose();
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

            if (handshakeComplete &&
                !hasNavigated &&
                !maxBleConnectionRetriesReached) {
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
                  color: ColorConstants.white,
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
                            handshakeComplete && !maxBleConnectionRetriesReached
                                ? Colors.green.withValues(alpha: 0.1)
                                : ColorConstants.errorIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete && !maxBleConnectionRetriesReached
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
                    Text(
                      maxBleConnectionRetriesReached
                          ? StringConstants.maxConnectionRetriesReached
                          : handshakeComplete
                          ? 'Device Connected!'
                          : isConnected
                          ? 'Establishing secure connection...'
                          : StringConstants.establishingSecureConnection,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Subtitle
                    Text(
                      handshakeComplete && !maxBleConnectionRetriesReached
                          ? StringConstants.ready
                          : maxBleConnectionRetriesReached
                          ? StringConstants.pleaseTryConnectingAgain
                          : isConnected
                          ? StringConstants.encryptingAndAuthenticating
                          : 'Please wait while we connect to ${device.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    if (maxBleConnectionRetriesReached)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.5),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            StringConstants.ok,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.white,
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
    ble.receivedPanelName.value = "";

    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    bool dialogShown = false;

    try {
      final deviceName = widget.selectedDevice.name;
      if (deviceName.isEmpty) {
        throw Exception(StringConstants.deviceNameIsEmpty);
      }

      _showConnectingDialog(device: widget.selectedDevice, context: context);
      dialogShown = true;

      await _bluetoothService.requestPermissions();
      final poweredOn = await _bluetoothService.ensurePoweredOn();
      if (!poweredOn) {
        throw Exception(StringConstants.bluetoothIsNotEnabled);
      }

      await _bluetoothService.startScanning();

      final Completer<DiscoveredDevice?> deviceFoundCompleter =
          Completer<DiscoveredDevice?>();

      _scanSubscription = _bluetoothService.scanResultsStream.listen((results) {
        for (var result in results) {
          if (result.name == widget.panelName) {
            if (!deviceFoundCompleter.isCompleted) {
              deviceFoundCompleter.complete(result);
            }
            break;
          }
        }
      });

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

      final bleController = Get.find<BleLogController>();
      await bleController.connectToDevice(device: device);

      var activeDevice = device;

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final resolvedDevice = await resolveBootloaderModeOnConnect(
        context: context,
        bleController: bleController,
        bluetoothService: _bluetoothService,
        device: device,
      );
      if (resolvedDevice == null) {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
        return;
      }
      activeDevice = resolvedDevice;

      if (mounted) {
        setState(() {
          _selectedDevice = activeDevice;
          _isConnecting = false;
        });
      }

      widget.onDeviceReconnected?.call(activeDevice);

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

      if (!mounted) return;
      await offerOptionalFullConfigDownloadAfterConnect(
        context: context,
        isMounted: () => mounted,
        device: activeDevice,
        refreshNotifiers: _panelRefreshNotifiers,
        navigatingToDeviceConnecting: _navigatingToDeviceConnecting,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        if (dialogShown) {
          try {
            Navigator.of(context).pop();
          } catch (_) {}
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
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = false;
    _hadEstablishedBleSession =
        _bleManager.isConnectedNotifier.value &&
        _bleManager.handshakeCompleteNotifier.value;
    _bleManager.isConnectedNotifier.addListener(_onBleSessionChanged);
    _bleManager.handshakeCompleteNotifier.addListener(_onBleSessionChanged);
  }

  Future<void> _exportProjectPdf() async {
    final siteId = widget.siteId;
    var siteName = widget.siteName?.trim() ?? '';
    var installer = '-';
    var company = '-';
    var saqcc = '-';

    if (siteId != null) {
      final site = await SiteService().getSiteById(siteId);
      if (site != null) {
        siteName = site.siteName;
        installer = site.installerName;
        company = site.companyName;
        saqcc = site.saqccRegNumber;
      }
    } else if (siteName.isEmpty) {
      siteName = '-';
    }

    final bp = bleController.bleProcess;

    if (!mounted) return;
    try {
      await ProjectReportPdfUtil.generate(
        deviceId: _selectedDevice.id,
        siteName: siteName,
        installerName: installer,
        companyName: company,
        saqccNo: saqcc,
        receivedPanelName: bp.receivedPanelName.value,
        advertisedPanelName: widget.panelName,
        hardwareVersion: bp.receivedHardwareVersion.value,
        firmwareVersion: bp.receivedFirmwareVersion.value,
        firmwareDate: bp.receivedFirmwareDate.value,
        protocolVersion: bp.receivedProtocolVersion.value,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create PDF: $e')));
      }
    }
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
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
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
                              color: ColorConstants.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: ColorConstants.textDark,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            StringConstants.projectDashboard,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showExportBottomSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SvgPicture.asset(
                              "assets/svgs/share_icon.svg",
                            ),
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

  void _showExportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Export',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textBodyDark,
                ),
              ),

              const SizedBox(height: 12),

              ExportTile(
                iconPath: "assets/svgs/share_icon_red.svg",
                title: StringConstants.exportAsPDF,
                onTap: () async {
                  Navigator.pop(context);
                  _exportProjectPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showBootloaderModeDialog({required BuildContext context}) async {
    final bootloaderFileCorrupted = BleMsdUtils.isBootloaderCorrupt(
      _selectedDevice.manufacturerData,
    );
    final wantUpgrade = await showBootloaderUpgradeOfferFromDashboardDialog(
      context,
      bootloaderFileCorrupted: bootloaderFileCorrupted,
    );
    if (wantUpgrade != true || !context.mounted) return;

    final upgraded = await showFirmwareUpgradeBottomSheetForConnect(
      context: context,
      connectedDevice: _selectedDevice,
    );
    if (!upgraded || !mounted) return;

    final bleController = Get.find<BleLogController>();
    await bleController.bleManager.disconnectConnectedDevice();

    final refreshed = await runWithBleConnectingDialog<DiscoveredDevice?>(
      context: context,
      device: _selectedDevice,
      bleController: bleController,
      messages: BleConnectingDialogMessages.afterFirmwareUpgrade,
      operation:
          () => reconnectBleDeviceInAppModeAfterUpgrade(
            bleController: bleController,
            bluetoothService: _bluetoothService,
            originalDevice: _selectedDevice,
          ),
    );
    if (refreshed == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              StringConstants.deviceNotFoundAfterFirmwareUpgradePleaseReconnect,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _selectedDevice = refreshed);

    bleController.bleProcess.clearSessionAccessCode();
    final ok = await showPanelAccessCodeGatewayDialog(
      context: context,
      onStartValidation: () => bleController.startSessionAccessCodeValidation(),
    );
    if (!ok || !mounted) {
      bleController.bleManager.disconnectConnectedDevice();
    }
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
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.deviceNotConnected,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.bleDeviceIsNotConnectedTapOnConnectToConnectAgain,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.textGray,
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
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.textGray,
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
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
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
                                color: ColorConstants.white,
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
    showPanelApplySuccessDialog(
      context,
      _bleManager.bleProcess,
      message,
      subtitle: subtitle,
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
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.successBackgroundLight,
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
                  message == StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime
                      ? "Live Diagnostics Active"
                      : "$message Downloaded",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Visibility(
                  visible: !ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    message == StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime
                        ? StringConstants.theMessageHasBeenSuccessfullyDownloadedFromTheDevice
                        : 'The $message has been successfully downloaded from the device.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible: ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    StringConstants.thereWasAnErrorDownloading,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textMuted,
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
                      color: ColorConstants.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDiagnosticStopDialog(BuildContext context) {
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
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.successBackgroundLight,
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
                  StringConstants.liveDiagnosticsStopped,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  StringConstants.liveDataStreamingFromTheDeviceHasBeenStopped,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _saveAllPeripheralCachesFromBle() async {
    await PanelConfigCacheSync.saveAllFromBle(
      _bleManager,
      _selectedDevice.id,
      _panelRefreshNotifiers,
    );
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
      showDetailedConfigLogBulkBleProgressInAccessDialog: false,
      downloadSuccessMessage: StringConstants.configuration,
      onDownloadComplete: () async {
        try {
          await PanelConfigBulkSync.runConfigLogFetchRemaining(
            bleController,
            _bleManager,
          );
          _configLogCompareResult.value =
              await PanelConfigBulkSync.buildConfigCompareResultFromCache(
                _bleManager,
                _selectedDevice.id,
              );
          await _saveAllPeripheralCachesFromBle();
        } catch (e, _) {
          _configLogCompareResult.value = ConfigCompareResult.withError(
            e is TimeoutException
                ? StringConstants.operationTimedOutStayCloseToTheDeviceAndTryAgain
                : e.toString(),
          );
        }
      },
    );
  }

  Future<void> _onConfigLogUsePanelDataInApp() async {
    await _saveAllPeripheralCachesFromBle();
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
      showDetailedConfigLogBulkBleProgressInAccessDialog: false,
    );
  }

  void showConfigLogBottomSheet({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
    bool? isLBusSetup = false,
    bool? isSounderSetup = false,
    bool? isServiceDueSetup = false,
    bool? isAccessCodeSetup = false,
    bool? isPanelInfoSetup = false,
    bool? isGeneralModuleSetup = false,
    bool? isAdcSetup = false,
    bool isConfigLogBulk = false,
    bool isConfigLogBulkApply = false,
    bool showDetailedConfigLogBulkBleProgressInAccessDialog = true,
    String? mode,
    Future<void> Function()? onDownloadComplete,
    String? downloadSuccessMessage,
    Future<void> Function(BuildContext context)? onAfterApplySuccess,
  }) {
    showPanelAccessPasswordPopup(
      context: context,
      isMounted: () => mounted,
      bleManager: _bleManager,
      bleController: bleController,
      selectedDevice: _selectedDevice,
      navigatingToDeviceConnecting: _navigatingToDeviceConnecting,
      delegates: PanelAccessPasswordDelegates(
        saveExtOutCache: _saveExtOutCacheAndNotifyRefresh,
        saveInputCache: _saveInputCacheAndNotifyRefresh,
        saveRelayCache: _saveRelayCacheAndNotifyRefresh,
        saveZoneCache: _saveZoneCacheAndNotifyRefresh,
        saveRadioCache: _saveRadioCacheAndNotifyRefresh,
        saveLBusCache: _saveLBusCacheAndNotifyRefresh,
        saveSounderCache: _saveSounderCacheAndNotifyRefresh,
        saveServiceDueCache: _saveServiceDueCacheAndNotifyRefresh,
        saveAccessCodeCache: _saveAccessCodeCacheAndNotifyRefresh,
        savePanelInfoCache: _savePanelInfoCacheAndNotifyRefresh,
        saveGeneralModuleCache: _saveGeneralModuleCacheAndNotifyRefresh,
        showApplySuccess: showApplySuccessDialog,
        showDownloadSuccess: showDownloadSuccessDialog,
        openLogRetrievalLoading: (dialogContext) {
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
        },
        afterBulkApplyAccessGranted:
            (isConfigLogBulkApply && mode == 'bottomsheet_apply')
                ? () async {
                  try {
                    await PanelConfigBulkSync.runConfigLogApplyRemaining(
                      bleController,
                      _bleManager,
                    );
                    await _saveAllPeripheralCachesFromBle();
                    if (!mounted) return;
                    _configLogCompareResult.value =
                        await PanelConfigBulkSync.buildConfigCompareResultFromCache(
                          _bleManager,
                          _selectedDevice.id,
                        );
                    if (!mounted) return;
                    showApplySuccessDialog(
                      context,
                      StringConstants.configuration,
                      subtitle:
                          StringConstants.yourSavedSetupHasBeenAppliedToThePanel,
                    );
                  } finally {
                    _bleManager.bleProcess.clearPeripheralApplyDoneFlags();
                  }
                }
                : null,
      ),
      onCall: onCall,
      isExtOut: isExtOut ?? false,
      isInputSetup: isInputSetup ?? false,
      isRelaySetup: isRelaySetup ?? false,
      isZoneSetup: isZoneSetup ?? false,
      isLBusSetup: isLBusSetup ?? false,
      isSounderSetup: isSounderSetup ?? false,
      isServiceDueSetup: isServiceDueSetup ?? false,
      isAccessCodeSetup: isAccessCodeSetup ?? false,
      isPanelInfoSetup: isPanelInfoSetup ?? false,
      isGeneralModuleSetup: isGeneralModuleSetup ?? false,
      isAdcSetup: isAdcSetup ?? false,
      isConfigLogBulk: isConfigLogBulk,
      isConfigLogBulkApply: isConfigLogBulkApply,
      showDetailedConfigLogBulkBleProgressInAccessDialog:
          showDetailedConfigLogBulkBleProgressInAccessDialog,
      mode: mode,
      onDownloadComplete: onDownloadComplete,
      downloadSuccessMessage: downloadSuccessMessage,
      onAfterApplySuccess: onAfterApplySuccess,
      configLogWorking: _configLogWorking,
    );
  }

  Future<void> _showWalkTestResultConfirmation(BuildContext context) {
    return showCommissioningTestResultConfirmation(
      context: context,
      deviceId: _selectedDevice.id,
      type: CommissioningTestType.walkTest,
      manager: _bleManager,
    );
  }

  Future<void> _showRelayTestResultConfirmation(BuildContext context) {
    return showCommissioningTestResultConfirmation(
      context: context,
      deviceId: _selectedDevice.id,
      type: CommissioningTestType.relayTest,
      manager: _bleManager,
    );
  }

  Future<void> _showSounderTestResultConfirmation(BuildContext context) {
    return showCommissioningTestResultConfirmation(
      context: context,
      deviceId: _selectedDevice.id,
      type: CommissioningTestType.sounderTest,
      manager: _bleManager,
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPanelInfoHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _buildPeripheralOverview(),
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
                BleNameUtils.getDisplayIdFromBleName(widget.panelName),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.textDisabled,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              ValueListenableBuilder(
                valueListenable: ble.isConnectedNotifier,
                builder: (context, isConnected, child) {
                  if (isConnected) {
                    return Text(
                      StringConstants.connected,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.success,
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
                                  text: StringConstants.disconnected,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: ColorConstants.primary,
                                  ),
                                ),
                              ],
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

        ValueListenableBuilder(
          valueListenable: ble.isConnectedNotifier,
          builder: (context, isConnected, child) {
            if (!isConnected) {
              return _isConnecting
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.primary,
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
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Connect',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.white,
                        ),
                      ),
                    ),
                  );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeripheralOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.peripheralOverview,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        SizedBox(
          height:
              (MediaQuery.of(context).size.height +
                  MediaQuery.of(context).size.width) *
              0.2,
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: StringConstants.relays,
                iconPath: 'assets/svgs/peripheral_relay_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                peripheralName: StringConstants.inputs,
                iconPath: 'assets/svgs/peripheral_input_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                peripheralName: StringConstants.zones,
                iconPath: 'assets/svgs/peripheral_zones_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                peripheralName: StringConstants.sounders,
                iconPath: 'assets/svgs/peripheral_sounder_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                peripheralName: StringConstants.radio,
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
                isDisabled: true,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        downloadSuccessMessage: StringConstants.radio,
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
                peripheralName: StringConstants.moduleInfo,
                iconPath: 'assets/svgs/peripheral_aux_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                peripheralName: StringConstants.lBus,
                iconPath: 'assets/svgs/peripheral_l_bus_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        downloadSuccessMessage: StringConstants.lBus,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isLBusSetupApplyCommandActive.value =
                              true;
                          bleController.startLBusSetupApply();
                        },
                        isLBusSetup: true,
                        mode: 'bottomsheet_apply',
                        downloadSuccessMessage: StringConstants.lBus,
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.extOut2,
                iconPath: 'assets/svgs/peripheral_ext_out_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => DiagnosticInfoBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onStop: onStop,
          ),
    ).whenComplete(() {
      if (!mounted) return;
      ble.bleProcess.isAdcSetupFetchCommandActive.value = false;
    });
  }

  void showModuleSetupBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => WalkTestZoneBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showTestModeSounderBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => TestModeSounderBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showTestModeRelayBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => TestModeRelayBottomSheet(
            deviceId: deviceId,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  void showTestModeChoiceBottomSheet({
    required BuildContext context,
    required String deviceId,
    required VoidCallback onDownloadRelays,
    required VoidCallback onDownloadSounders,
    required VoidCallback onApplyRelays,
    required VoidCallback onApplySounders,
    required ValueNotifier<int> relayRefreshTrigger,
    required ValueNotifier<int> sounderRefreshTrigger,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder: (sheetContext) {
        return TestModeChoiceBottomSheet(
          onSounders: () {
            Navigator.pop(sheetContext);
            showTestModeSounderBottomSheet(
              context: context,
              deviceId: deviceId,
              onDownload: onDownloadSounders,
              onApply: onApplySounders,
              refreshTrigger: sounderRefreshTrigger,
            );
          },
          onRelays: () {
            Navigator.pop(sheetContext);
            showTestModeRelayBottomSheet(
              context: context,
              deviceId: deviceId,
              onDownload: onDownloadRelays,
              onApply: onApplyRelays,
              refreshTrigger: relayRefreshTrigger,
            );
          },
        );
      },
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
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
                color: ColorConstants.backgroundSubtle,
                border: Border.all(color: ColorConstants.borderMedium),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(
                    isDisabled == true
                        ? ColorConstants.textGray.withValues(alpha: 0.2)
                        : ColorConstants.primary,
                    BlendMode.srcIn,
                  ),
                  height:
                      iconPath.contains("general_module")
                          ? 36
                          : iconPath.contains("peripheral_prog_hold_icon")
                          ? 24
                          : iconPath.contains("walk_test_icon")
                          ? 32
                          : null,
                  width:
                      iconPath.contains("general_module")
                          ? 36
                          : iconPath.contains("peripheral_prog_hold_icon")
                          ? 24
                          : iconPath.contains("walk_test_icon")
                          ? 32
                          : null,
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
              color: ColorConstants.textSecondary,
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
          StringConstants.panelActions,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        SizedBox(
          height:
              (MediaQuery.of(context).size.height +
                  MediaQuery.of(context).size.width) *
              0.35,
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
                peripheralName: StringConstants.eventLog,
                iconPath: 'assets/svgs/panel_action_event_log_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      ble
                          .bleProcess
                          .isEventLogRetrievalFetchCommandActive
                          .value = true;
                      bleController.startLogRetrieval();
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.fwUpgrade,
                iconPath: 'assets/svgs/firmware_icon.svg',
                onTap: () {
                  if (!Get.isRegistered<UpdatesController>()) {
                    Get.put(UpdatesController());
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: ColorConstants.transparent,
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
                peripheralName: StringConstants.serviceDue,
                iconPath: 'assets/svgs/panel_action_service_due_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        downloadSuccessMessage: StringConstants.serviceDue,
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
                peripheralName: StringConstants.accessCode,
                iconPath: 'assets/svgs/panel_action_access_code_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        downloadSuccessMessage: StringConstants.accessCode,
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
                peripheralName: StringConstants.panelInfo,
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
                        downloadSuccessMessage: StringConstants.panelInfo,
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
                        downloadSuccessMessage: StringConstants.generalModule,
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
                peripheralName: StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
                iconPath: 'assets/svgs/diagnostic_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        downloadSuccessMessage: StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
                      );
                    },
                    onStop: () {
                      ble.bleProcess.isAdcSetupFetchCommandActive.value = false;
                      showDiagnosticStopDialog(context);
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.walkTest,
                iconPath: 'assets/svgs/walk_test_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
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
                        onAfterApplySuccess: _showWalkTestResultConfirmation,
                      );
                    },
                    refreshTrigger: _zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.configLog,
                iconPath: 'assets/svgs/panel_action_config_log_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showConfigLogBottomSheet(context: context);
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.testMode,
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog(context: context);
                    return;
                  }
                  showTestModeChoiceBottomSheet(
                    context: context,
                    deviceId: _selectedDevice.id,
                    onDownloadRelays: () {
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
                    onDownloadSounders: () {
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
                    onApplyRelays: () {
                      showPasswordPopup(
                        onCall: () {
                          ble.bleProcess.isRelaySetupCommandApplyActive.value =
                              true;
                          bleController.startRelaySetupApply();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_apply',
                        onAfterApplySuccess: _showRelayTestResultConfirmation,
                      );
                    },
                    onApplySounders: () {
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
                        onAfterApplySuccess: _showSounderTestResultConfirmation,
                      );
                    },
                    relayRefreshTrigger: _relayRefreshTrigger,
                    sounderRefreshTrigger: _sounderRefreshTrigger,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
