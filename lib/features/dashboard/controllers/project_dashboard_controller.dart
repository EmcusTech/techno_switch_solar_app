import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/bluetooth_service.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/pdf/project_report_pdf_util.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

class ProjectDashboardController extends GetxController {
  ProjectDashboardController({required this.args});

  final ProjectDashboardArgs args;

  ProjectDashboardUiDelegate? _ui;

  late final BleManager bleManager;
  late final BleLogController bleController;
  final BluetoothService bluetoothService = BluetoothService();

  String get panelVersionNo => args.panelVersionNo;
  String get panelName => args.panelName;
  int? get siteId => args.siteId;
  String? get siteName => args.siteName;

  late DiscoveredDevice selectedDevice;
  int selectedIndex = 0;
  bool isConnecting = false;
  bool hadEstablishedBleSession = false;
  bool suppressUnexpectedBleDisconnectUi = false;
  bool isUnexpectedDisconnectDialogOpen = false;

  StreamSubscription? scanSubscription;

  final ValueNotifier<bool> navigatingToDeviceConnecting = ValueNotifier(false);
  final ValueNotifier<int> relayRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> inputRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> zoneRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> extOutRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> sounderRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> serviceDueRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> accessCodeRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> panelInfoRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<int> generalModuleRefreshTrigger = ValueNotifier(0);
  final ValueNotifier<ConfigCompareResult?> configLogCompareResult =
      ValueNotifier(null);
  final ValueNotifier<bool> configLogWorking = ValueNotifier(false);
  final ValueNotifier<int> logHistoryRefreshTrigger = ValueNotifier(0);

  late final PanelConfigRefreshNotifiers panelRefreshNotifiers;

  BleManager get ble => bleManager;

  void attachUi(ProjectDashboardUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  void setSelectedIndex(int index) {
    if (index == 1 || index == 2) return;
    selectedIndex = index;
    update();
  }

  void onLogsSavedToSite() {
    logHistoryRefreshTrigger.value++;
    update();
  }

  void updateSelectedDevice(DiscoveredDevice device) {
    selectedDevice = device;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    selectedDevice = args.selectedDevice;
    bleManager = Get.find<BleManager>();
    bleController = Get.find<BleLogController>();
    panelRefreshNotifiers = PanelConfigRefreshNotifiers(
      relay: relayRefreshTrigger,
      input: inputRefreshTrigger,
      zone: zoneRefreshTrigger,
      extOut: extOutRefreshTrigger,
      sounder: sounderRefreshTrigger,
      serviceDue: serviceDueRefreshTrigger,
      accessCode: accessCodeRefreshTrigger,
      panelInfo: panelInfoRefreshTrigger,
      generalModule: generalModuleRefreshTrigger,
    );
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = false;
    hadEstablishedBleSession =
        bleManager.isConnectedNotifier.value &&
        bleManager.handshakeCompleteNotifier.value;
    bleManager.isConnectedNotifier.addListener(onBleSessionChanged);
    bleManager.handshakeCompleteNotifier.addListener(onBleSessionChanged);
  }

  @override
  void onClose() {
    bleManager.isConnectedNotifier.removeListener(onBleSessionChanged);
    bleManager.handshakeCompleteNotifier.removeListener(onBleSessionChanged);
    scanSubscription?.cancel();
    bluetoothService.stopScanning();
    configLogCompareResult.dispose();
    configLogWorking.dispose();
    navigatingToDeviceConnecting.dispose();
    relayRefreshTrigger.dispose();
    inputRefreshTrigger.dispose();
    zoneRefreshTrigger.dispose();
    extOutRefreshTrigger.dispose();
    sounderRefreshTrigger.dispose();
    serviceDueRefreshTrigger.dispose();
    accessCodeRefreshTrigger.dispose();
    panelInfoRefreshTrigger.dispose();
    generalModuleRefreshTrigger.dispose();
    logHistoryRefreshTrigger.dispose();
    super.onClose();
  }

  void onBleSessionChanged() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final connected = bleManager.isConnectedNotifier.value;
    final handshakeComplete = bleManager.handshakeCompleteNotifier.value;
    final sessionActive = connected && handshakeComplete;
    final connectInProgress = isConnecting || bleManager.isConnectInProgress;

    if (sessionActive && isUnexpectedDisconnectDialogOpen) {
      isUnexpectedDisconnectDialogOpen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_ui?.isMounted != true) return;
        _ui!.dismissRootNavigatorIfCanPop();
      });
    }

    if (sessionActive) {
      hadEstablishedBleSession = true;
    }

    final lostEstablishedSession =
        hadEstablishedBleSession && !sessionActive && !connectInProgress;

    if (lostEstablishedSession) {
      hadEstablishedBleSession = false;

      final suppressForFirmware =
          BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value;

      if (!suppressForFirmware) {
        ui.closeModalOverlaysAboveDashboard();

        if (suppressUnexpectedBleDisconnectUi) {
          suppressUnexpectedBleDisconnectUi = false;
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_ui?.isMounted != true) return;
            isUnexpectedDisconnectDialogOpen = true;
            _ui!.showUnexpectedBleDisconnectDialog();
          });
        }
      } else if (suppressUnexpectedBleDisconnectUi) {
        suppressUnexpectedBleDisconnectUi = false;
      }
    }
  }

  Future<bool> confirmAndDisconnect() async {
    final ui = _ui;
    if (ui == null) return false;

    final shouldDisconnect = await ui.showDisconnectConfirmDialog();

    if (shouldDisconnect == true) {
      if (bleManager.isConnected) {
        suppressUnexpectedBleDisconnectUi = true;
        hadEstablishedBleSession = false;
        await bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  Future<void> handleBackNavigation() async {
    final ui = _ui;
    if (ui == null) return;

    if (bleController.isConnected) {
      final shouldPop = await confirmAndDisconnect();
      if (shouldPop && ui.isMounted) {
        ui.popScreen();
      }
    } else {
      ui.popScreen();
    }
  }

  Future<bool> handleWillPop() async {
    if (bleController.isConnected) {
      return confirmAndDisconnect();
    }
    return true;
  }

  Future<void> connectToDeviceByName() async {
    final ui = _ui;
    if (ui == null || isConnecting) return;

    bleManager.receivedPanelName.value = '';
    isConnecting = true;
    update();

    var dialogShown = false;

    try {
      final deviceName = selectedDevice.name;
      if (deviceName.isEmpty) {
        throw Exception(StringConstants.deviceNameIsEmpty);
      }

      ui.showConnectingDialog(selectedDevice);
      dialogShown = true;

      await bluetoothService.requestPermissions();
      final poweredOn = await bluetoothService.ensurePoweredOn();
      if (!poweredOn) {
        throw Exception(StringConstants.bluetoothIsNotEnabled);
      }

      await bluetoothService.startScanning();

      final deviceFoundCompleter = Completer<DiscoveredDevice?>();

      scanSubscription = bluetoothService.scanResultsStream.listen((results) {
        for (final result in results) {
          if (result.name == panelName) {
            if (!deviceFoundCompleter.isCompleted) {
              deviceFoundCompleter.complete(result);
            }
            break;
          }
        }
      });

      final device = await deviceFoundCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      await scanSubscription?.cancel();
      await bluetoothService.stopScanning();

      if (device == null) {
        throw Exception('Device "$deviceName" not found');
      }

      await bleController.connectToDevice(device: device);

      var activeDevice = device;

      await Future.delayed(const Duration(milliseconds: 600));
      if (_ui?.isMounted != true) return;

      final resolvedDevice = await ui.resolveBootloaderOnConnect(device);
      if (resolvedDevice == null) {
        isConnecting = false;
        update();
        return;
      }
      activeDevice = resolvedDevice;

      updateSelectedDevice(activeDevice);
      isConnecting = false;
      update();

      if (_ui?.isMounted != true) return;

      bleController.bleProcess.clearSessionAccessCode();
      final ok = await ui.showPanelAccessCodeGatewayDialog(
        onStartValidation: bleController.startSessionAccessCodeValidation,
      );

      if (!ok || _ui?.isMounted != true) {
        bleController.bleManager.disconnectConnectedDevice();
        return;
      }

      if (_ui?.isMounted != true) return;
      await ui.offerOptionalFullConfigDownload(activeDevice);
    } catch (e) {
      isConnecting = false;
      update();
      if (dialogShown && _ui?.isMounted == true) {
        ui.popTopDialogIfMounted();
      }
      if (_ui?.isMounted == true) {
        ui.showSnackBar(
          '${StringConstants.failedToConnectPrefix}$e',
          backgroundColor: Colors.red,
        );
      }
      await scanSubscription?.cancel();
      await bluetoothService.stopScanning();
    }
  }

  Future<void> exportProjectPdf() async {
    final ui = _ui;
    if (ui == null) return;

    final resolvedSiteId = siteId;
    var resolvedSiteName = siteName?.trim() ?? '';
    var installer = '-';
    var company = '-';
    var saqcc = '-';

    if (resolvedSiteId != null) {
      final site = await SiteService().getSiteById(resolvedSiteId);
      if (site != null) {
        resolvedSiteName = site.siteName;
        installer = site.installerName;
        company = site.companyName;
        saqcc = site.saqccRegNumber;
      }
    } else if (resolvedSiteName.isEmpty) {
      resolvedSiteName = '-';
    }

    final bp = bleController.bleProcess;

    if (_ui?.isMounted != true) return;
    try {
      await ProjectReportPdfUtil.generate(
        deviceId: selectedDevice.id,
        siteName: resolvedSiteName,
        installerName: installer,
        companyName: company,
        saqccNo: saqcc,
        receivedPanelName: bp.receivedPanelName.value,
        advertisedPanelName: panelName,
        hardwareVersion: bp.receivedHardwareVersion.value,
        firmwareVersion: bp.receivedFirmwareVersion.value,
        firmwareDate: bp.receivedFirmwareDate.value,
        protocolVersion: bp.receivedProtocolVersion.value,
      );
    } catch (e) {
      if (_ui?.isMounted == true) {
        ui.showSnackBar('${StringConstants.couldNotCreatePdfPrefix}$e');
      }
    }
  }

  Future<void> saveAllPeripheralCachesFromBle() async {
    await PanelConfigCacheSync.saveAllFromBle(
      bleManager,
      selectedDevice.id,
      panelRefreshNotifiers,
    );
  }

  void onConfigLogDownloadAndCompare() {
    configLogCompareResult.value = null;
    _ui?.showConfigLogPasswordPopup(
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
            bleManager,
          );
          configLogCompareResult.value =
              await PanelConfigBulkSync.buildConfigCompareResultFromCache(
                bleManager,
                selectedDevice.id,
              );
          await saveAllPeripheralCachesFromBle();
        } catch (e, _) {
          configLogCompareResult.value = ConfigCompareResult.withError(
            e is TimeoutException
                ? StringConstants
                    .operationTimedOutStayCloseToTheDeviceAndTryAgain
                : e.toString(),
          );
        }
      },
    );
  }

  Future<void> onConfigLogUsePanelDataInApp() async {
    await saveAllPeripheralCachesFromBle();
  }

  void onConfigLogApplyLocalToPanel() {
    _ui?.showConfigLogPasswordPopup(
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

  void clearConfigLogState() {
    configLogCompareResult.value = null;
    configLogWorking.value = false;
  }

  Future<void> saveRelayCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveRelaySetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.relayMap(bleManager),
    );
    relayRefreshTrigger.value++;
  }

  Future<void> saveInputCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveInputSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.inputMap(bleManager),
    );
    inputRefreshTrigger.value++;
  }

  Future<void> saveZoneCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveZoneSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.zoneMap(bleManager),
    );
    zoneRefreshTrigger.value++;
  }

  Future<void> saveExtOutCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveExtOutSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.extOutMap(bleManager),
    );
    extOutRefreshTrigger.value++;
  }

  Future<void> saveSounderCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveSounderSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.sounderMap(bleManager),
    );
    sounderRefreshTrigger.value++;
  }

  Future<void> saveServiceDueCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveServiceDueSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.serviceDueMap(bleManager),
    );
    serviceDueRefreshTrigger.value++;
  }

  Future<void> saveRadioCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveRadioSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.radioMap(bleManager),
    );
    zoneRefreshTrigger.value++;
  }

  Future<void> saveModuleCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveModuleSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.moduleMap(bleManager),
    );
  }

  Future<void> saveLBusCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveLBusSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.lBusList(bleManager),
    );
    zoneRefreshTrigger.value++;
  }

  Future<void> saveAccessCodeCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveAccessCodeSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.accessCodeList(bleManager),
    );
    accessCodeRefreshTrigger.value++;
  }

  Future<void> savePanelInfoCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.savePanelInfoSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.panelInfoMap(bleManager),
    );
    panelInfoRefreshTrigger.value++;
  }

  Future<void> saveGeneralModuleCacheAndNotifyRefresh() async {
    await PeripheralSetupCache.saveGeneralModuleSetup(
      selectedDevice.id,
      PeripheralConfigSnapshot.generalModuleMap(bleManager),
    );
    generalModuleRefreshTrigger.value++;
  }

  Future<void> onPeripheralTileTap(VoidCallback? onTap) async {
    if (!bleController.isConnected) {
      await _ui?.showBluetoothOffDialog();
    } else {
      ble.bleProcess.processDesc.value = '';
      onTap?.call();
    }
  }

  void markUnexpectedDisconnectDialogClosed() {
    isUnexpectedDisconnectDialogOpen = false;
  }
}
