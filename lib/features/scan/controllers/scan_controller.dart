import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/bluetooth_service.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/ble/bootloader_connect_flow.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/panel_site_connect_flow.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:usb_serial/usb_serial.dart';

class ScanController extends GetxController {
  ScanController({required this.args});

  ScanFlowArgs args;

  ScanUiDelegate? _ui;
  ScanUiDelegate? _scanningUi;
  VoidCallback? _pauseAnimationsCallback;
  VoidCallback? _resumeAnimationsCallback;

  Timer? scanTimer;
  Timer? autoStopTimer;
  Timer? countdownTimer;
  StreamSubscription? bleResultsSub;

  List<dynamic> discoveredDevices = [];
  bool isScanning = false;
  ScanType? selectedScanType;
  int remainingSeconds = scanDurationSeconds;
  bool transitioningToScanned = false;
  bool bleConnectPauseApplied = false;

  static const int scanDurationSeconds = 30;
  static const int maxSlots = 12;
  static const int staleTimeoutSeconds = 20;

  final BluetoothService bluetoothService = BluetoothService();
  final PanelService panelService = PanelService();
  final SiteService siteService = SiteService();

  final Map<String, int> assignedSlot = {};
  final Map<int, String> slotToDevice = {};
  final Map<String, DateTime> lastSeen = {};
  final Map<String, bool> justAssigned = {};

  late final BleManager bleManager;
  late final BleLogController bleLogController;

  bool get isLiveEvent => args.isLiveEvent;
  bool get isLiveEventLogs => args.isLiveEventLogs;
  String? get createProjectExpectedPanelType => args.createProjectExpectedPanelType;
  VoidCallback? get onCreateProjectPanelVerified =>
      args.onCreateProjectPanelVerified;
  ScanFlowMode get flowMode => args.mode;

  void attachUi(ScanUiDelegate ui) {
    _ui = ui;
  }

  void attachScanningUi(ScanUiDelegate ui) {
    _scanningUi = ui;
    _ui = ui;
  }

  void restoreScanningUi() {
    _ui = _scanningUi;
  }

  void detachUi() {
    _ui = null;
  }

  void setAnimationCallbacks({
    VoidCallback? pause,
    VoidCallback? resume,
  }) {
    _pauseAnimationsCallback = pause;
    _resumeAnimationsCallback = resume;
  }

  @override
  void onInit() {
    super.onInit();
    bleManager = Get.find<BleManager>();
    bleLogController = Get.find<BleLogController>();

    if (args.mode == ScanFlowMode.scanned) {
      discoveredDevices = List<dynamic>.from(args.discoveredDevices);
      selectedScanType = args.scanType;
      isScanning = false;
    }
  }

  @override
  void onClose() {
    scanTimer?.cancel();
    autoStopTimer?.cancel();
    countdownTimer?.cancel();
    bleResultsSub?.cancel();
    bluetoothService.dispose();
    super.onClose();
  }

  Future<void> startScanning(ScanType scanType) async {
    selectedScanType = scanType;
    isScanning = true;
    remainingSeconds = scanDurationSeconds;
    update();

    await requestPermissions(scanType);

    if (scanType == ScanType.bluetooth) {
      try {
        await bluetoothService.requestPermissions();
      } catch (_) {}

      final poweredOn = await bluetoothServiceEnsureSafe();
      if (poweredOn) {
        await bleResultsSub?.cancel();
        bleResultsSub = bluetoothServiceScanListener();
        try {
          await bluetoothService.startScanning();
        } catch (_) {}
      } else {
        _ui?.showBluetoothOffDialog();
      }
    }

    if (scanType == ScanType.usb) {
      scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (isScanning) await scanForDevices();
      });
    }

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        update();
      } else {
        timer.cancel();
      }
    });

    autoStopTimer = Timer(const Duration(seconds: scanDurationSeconds), () {
      stopScanning(false);
    });
  }

  StreamSubscription bluetoothServiceScanListener() {
    return bluetoothService.scanResultsStream.listen((results) {
      if (_ui?.isMounted ?? false) {
        handleNewScanResults(results.cast<dynamic>());
      }
    });
  }

  Future<bool> bluetoothServiceEnsureSafe() async {
    try {
      return await bluetoothService.ensurePoweredOn();
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermissions(ScanType scanType) async {
    if (scanType == ScanType.usb) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> scanForDevices() async {
    try {
      if (selectedScanType == ScanType.usb) {
        final devices = await UsbSerial.listDevices();
        if (_ui?.isMounted ?? false) {
          handleNewScanResults(devices.cast<dynamic>());
        }
      }
    } catch (_) {}
  }

  String? computeStableKey(dynamic device) {
    try {
      if (device == null) return null;

      if (device is Map) {
        final map = device;
        final candidates = <String?>[
          map['address']?.toString(),
          map['id']?.toString(),
          map[StringConstants.deviceid]?.toString(),
          map['mac']?.toString(),
          map['uuid']?.toString(),
          map[StringConstants.peripheralid]?.toString(),
        ];
        for (var c in candidates) {
          if (c != null && c.isNotEmpty) return 'field:$c';
        }
        if (map.containsKey(StringConstants.advertisementdata)) {
          final ad = map[StringConstants.advertisementdata];
          try {
            if (ad is Map && ad.containsKey(StringConstants.manufacturerdata)) {
              final manu = ad[StringConstants.manufacturerdata];
              if (manu != null) {
                final hex = bytesToHex(manu);
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
            final hex = bytesToHex(manu);
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
          final h = simpleHash(full);
          return 'ts:$h';
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  String bytesToHex(dynamic b) {
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

  int simpleHash(String s) {
    int h = 0;
    for (int i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }

  int? findFreeSlot() {
    for (int i = 0; i < maxSlots; i++) {
      if (!slotToDevice.containsKey(i)) return i;
    }
    return null;
  }

  int hashToSlot(String key) {
    final h = simpleHash(key);
    return h % maxSlots;
  }

  void handleNewScanResults(List<dynamic> results) {
    final Map<String, dynamic> keyToDevice = {};

    for (var d in results) {
      final key = computeStableKey(d);
      if (key == null) continue;
      keyToDevice[key] = d;
      lastSeen[key] = DateTime.now();

      if (!assignedSlot.containsKey(key)) {
        final free = findFreeSlot();
        if (free != null) {
          assignedSlot[key] = free;
          slotToDevice[free] = key;
          justAssigned[key] = true;
          Timer(const Duration(milliseconds: 900), () {
            if (_ui?.isMounted ?? false) {
              justAssigned.remove(key);
              update();
            }
          });
        } else {
          final fallback = hashToSlot(key);
          assignedSlot[key] = fallback;
          slotToDevice[fallback] = key;
          justAssigned[key] = true;
          Timer(const Duration(milliseconds: 900), () {
            if (_ui?.isMounted ?? false) {
              justAssigned.remove(key);
              update();
            }
          });
        }
      }
    }

    final cutoff = DateTime.now().subtract(
      Duration(seconds: staleTimeoutSeconds),
    );
    final stale =
        lastSeen.entries
            .where((e) => e.value.isBefore(cutoff))
            .map((e) => e.key)
            .toList();
    for (var sid in stale) {
      final slot = assignedSlot.remove(sid);
      if (slot != null) slotToDevice.remove(slot);
      lastSeen.remove(sid);
      justAssigned.remove(sid);
    }

    final Map<int, dynamic> devicesBySlot = {};
    for (var entry in keyToDevice.entries) {
      final k = entry.key;
      final dev = entry.value;
      final slot = assignedSlot[k];
      if (slot != null) devicesBySlot[slot] = dev;
    }

    if (_ui?.isMounted ?? false) {
      final slots = devicesBySlot.keys.toList()..sort();
      discoveredDevices = slots.map((s) => devicesBySlot[s]!).toList();
      update();
    }
  }

  String? deviceKeyByObject(dynamic device) {
    return computeStableKey(device);
  }

  DiscoveredDevice? deviceForKey(String deviceKey) {
    for (final device in discoveredDevices) {
      if (device is DiscoveredDevice && computeStableKey(device) == deviceKey) {
        return device;
      }
    }
    return null;
  }

  void stopScanningForConnection() {
    if (_ui?.isMounted ?? false) {
      isScanning = false;
      update();
    }
    scanTimer?.cancel();
    autoStopTimer?.cancel();
    countdownTimer?.cancel();

    if (selectedScanType == ScanType.bluetooth) {
      bluetoothService.stopScanning();
    }
  }

  void stopScanning(bool isCtaButton) {
    if (_ui?.isMounted ?? false) {
      isScanning = false;
      update();
    }

    scanTimer?.cancel();
    autoStopTimer?.cancel();
    countdownTimer?.cancel();

    if (selectedScanType == ScanType.bluetooth) {
      bluetoothService.stopScanning();
    }

    Future.delayed(const Duration(milliseconds: 300));

    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final isCreateWizard =
        createProjectExpectedPanelType?.trim().isNotEmpty ?? false;

    if (isCreateWizard) {
      unawaited(_openScannedForCreateWizard());
    } else {
      transitionToScannedScreen();
    }
  }

  Future<void> _openScannedForCreateWizard() async {
    final ui = _ui;
    if (ui == null) return;

    transitioningToScanned = true;
    args = args.copyWith(
      mode: ScanFlowMode.scanned,
      discoveredDevices: discoveredDevices,
      scanType: selectedScanType,
    );

    final verified = await ui.pushScannedScreen();
    transitioningToScanned = false;
    restoreScanningUi();

    if (!ui.isMounted) return;
    if (verified == true && onCreateProjectPanelVerified == null) {
      ui.popWithResult(true);
    }
  }

  void transitionToScannedScreen() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    transitioningToScanned = true;
    args = args.copyWith(
      mode: ScanFlowMode.scanned,
      discoveredDevices: discoveredDevices,
      scanType: selectedScanType,
    );
    ui.replaceWithScannedScreen();
  }

  Future<void> openScanAgain() async {
    final ui = _ui;
    if (ui == null) return;

    await ui.openScanAgain(
      scanningArgs: ScanFlowArgs.scanning(
        isLiveEvent: isLiveEvent,
        isLiveEventLogs: isLiveEventLogs,
        createProjectExpectedPanelType: createProjectExpectedPanelType,
        onCreateProjectPanelVerified: onCreateProjectPanelVerified,
      ),
    );
  }

  void exitScanning() {
    bleResultsSub?.cancel();
    bluetoothService.stopScanning();
    _ui?.popScreen();
  }

  Future<void> onDeviceSelected(
    DiscoveredDevice device, {
    bool isScanningConnectFlow = false,
  }) async {
    bleConnectPauseApplied = false;
    stopScanningForConnection();
    _ui?.showConnectingDialog(
      device,
      onPauseAnimations: isScanningConnectFlow ? _pauseAnimationsCallback : null,
      onResumeAnimations: isScanningConnectFlow ? _resumeAnimationsCallback : null,
      isScanningConnectFlow: isScanningConnectFlow,
    );
    await bleLogController.connectToDevice(device: device);
  }

  Future<int?> ensureConnectedPanelHasSite({
    required DiscoveredDevice device,
  }) async {
    final ui = _ui;
    if (ui == null) return null;

    final bleName = device.name.trim();
    if (bleName.isEmpty) return null;

    final recoveredSiteId =
        await PanelSiteConnectFlow.tryTechnoswitchRecoveredSite(
          context: ui.uiContext,
          device: device,
          panelService: panelService,
          siteService: siteService,
        );
    if (recoveredSiteId == -1) return null;
    if (recoveredSiteId != null) return recoveredSiteId;

    try {
      final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
      var existingPanel =
          (logicalId != null
              ? await panelService.getPanelByPanelId(logicalId)
              : null) ??
          await panelService.getPanelByPanelId(bleName) ??
          await panelService.getPanelByBleName(bleName);
      final existingSiteId = existingPanel?.siteId;
      if (existingSiteId != null) return existingSiteId;
    } catch (_) {}

    final sites = await siteService.getAllSites();
    final pickedSiteId = await ui.promptUserToPickOrCreateSite(
      sites: sites,
      panelId: bleName,
      panelName: bleName,
    );

    if (pickedSiteId == null) return null;

    final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
    final panel =
        (logicalId != null
            ? await panelService.getPanelByPanelId(logicalId)
            : null) ??
        await panelService.getPanelByPanelId(bleName) ??
        await panelService.getPanelByBleName(bleName);
    final panelIdToUse = panel?.panelId ?? logicalId ?? bleName;
    await siteService.assignPanelToSite(
      panelIdToUse,
      pickedSiteId,
      panelName: bleName,
    );
    if (logicalId != null) {
      await panelService.markPanelBleLinked(
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

  Future<void> waitForReceivedPanelName() async {
    const attempts = 80;
    for (var i = 0; i < attempts; i++) {
      if (bleLogController.bleProcess.receivedPanelName.value
          .trim()
          .isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  bool panelTypeMatchesReceived(
    String expectedPanelType,
    String receivedName,
  ) {
    final e = expectedPanelType.trim().toUpperCase();
    final r = receivedName.trim().toUpperCase();
    if (e.isEmpty || r.isEmpty) return false;
    return r.contains(e) || e.contains(r);
  }

  void resumeScanAnimationsIfNeeded() {
    bleConnectPauseApplied = false;
    _resumeAnimationsCallback?.call();
  }

  Future<void> handlePostConnectRouting({
    required DiscoveredDevice device,
    VoidCallback? onResumeAnimations,
    bool resolveBootloader = true,
  }) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    var activeDevice = device;
    if (resolveBootloader && selectedScanType == ScanType.bluetooth) {
      final resolvedDevice = await resolveBootloaderModeOnConnect(
        context: ui.uiContext,
        bleController: bleLogController,
        bluetoothService: bluetoothService,
        device: device,
        onAbort: onResumeAnimations,
      );
      if (resolvedDevice == null) return;
      activeDevice = resolvedDevice;
    }

    if (isLiveEvent) {
      bleLogController.bleProcess.processDesc.value = '';
      if (bleLogController.bleProcess.sessionAccessCodeReady.value &&
          bleLogController.bleProcess.accessKey.value.isNotEmpty) {
        await bleLogController.startLogRetrieval();
        await Future.delayed(const Duration(seconds: 1));
        if (!ui.isMounted) return;
        ui.navigateToLogRetrievalLoading(
          args: LogFlowArgs.loading(
            selectedDevice: activeDevice,
            scanType: ScanType.bluetooth,
            isLiveEvent: isLiveEvent,
          ),
        );
      } else {
        final ok = await ui.showPanelAccessCodeLogRetrievalSheet(
          device: activeDevice,
          isLiveEvent: isLiveEvent,
          onStartValidation: () => bleLogController.startLogRetrieval(),
        );
        if (!ok) {
          onResumeAnimations?.call();
          bleConnectPauseApplied = false;
        }
      }
      return;
    }

    final expectedPanel = createProjectExpectedPanelType?.trim() ?? '';
    if (expectedPanel.isNotEmpty) {
      final ok = await ui.showPanelAccessCodeGatewayDialog(
        onStartValidation:
            () => bleLogController.startSessionAccessCodeValidation(),
      );
      if (!ok || !ui.isMounted) {
        bleLogController.bleManager.disconnectConnectedDevice();
        onResumeAnimations?.call();
        bleConnectPauseApplied = false;
        return;
      }
      await waitForReceivedPanelName();
      if (!ui.isMounted) return;
      final received =
          bleLogController.bleProcess.receivedPanelName.value.trim();
      if (!panelTypeMatchesReceived(expectedPanel, received)) {
        await bleLogController.bleManager.disconnectConnectedDevice();
        onResumeAnimations?.call();
        bleConnectPauseApplied = false;
        if (ui.isMounted) {
          await ui.showWrongPanelTypeDialog(
            expected: expectedPanel,
            received: received.isEmpty ? '-' : received,
          );
        }
        return;
      }
      if (onCreateProjectPanelVerified != null) {
        onCreateProjectPanelVerified!();
      } else {
        ui.popWithResult(true);
      }
      return;
    }

    final bleNameForSiteLookup = activeDevice.name.trim();
    final preAssocPanel =
        await panelService.getPanelByPanelId(bleNameForSiteLookup) ??
        await panelService.getPanelByBleName(bleNameForSiteLookup);
    final panelHadNoSiteBeforeConnect = preAssocPanel?.siteId == null;

    final siteId = await ensureConnectedPanelHasSite(device: activeDevice);

    if (siteId == null) {
      if (ui.isMounted) {
        ui.showSnackBar(
          StringConstants.noSiteSelectedPleaseSelectOrCreateASite,
        );
      }
      return;
    }

    if (!ui.isMounted) return;

    if (isLiveEventLogs) {
      ui.navigateToEventLog(
        args: LogFlowArgs.eventLog(
          logDataList: [],
          panelVersionNo: activeDevice.id,
          panelName: activeDevice.name,
          connectedDevice: activeDevice,
          isLiveEventLogs: true,
        ),
      );
    } else {
      final ok = await ui.showPanelAccessCodeGatewayDialog(
        onStartValidation:
            () => bleLogController.startSessionAccessCodeValidation(),
      );
      if (!ok || !ui.isMounted) {
        bleLogController.bleManager.disconnectConnectedDevice();
        onResumeAnimations?.call();
        bleConnectPauseApplied = false;
        return;
      }

      await ui.offerOptionalFullConfigDownloadAfterConnect(
        device: activeDevice,
        panelHadNoSiteBeforeConnect: panelHadNoSiteBeforeConnect,
      );
      if (!ui.isMounted) return;

      ui.navigateToProjectDashboard(
        args: ProjectDashboardArgs(
          panelVersionNo: activeDevice.id,
          panelName: activeDevice.name,
          selectedDevice: activeDevice,
          siteId: siteId,
        ),
      );
    }
  }
}
