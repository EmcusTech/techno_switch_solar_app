import 'dart:async';

import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_ui_delegate.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

abstract final class ProjectDashboardTileActions {
  static ProjectDashboardUiDelegate? _ui(ProjectDashboardController c) =>
      c.uiDelegate;

  static void openRelays(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showRelaySetupBottomSheet(
        onDownload:
            () => ui.runRelaySetupDownload(
              onDownloadComplete: c.saveRelayCacheAndNotifyRefresh,
            ),
        onApply: () => ui.runRelaySetupApply(),
        refreshTrigger: c.relayRefreshTrigger,
      );
    });
  }

  static void openInputs(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showInputSetupBottomSheet(
        onDownload:
            () => ui.runInputSetupDownload(
              onDownloadComplete: c.saveInputCacheAndNotifyRefresh,
            ),
        onApply: () => ui.runInputSetupApply(),
        refreshTrigger: c.inputRefreshTrigger,
      );
    });
  }

  static void openZones(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showZoneSetupBottomSheet(
        onDownload:
            () => ui.runZoneSetupDownload(
              onDownloadComplete: c.saveZoneCacheAndNotifyRefresh,
            ),
        onApply: () => ui.runZoneSetupApply(),
        refreshTrigger: c.zoneRefreshTrigger,
      );
    });
  }

  static void openSounders(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showSounderSetupBottomSheet(
        onDownload:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isSounderSetupFetchCommandActive.value = true;
                c.bleController.startSounderSetupFetch();
              },
              isSounderSetup: true,
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveSounderCacheAndNotifyRefresh,
              downloadSuccessMessage: 'Sounder',
            ),
        onApply:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isSounderSetupApplyCommandActive.value = true;
                c.bleController.startSounderSetupApply();
              },
              isSounderSetup: true,
              mode: 'bottomsheet_apply',
            ),
        refreshTrigger: c.sounderRefreshTrigger,
      );
    });
  }

  static void openRadio(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showRadioSetupBottomSheet(
        onDownload:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isRadioSetupFetchCommandActive.value = true;
                c.bleController.startRadioSetupFetch();
              },
              isZoneSetup: true,
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveRadioCacheAndNotifyRefresh,
              downloadSuccessMessage: StringConstants.radio,
            ),
        onApply:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isRadioSetupCommandApplyActive.value = true;
                c.bleController.startRadioSetupApply();
              },
              isZoneSetup: true,
              mode: 'bottomsheet_apply',
            ),
        refreshTrigger: c.zoneRefreshTrigger,
      );
    });
  }

  static void openModuleInfo(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showModuleSetupBottomSheet(
        onDownload:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isModuleSetupFetchCommandActive.value = true;
                c.bleController.startModuleSetupFetch();
              },
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveModuleCacheAndNotifyRefresh,
              downloadSuccessMessage: 'Module',
            ),
      );
    });
  }

  static void openLBus(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showLBusSetupBottomSheet(
        onDownload:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isLBusSetupFetchCommandActive.value = true;
                c.bleController.startLBusSetupFetch();
              },
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveLBusCacheAndNotifyRefresh,
              downloadSuccessMessage: StringConstants.lBus,
            ),
        onApply:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isLBusSetupApplyCommandActive.value = true;
                c.bleController.startLBusSetupApply();
              },
              isLBusSetup: true,
              mode: 'bottomsheet_apply',
              downloadSuccessMessage: StringConstants.lBus,
            ),
        refreshTrigger: c.zoneRefreshTrigger,
      );
    });
  }

  static void openExtOut(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showExtOutBottomSheet(
        onDownload:
            () => ui.runExtOutSetupDownload(
              onDownloadComplete: c.saveExtOutCacheAndNotifyRefresh,
            ),
        onApply: () => ui.runExtOutSetupApply(),
        refreshTrigger: c.extOutRefreshTrigger,
      );
    });
  }

  static void openEventLog(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      unawaited(_openEventLogAfterConfirm(c));
    });
  }

  static Future<void> _openEventLogAfterConfirm(
    ProjectDashboardController c,
  ) async {
    final ui = _ui(c);
    if (ui == null) return;

    final proceed = await ui.showEventLogRetrievalConfirmDialog();
    if (proceed != true) return;

    ui.showPasswordPopup(
      onCall: () {
        c.ble.bleProcess.isEventLogRetrievalFetchCommandActive.value = true;
        c.bleController.startLogRetrieval();
      },
    );
  }

  static void openFirmwareUpgrade(ProjectDashboardController c) {
    c.uiDelegate?.showFirmwareUpgradeBottomSheet();
  }

  static void openServiceDue(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showServiceDueSetupBottomSheet(
        onDownload:
            () => ui.runPanelPropertiesDownload(
              successMessage: StringConstants.serviceDue,
              progressLabel: StringConstants.downloadingServiceDue,
              markActive:
                  () =>
                      c.ble.bleProcess.isServiceDueFetchCommandActive.value =
                          true,
              start: c.bleController.startServiceDueFetch,
              onDownloadComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
            ),
        onApply:
            () => ui.runPanelPropertiesApply(
              successMessage: StringConstants.serviceDue,
              progressLabel: StringConstants.applyingServiceDue,
              markActive:
                  () =>
                      c.ble.bleProcess.isServiceDueApplyCommandActive.value =
                          true,
              start: c.bleController.startServiceDueApply,
              onApplyComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
            ),
        refreshTrigger: c.serviceDueRefreshTrigger,
      );
    });
  }

  static void openAccessCode(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showAccessCodeSetupBottomSheet(
        onDownload:
            () => ui.runAccessCodeSetupDownload(
              onDownloadComplete: c.saveAccessCodeCacheAndNotifyRefresh,
            ),
        onApply: () => ui.runAccessCodeSetupApply(),
        refreshTrigger: c.accessCodeRefreshTrigger,
      );
    });
  }

  static void openPanelInfo(ProjectDashboardController c) {
    final ui = _ui(c);
    if (ui == null) return;
    ui.showPanelInfoSetupBottomSheet(
      onDownload:
          () => ui.runPanelPropertiesDownload(
            successMessage: StringConstants.panelInfo,
            progressLabel: StringConstants.downloadingPanelInfo,
            markActive:
                () =>
                    c.ble.bleProcess.isPanelInfoSetupFetchCommandActive.value =
                        true,
            start: c.bleController.startPanelInfoSetupFetch,
            onDownloadComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
          ),
      onApply:
          () => ui.runPanelPropertiesApply(
            successMessage: StringConstants.panelInfo,
            progressLabel: StringConstants.applyingPanelInfo,
            markActive:
                () =>
                    c.ble.bleProcess.isPanelInfoSetupApplyCommandActive.value =
                        true,
            start: c.bleController.startPanelInfoSetupApply,
            onApplyComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
          ),
      refreshTrigger: c.panelInfoRefreshTrigger,
    );
  }

  static void openGeneralModule(ProjectDashboardController c) {
    final ui = _ui(c);
    if (ui == null) return;
    ui.showGeneralModuleSetupBottomSheet(
      onDownload:
          () => ui.runPanelPropertiesDownload(
            successMessage: StringConstants.generalModule,
            progressLabel: StringConstants.downloadingGeneralModule,
            markActive:
                () =>
                    c
                        .ble
                        .bleProcess
                        .isGeneralModuleSetupFetchCommandActive
                        .value = true,
            start: c.bleController.startGeneralModuleSetupFetch,
            onDownloadComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
          ),
      onApply:
          () => ui.runPanelPropertiesApply(
            successMessage: StringConstants.generalModule,
            progressLabel: StringConstants.applyingGeneralModuleTimeOut,
            markActive:
                () =>
                    c
                        .ble
                        .bleProcess
                        .isGeneralModuleSetupApplyCommandActive
                        .value = true,
            start: c.bleController.startGeneralModuleSetupApply,
            onApplyComplete: c.savePanelPropertiesCachesAndNotifyRefresh,
          ),
      refreshTrigger: c.generalModuleRefreshTrigger,
    );
  }

  static void openLiveDiagnostics(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showAdcDiagnosticsSetupBottomSheet(
        onDownload:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isAdcSetupFetchCommandActive.value = true;
                c.bleController.startAdcSetupFetch();
              },
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveModuleCacheAndNotifyRefresh,
              downloadSuccessMessage:
                  StringConstants
                      .liveDataIsBeingStreamedFromTheDeviceInRealTime,
            ),
        onStop: () {
          c.ble.bleProcess.isAdcSetupFetchCommandActive.value = false;
          ui.showDiagnosticStopDialog();
        },
      );
    });
  }

  static void openWalkTest(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showWalkTestZoneBottomSheet(
        onDownload:
            () => ui.runZoneSetupDownload(
              onDownloadComplete: c.saveZoneCacheAndNotifyRefresh,
            ),
        onApply:
            () => ui.runZoneSetupApply(
              onAfterApplySuccess: ui.showWalkTestResultConfirmation,
            ),
        refreshTrigger: c.zoneRefreshTrigger,
      );
    });
  }

  static void openConfigLog(ProjectDashboardController c) {
    c.guardBootloaderOr(() => c.uiDelegate?.showConfigLogBottomSheet());
  }

  static void openTestMode(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showTestModeChoiceBottomSheet(
        onDownloadRelays:
            () => ui.runRelaySetupDownload(
              onDownloadComplete: c.saveRelayCacheAndNotifyRefresh,
            ),
        onDownloadSounders:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isSounderSetupFetchCommandActive.value = true;
                c.bleController.startSounderSetupFetch();
              },
              isSounderSetup: true,
              mode: 'bottomsheet_download',
              onDownloadComplete: c.saveSounderCacheAndNotifyRefresh,
              downloadSuccessMessage: 'Sounder',
            ),
        onApplyRelays:
            () => ui.runRelaySetupApply(
              onAfterApplySuccess: ui.showRelayTestResultConfirmation,
            ),
        onApplySounders:
            () => ui.showPasswordPopup(
              onCall: () {
                c.ble.bleProcess.isSounderSetupApplyCommandActive.value = true;
                c.bleController.startSounderSetupApply();
              },
              isSounderSetup: true,
              mode: 'bottomsheet_apply',
              onAfterApplySuccess:
                  (_) => ui.showSounderTestResultConfirmation(),
            ),
        relayRefreshTrigger: c.relayRefreshTrigger,
        sounderRefreshTrigger: c.sounderRefreshTrigger,
      );
    });
  }
}
