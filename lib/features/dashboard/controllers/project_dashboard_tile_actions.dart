import 'dart:async';

import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_ui_delegate.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

abstract final class ProjectDashboardTileActions {
  static ProjectDashboardUiDelegate? _ui(ProjectDashboardController c) =>
      c.uiDelegate;

  static void openRelays(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showRelaySetupBottomSheet(
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isRelaySetupFetchCommandActive.value = true;
            c.bleController.startRelaySetupFetch();
          },
          isRelaySetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveRelayCacheAndNotifyRefresh,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isRelaySetupCommandApplyActive.value = true;
            c.bleController.startRelaySetupApply();
          },
          isRelaySetup: true,
          mode: 'bottomsheet_apply',
        ),
        refreshTrigger: c.relayRefreshTrigger,
      );
    });
  }

  static void openInputs(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showInputSetupBottomSheet(
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isInputSetupFetchCommandActive.value = true;
            c.bleController.startInputSetupFetch();
          },
          isInputSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveInputCacheAndNotifyRefresh,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isInputSetupApplyActive.value = true;
            c.bleController.startInputSetupApply();
          },
          isInputSetup: true,
          mode: 'bottomsheet_apply',
        ),
        refreshTrigger: c.inputRefreshTrigger,
      );
    });
  }

  static void openZones(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showZoneSetupBottomSheet(
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isZoneSetupFetchCommandActive.value = true;
            c.bleController.startZoneSetupFetch();
          },
          isZoneSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveZoneCacheAndNotifyRefresh,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isZoneSetupCommandApplyActive.value = true;
            c.bleController.startZoneSetupApply();
          },
          isZoneSetup: true,
          mode: 'bottomsheet_apply',
        ),
        refreshTrigger: c.zoneRefreshTrigger,
      );
    });
  }

  static void openSounders(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showSounderSetupBottomSheet(
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isSounderSetupFetchCommandActive.value = true;
            c.bleController.startSounderSetupFetch();
          },
          isSounderSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveSounderCacheAndNotifyRefresh,
          downloadSuccessMessage: 'Sounder',
        ),
        onApply: () => ui.showPasswordPopup(
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isRadioSetupFetchCommandActive.value = true;
            c.bleController.startRadioSetupFetch();
          },
          isZoneSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveRadioCacheAndNotifyRefresh,
          downloadSuccessMessage: StringConstants.radio,
        ),
        onApply: () => ui.showPasswordPopup(
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
        onDownload: () => ui.showPasswordPopup(
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isLBusSetupFetchCommandActive.value = true;
            c.bleController.startLBusSetupFetch();
          },
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveLBusCacheAndNotifyRefresh,
          downloadSuccessMessage: StringConstants.lBus,
        ),
        onApply: () => ui.showPasswordPopup(
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isExtOutCommandFetchActive.value = true;
            c.bleController.startExtOutFetch();
          },
          isExtOut: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveExtOutCacheAndNotifyRefresh,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isExtOutCommandApplyActive.value = true;
            c.bleController.startExtOutApply();
          },
          isExtOut: true,
          mode: 'bottomsheet_apply',
        ),
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isServiceDueFetchCommandActive.value = true;
            c.bleController.startServiceDueFetch();
          },
          isServiceDueSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveServiceDueCacheAndNotifyRefresh,
          downloadSuccessMessage: StringConstants.serviceDue,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isServiceDueApplyCommandActive.value = true;
            c.bleController.startServiceDueApply();
          },
          isServiceDueSetup: true,
          mode: 'bottomsheet_apply',
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isAccessCodeSetupFetchCommandActive.value = true;
            c.bleController.startAccessCodeSetupFetch();
          },
          isAccessCodeSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveAccessCodeCacheAndNotifyRefresh,
          downloadSuccessMessage: StringConstants.accessCode,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isAccessCodeSetupApplyCommandActive.value = true;
            c.bleController.startAccessCodeSetupApply();
          },
          isAccessCodeSetup: true,
          mode: 'bottomsheet_apply',
        ),
        refreshTrigger: c.accessCodeRefreshTrigger,
      );
    });
  }

  static void openPanelInfo(ProjectDashboardController c) {
    final ui = _ui(c);
    if (ui == null) return;
    ui.showPanelInfoSetupBottomSheet(
      onDownload: () => ui.showPasswordPopup(
        onCall: () {
          c.ble.bleProcess.isPanelInfoSetupFetchCommandActive.value = true;
          c.bleController.startPanelInfoSetupFetch();
        },
        isPanelInfoSetup: true,
        mode: 'bottomsheet_download',
        onDownloadComplete: c.savePanelInfoCacheAndNotifyRefresh,
        downloadSuccessMessage: StringConstants.panelInfo,
      ),
      onApply: () => ui.showPasswordPopup(
        onCall: () {
          c.ble.bleProcess.isPanelInfoSetupApplyCommandActive.value = true;
          c.bleController.startPanelInfoSetupApply();
        },
        isPanelInfoSetup: true,
        mode: 'bottomsheet_apply',
      ),
      refreshTrigger: c.panelInfoRefreshTrigger,
    );
  }

  static void openGeneralModule(ProjectDashboardController c) {
    final ui = _ui(c);
    if (ui == null) return;
    ui.showGeneralModuleSetupBottomSheet(
      onDownload: () => ui.showPasswordPopup(
        onCall: () {
          c.ble.bleProcess.isGeneralModuleSetupFetchCommandActive.value = true;
          c.bleController.startGeneralModuleSetupFetch();
        },
        isGeneralModuleSetup: true,
        mode: 'bottomsheet_download',
        onDownloadComplete: c.saveGeneralModuleCacheAndNotifyRefresh,
        downloadSuccessMessage: StringConstants.generalModule,
      ),
      onApply: () => ui.showPasswordPopup(
        onCall: () {
          c.ble.bleProcess.isGeneralModuleSetupApplyCommandActive.value = true;
          c.bleController.startGeneralModuleSetupApply();
        },
        isGeneralModuleSetup: true,
        mode: 'bottomsheet_apply',
      ),
      refreshTrigger: c.generalModuleRefreshTrigger,
    );
  }

  static void openLiveDiagnostics(ProjectDashboardController c) {
    c.guardBootloaderOr(() {
      final ui = _ui(c);
      if (ui == null) return;
      ui.showAdcDiagnosticsSetupBottomSheet(
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isAdcSetupFetchCommandActive.value = true;
            c.bleController.startAdcSetupFetch();
          },
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveModuleCacheAndNotifyRefresh,
          downloadSuccessMessage:
              StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
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
        onDownload: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isZoneSetupFetchCommandActive.value = true;
            c.bleController.startZoneSetupFetch();
          },
          isZoneSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveZoneCacheAndNotifyRefresh,
        ),
        onApply: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isZoneSetupCommandApplyActive.value = true;
            c.bleController.startZoneSetupApply();
          },
          isZoneSetup: true,
          mode: 'bottomsheet_apply',
          onAfterApplySuccess: (_) => ui.showWalkTestResultConfirmation(),
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
        onDownloadRelays: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isRelaySetupFetchCommandActive.value = true;
            c.bleController.startRelaySetupFetch();
          },
          isRelaySetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveRelayCacheAndNotifyRefresh,
        ),
        onDownloadSounders: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isSounderSetupFetchCommandActive.value = true;
            c.bleController.startSounderSetupFetch();
          },
          isSounderSetup: true,
          mode: 'bottomsheet_download',
          onDownloadComplete: c.saveSounderCacheAndNotifyRefresh,
          downloadSuccessMessage: 'Sounder',
        ),
        onApplyRelays: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isRelaySetupCommandApplyActive.value = true;
            c.bleController.startRelaySetupApply();
          },
          isRelaySetup: true,
          mode: 'bottomsheet_apply',
          onAfterApplySuccess: (_) => ui.showRelayTestResultConfirmation(),
        ),
        onApplySounders: () => ui.showPasswordPopup(
          onCall: () {
            c.ble.bleProcess.isSounderSetupApplyCommandActive.value = true;
            c.bleController.startSounderSetupApply();
          },
          isSounderSetup: true,
          mode: 'bottomsheet_apply',
          onAfterApplySuccess: (_) => ui.showSounderTestResultConfirmation(),
        ),
        relayRefreshTrigger: c.relayRefreshTrigger,
        sounderRefreshTrigger: c.sounderRefreshTrigger,
      );
    });
  }
}
