import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/screens/scanned_screen.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/services/panel_site_connect_flow.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/widgets/panel_access_code_dialog.dart';
import 'package:techno_switch_solar_app/widgets/bootloader_connect_flow.dart';

enum ScanType { usb, bluetooth }

class ScanningScreen extends StatefulWidget {
  final bool? isLiveEvent;
  final bool? isLiveEventLogs;
  final String? createProjectExpectedPanelType;
  final VoidCallback? onCreateProjectPanelVerified;

  const ScanningScreen({
    super.key,
    this.isLiveEvent = false,
    this.isLiveEventLogs = false,
    this.createProjectExpectedPanelType,
    this.onCreateProjectPanelVerified,
  });

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
  static const int _scanDurationSeconds = 30;
  int _remainingSeconds = _scanDurationSeconds;

  final BluetoothService _bluetoothService = BluetoothService();
  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();
  StreamSubscription? _bleResultsSub;

  late final AnimationController _sweepController;

  final Map<String, int> _assignedSlot = {};
  final Map<int, String> _slotToDevice = {};
  final Map<String, DateTime> _lastSeen = {};

  final int maxSlots = 12;
  final int staleTimeoutSeconds = 20;

  final Map<String, bool> _justAssigned = {};

  final BleManager _bleManager = Get.find<BleManager>();

  final ValueNotifier<bool> _scanAnimationsPaused = ValueNotifier(false);

  bool _bleConnectPauseApplied = false;

  void _pauseScanAnimations() {
    _scanAnimationsPaused.value = true;
    if (_sweepController.isAnimating) {
      _sweepController.stop();
    }
  }

  void _resumeScanAnimations() {
    _scanAnimationsPaused.value = false;
    if (!_sweepController.isAnimating) {
      _sweepController.repeat();
    }
  }

  Future<int?> _promptUserToPickOrCreateSite({
    required List<SiteModel> sites,
    required String panelId,
    required String panelName,
  }) async {
    if (!mounted) return null;

    if (sites.isEmpty) {
      final shouldCreate = await showDialog<bool>(
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBDEE1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.domain_add,
                        size: 32,
                        color: Color(0xFFEC1D24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create a site?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D3D3D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This panel is not associated with any site yet. Create a site to continue.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: const BorderSide(color: Color(0xFFEC1D24)),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                            _bleManager.disconnectConnectedDevice();
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEC1D24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC1D24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: Text(
                            'Create',
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
                ],
              ),
            ),
          );
        },
      );

      if (shouldCreate != true) return null;

      final createdSiteId = await Navigator.of(context).push<int?>(
        MaterialPageRoute(
          builder:
              (_) => SimpleSiteCreationScreen(
                retrievedLogs: const [],
                panelName: panelName,
                panelVersionNo: '',
                panelId: panelId,
                returnCreatedSiteId: true,
              ),
        ),
      );
      return createdSiteId;
    }

    SiteModel? selected;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        const double siteRowHeight = 64;
        const int maxVisibleSites = 3;

        final visibleCount =
            sites.length < maxVisibleSites ? sites.length : maxVisibleSites;

        final listHeight =
            visibleCount * siteRowHeight + ((visibleCount - 1) * 8);

        return StatefulBuilder(
          builder: (_, setState) {
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_city,
                          size: 32,
                          color: Color(0xFFEC1D24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a site',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the site where this panel should be assigned.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF918F8F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: listHeight.toDouble(),
                      child: ListView.separated(
                        physics:
                            sites.length > maxVisibleSites
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                        itemCount: sites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final site = sites[index];
                          final isSelected = selected?.id == site.id;

                          return GestureDetector(
                            onTap: () => setState(() => selected = site),
                            child: Container(
                              height: siteRowHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(
                                          0xFFEC1D24,
                                        ).withOpacity(0.08)
                                        : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFFEC1D24)
                                          : const Color(0xFFD0D0D0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          site.siteName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D3D3D),
                                          ),
                                        ),
                                        if (site.companyName
                                                .trim()
                                                .isNotEmpty ||
                                            site.buildingName.trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              [
                                                    site.companyName.trim(),
                                                    site.buildingName.trim(),
                                                  ]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(' • '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF918F8F),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFEC1D24),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC1D24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed:
                                selected == null
                                    ? null
                                    : () => Navigator.of(
                                      dialogContext,
                                    ).pop('select'),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop('cancel');
                                  _bleManager.disconnectConnectedDevice();
                                },
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF918F8F),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFEC1D24),
                                    width: 1.5,
                                  ),
                                  backgroundColor: const Color(
                                    0xFFEC1D24,
                                  ).withOpacity(0.04),
                                ),
                                onPressed:
                                    () => Navigator.of(
                                      dialogContext,
                                    ).pop('create'),
                                child: Text(
                                  'Create',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEC1D24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (action == 'select') return selected?.id;
    if (action == 'create') {
      final createdSiteId = await Navigator.of(context).push<int?>(
        MaterialPageRoute(
          builder:
              (_) => SimpleSiteCreationScreen(
                retrievedLogs: const [],
                panelName: panelName,
                panelVersionNo: '',
                panelId: panelId,
                returnCreatedSiteId: true,
              ),
        ),
      );
      return createdSiteId;
    }

    return null;
  }

  Future<int?> _ensureConnectedPanelHasSite({
    required DiscoveredDevice device,
  }) async {
    final bleName = device.name.trim();
    if (bleName.isEmpty) return null;

    final recoveredSiteId =
        await PanelSiteConnectFlow.tryTechnoswitchRecoveredSite(
          context: context,
          device: device,
          panelService: _panelService,
          siteService: _siteService,
        );
    if (recoveredSiteId == -1) return null;
    if (recoveredSiteId != null) return recoveredSiteId;

    try {
      final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
      var existingPanel =
          (logicalId != null
              ? await _panelService.getPanelByPanelId(logicalId)
              : null) ??
          await _panelService.getPanelByPanelId(bleName) ??
          await _panelService.getPanelByBleName(bleName);
      final existingSiteId = existingPanel?.siteId;
      if (existingSiteId != null) return existingSiteId;
    } catch (_) {}

    final sites = await _siteService.getAllSites();
    final pickedSiteId = await _promptUserToPickOrCreateSite(
      sites: sites,
      panelId: bleName,
      panelName: bleName,
    );

    if (pickedSiteId == null) return null;

    final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
    final panel =
        (logicalId != null
            ? await _panelService.getPanelByPanelId(logicalId)
            : null) ??
        await _panelService.getPanelByPanelId(bleName) ??
        await _panelService.getPanelByBleName(bleName);
    final panelIdToUse = panel?.panelId ?? logicalId ?? bleName;
    await _siteService.assignPanelToSite(
      panelIdToUse,
      pickedSiteId,
      panelName: bleName,
    );
    if (logicalId != null) {
      await _panelService.markPanelBleLinked(
        logicalId,
        macAddress: device.id,
        bleName: bleName,
        rssi: device.rssi,
      );
      await PeripheralSetupCache.migrateDeviceCache(
        fromDeviceId: logicalId,
        toDeviceId: device.id,
      );
    }
    return pickedSiteId;
  }

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
    _scanAnimationsPaused.dispose();
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

      final poweredOn = await bluetoothServiceEnsureSafe();
      if (poweredOn) {
        await _bleResultsSub?.cancel();
        _bleResultsSub = bluetoothServiceScanListener();
        try {
          await _bluetoothService.startScanning();
        } catch (_) {}
      } else {
        if (mounted) {
          _showBluetoothOffDialog(context: context);
        }
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

    _autoStopTimer = Timer(const Duration(seconds: _scanDurationSeconds), () {
      _stopScanning(false);
    });
  }

  StreamSubscription bluetoothServiceScanListener() {
    return _bluetoothService.scanResultsStream.listen((results) {
      if (mounted) _handleNewScanResults(results.cast<dynamic>());
    });
  }

  Future<bool> bluetoothServiceEnsureSafe() async {
    try {
      return await _bluetoothService.ensurePoweredOn();
    } catch (_) {
      return false;
    }
  }

  void _showBluetoothOffDialog({required BuildContext context}) {
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Turn on Bluetooth',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bluetooth is off. Please enable Bluetooth to continue scanning.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                      Navigator.of(context).pop();
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

  void _stopScanningForConnection() {
    if (mounted) setState(() => _isScanning = false);
    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();

    if (_selectedScanType == ScanType.bluetooth) {
      _bluetoothService.stopScanning();
    }
  }

  Future<void> _onDeviceSelected(DiscoveredDevice device) async {
    _bleConnectPauseApplied = false;
    _stopScanningForConnection();
    _showConnectingDialog(device: device, context: context);
    await Get.find<BleLogController>().connectToDevice(device: device);
  }

  void _stopScanning(bool isCtaButton) {
    if (mounted) setState(() => _isScanning = false);

    _scanTimer?.cancel();
    _autoStopTimer?.cancel();
    _countdownTimer?.cancel();

    if (_selectedScanType == ScanType.bluetooth) {
      _bluetoothService.stopScanning();
    }

    if (true) {
      Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        final isCreateWizard =
            widget.createProjectExpectedPanelType?.trim().isNotEmpty ?? false;

        final route = MaterialPageRoute<bool>(
          builder:
              (context) => ScannedScreen(
                discoveredDevices: _discoveredDevices,
                scanType: _selectedScanType!,
                isLiveEvent: widget.isLiveEvent,
                isLiveEventLogs: widget.isLiveEventLogs,
                createProjectExpectedPanelType:
                    widget.createProjectExpectedPanelType,
                onCreateProjectPanelVerified:
                    widget.onCreateProjectPanelVerified,
              ),
        );

        if (isCreateWizard) {
          unawaited(_openScannedForCreateWizard(route));
        } else {
          Navigator.pushReplacement(context, route);
        }
      }
    }
  }

  Future<void> _openScannedForCreateWizard(
    MaterialPageRoute<bool> route,
  ) async {
    final verified = await Navigator.of(context).push<bool>(route);
    if (!mounted) return;
    if (verified == true && widget.onCreateProjectPanelVerified == null) {
      Navigator.of(context).pop(true);
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
      resizeToAvoidBottomInset: false,
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
    const double radarSize = 340;

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
        Align(
          alignment: Alignment.center,
          child: ScanningAnimation(pausedListenable: _scanAnimationsPaused),
        ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: GestureDetector(
                onTap: () {
                  _stopScanning(true);
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
                    animation: sweepControllerProxy(),
                    builder:
                        (c, _) => CustomPaint(
                          painter: _SweepPainter(
                            progress: _sweepController.value,
                          ),
                        ),
                  ),
                ),
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
    const double cardWidth = 100;
    const double cardHeight = 130;

    final widgets = <Widget>[];

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
            highlight: justAssigned,
            child: _buildDeviceCard(device),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    final label = device.name;

    return GestureDetector(
      onTap: () => _onDeviceSelected(device),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEC1D24).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEC1D24), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(label),
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D).withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: 6),
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                width: 60,
                height: 60,
              ),
              SizedBox(height: 6),
              Expanded(
                child: Text(
                  BleNameUtils.getDisplayIdFromBleName(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Animation<double> sweepControllerProxy() => _sweepController;

  Future<void> _waitForReceivedPanelName(BleLogController bleController) async {
    const attempts = 80;
    for (var i = 0; i < attempts; i++) {
      if (bleController.bleProcess.receivedPanelName.value.trim().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _panelTypeMatchesReceived(
    String expectedPanelType,
    String receivedName,
  ) {
    final e = expectedPanelType.trim().toUpperCase();
    final r = receivedName.trim().toUpperCase();
    if (e.isEmpty || r.isEmpty) return false;
    return r.contains(e) || e.contains(r);
  }

  Future<void> _showWrongPanelTypeDialog({
    required BuildContext context,
    required String expected,
    required String received,
  }) {
    return showDialog<void>(
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wrong panel type',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This device does not match the panel type you selected ($expected). '
                  'The connected panel reported: $received.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC1D24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.5),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
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
  }

  void _showConnectingDialog({
    required DiscoveredDevice device,
    required BuildContext context,
  }) {
    final bleController = Get.find<BleLogController>();
    final connectionNotifier = bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        bleController.bleManager.handshakeCompleteNotifier;
    final maxRetriesNotifier =
        bleController.bleManager.maxBleConnectionRetriesReached;
    final networkCommFailureNotifier =
        bleController.bleProcess.communicationFailureMessage;
    final maxOtherPacketsRetriesNotifier =
        bleController.bleProcess.maxOtherPacketsRetriesReached;

    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
      maxRetriesNotifier,
      networkCommFailureNotifier,
      maxOtherPacketsRetriesNotifier,
    ]);

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: mergedListenable,
          builder: (_, __) {
            final isConnected = connectionNotifier.value;
            final handshakeComplete = handshakeCompleteNotifier.value;
            final maxRetries = maxRetriesNotifier.value;
            final networkCommMessage = networkCommFailureNotifier.value;
            final showNetworkCommError =
                networkCommMessage != null && networkCommMessage.isNotEmpty;
            final showConnectionError = maxRetries || showNetworkCommError;

            if (isConnected && !_bleConnectPauseApplied) {
              _bleConnectPauseApplied = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pauseScanAnimations();
              });
            }

            if (handshakeComplete &&
                !hasNavigated &&
                !maxRetries &&
                !showNetworkCommError) {
              hasNavigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext, rootNavigator: true).pop(true);

                await Future.delayed(const Duration(milliseconds: 150));

                if (!context.mounted) return;

                var activeDevice = device;
                final resolvedDevice = await resolveBootloaderModeOnConnect(
                  context: context,
                  bleController: bleController,
                  bluetoothService: _bluetoothService,
                  device: device,
                  onAbort: () {
                    _bleConnectPauseApplied = false;
                    if (mounted) _resumeScanAnimations();
                  },
                );
                if (resolvedDevice == null) return;
                activeDevice = resolvedDevice;

                if (widget.isLiveEvent == true) {
                  bleController.bleProcess.processDesc.value = "";
                  if (bleController.bleProcess.sessionAccessCodeReady.value &&
                      bleController.bleProcess.accessKey.value.isNotEmpty) {
                    await bleController.startLogRetrieval();
                    await Future.delayed(const Duration(seconds: 1));
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (ctx) => LogRetrievalLoadingScreen(
                              scanType: ScanType.bluetooth,
                              selectedDevice: activeDevice,
                              isLiveEvent: widget.isLiveEvent,
                            ),
                      ),
                    );
                  } else {
                    final ok = await showPanelAccessCodeLogRetrievalSheet(
                      context: context,
                      device: activeDevice,
                      isLiveEvent: widget.isLiveEvent,
                      onStartValidation:
                          () => bleController.startLogRetrieval(),
                    );
                    if (!ok) {
                      _bleConnectPauseApplied = false;
                      if (mounted) _resumeScanAnimations();
                    }
                  }
                  return;
                }

                final expectedPanel =
                    widget.createProjectExpectedPanelType?.trim() ?? '';
                if (expectedPanel.isNotEmpty) {
                  final ok = await showPanelAccessCodeGatewayDialog(
                    context: context,
                    onStartValidation:
                        () => bleController.startSessionAccessCodeValidation(),
                  );
                  if (!ok || !context.mounted) {
                    bleController.bleManager.disconnectConnectedDevice();
                    _bleConnectPauseApplied = false;
                    if (mounted) _resumeScanAnimations();
                    return;
                  }
                  await _waitForReceivedPanelName(bleController);
                  if (!context.mounted) return;
                  final received =
                      bleController.bleProcess.receivedPanelName.value.trim();
                  if (!_panelTypeMatchesReceived(expectedPanel, received)) {
                    await bleController.bleManager.disconnectConnectedDevice();
                    _bleConnectPauseApplied = false;
                    if (mounted) _resumeScanAnimations();
                    if (context.mounted) {
                      await _showWrongPanelTypeDialog(
                        context: context,
                        expected: expectedPanel,
                        received: received.isEmpty ? '-' : received,
                      );
                    }
                    return;
                  }
                  if (widget.onCreateProjectPanelVerified != null) {
                    widget.onCreateProjectPanelVerified!();
                  } else if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop(true);
                  }
                  return;
                }

                final bleNameForSiteLookup = activeDevice.name.trim();
                final preAssocPanel =
                    await _panelService.getPanelByPanelId(
                      bleNameForSiteLookup,
                    ) ??
                    await _panelService.getPanelByBleName(bleNameForSiteLookup);
                final panelHadNoSiteBeforeConnect =
                    preAssocPanel?.siteId == null;

                final siteId = await _ensureConnectedPanelHasSite(
                  device: activeDevice,
                );

                if (siteId == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No site selected. Please select or create a site.',
                        ),
                      ),
                    );
                  }
                  return;
                }

                if (!context.mounted) return;

                if (widget.isLiveEventLogs == true) {
                  Navigator.of(context, rootNavigator: true).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (_) => EventLogScreen(
                            connectedDevice: activeDevice,
                            logDataList: [],
                            panelVersionNo: activeDevice.id,
                            panelName: activeDevice.name,
                            isLiveEventLogs: widget.isLiveEventLogs,
                          ),
                    ),
                  );
                } else {
                  final ok = await showPanelAccessCodeGatewayDialog(
                    context: context,
                    onStartValidation:
                        () => bleController.startSessionAccessCodeValidation(),
                  );
                  if (!ok || !context.mounted) {
                    bleController.bleManager.disconnectConnectedDevice();
                    _bleConnectPauseApplied = false;
                    if (mounted) _resumeScanAnimations();
                    return;
                  }

                  await offerOptionalFullConfigDownloadAfterConnect(
                    context: context,
                    isMounted: () => context.mounted,
                    device: activeDevice,
                    awaitDownloadIfAccepted: true,
                    showConfigLogCompareAfterDownload: true,
                    panelHadNoSiteBeforeConnect: panelHadNoSiteBeforeConnect,
                  );
                  if (!context.mounted) return;

                  Navigator.of(context, rootNavigator: true).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (_) => ProjectDashboardScreen(
                            selectedDevice: activeDevice,
                            panelVersionNo: activeDevice.id,
                            panelName: activeDevice.name,
                            siteId: siteId,
                          ),
                    ),
                  );
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            handshakeComplete
                                ? Colors.green.withValues(alpha: 0.1)
                                : showNetworkCommError
                                ? const Color(0xFFFBDEE1)
                                : const Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete
                                ? const Icon(
                                  Icons.check_circle,
                                  size: 32,
                                  color: Colors.green,
                                )
                                : showNetworkCommError
                                ? const Icon(
                                  Icons.error_outline,
                                  size: 32,
                                  color: Color(0xFFEC1D24),
                                )
                                : Lottie.asset(
                                  'assets/jsons/ble_connecting.json',
                                  animate: !showConnectionError,
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      showNetworkCommError
                          ? 'Connection problem'
                          : maxRetries
                          ? 'Max Connection Retries Reached!'
                          : handshakeComplete
                          ? 'Device Connected!'
                          : isConnected
                          ? 'Device Connected!'
                          : 'Connecting...',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      maxRetries
                          ? 'Please scan again and reconnect.'
                          : showNetworkCommError
                          ? networkCommMessage
                          : handshakeComplete
                          ? 'Preparing dashboard...'
                          : isConnected
                          ? 'Encrypting and authenticating...'
                          : 'Please wait while we connect to ${device.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF918F8F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (showConnectionError)
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
                            if (showNetworkCommError) {
                              bleController.bleProcess
                                  .clearCommunicationFailure();
                            }
                            _bleConnectPauseApplied = false;
                            if (mounted) _resumeScanAnimations();
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop();
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
}

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
