import 'package:Technoswitch/ble/demo/demo_ble.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_tile_actions.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_peripheral_tile.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

abstract final class WindowsDashboardTileRegistry {
  static List<WindowsDashboardTileConfig> overviewTiles(
    ProjectDashboardController controller,
  ) {
    return [
      WindowsDashboardTileConfig(
        label: StringConstants.relays,
        iconPath: AssetConstants.peripheralRelayIcon,
        onTap: () => ProjectDashboardTileActions.openRelays(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.inputs,
        iconPath: AssetConstants.peripheralInputIcon,
        onTap: () => ProjectDashboardTileActions.openInputs(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.zones,
        iconPath: AssetConstants.peripheralZonesIcon,
        onTap: () => ProjectDashboardTileActions.openZones(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.sounders,
        iconPath: AssetConstants.peripheralSounderIcon,
        isDisabled: !DemoBle.enabled,
        onTap: () => ProjectDashboardTileActions.openSounders(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.radio,
        iconPath: AssetConstants.peripheralProgHoldIcon,
        isDisabled: !DemoBle.enabled,
        iconHeight: 24,
        iconWidth: 24,
        onTap: () => ProjectDashboardTileActions.openRadio(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.moduleInfo,
        iconPath: AssetConstants.peripheralAuxIcon,
        isDisabled: !DemoBle.enabled,
        onTap: () => ProjectDashboardTileActions.openModuleInfo(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.lBus,
        iconPath: AssetConstants.peripheralLBusIcon,
        isDisabled: !DemoBle.enabled,
        onTap: () => ProjectDashboardTileActions.openLBus(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.extOut2,
        iconPath: AssetConstants.peripheralExtOutIcon,
        isDisabled: !DemoBle.enabled,
        onTap: () => ProjectDashboardTileActions.openExtOut(controller),
      ),
    ];
  }

  static List<WindowsDashboardTileConfig> panelActionTiles(
    ProjectDashboardController controller,
  ) {
    return [
      WindowsDashboardTileConfig(
        label: StringConstants.eventLog,
        iconPath: AssetConstants.panelActionEventLogIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openEventLog(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.fwUpgrade,
        iconPath: AssetConstants.firmwareIcon,
        isDisabled: true,
        onTap:
            () => ProjectDashboardTileActions.openFirmwareUpgrade(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.serviceDue,
        iconPath: AssetConstants.panelActionServiceDueIcon,
        // isDisabled: !DemoBle.enabled,
        onTap: () => ProjectDashboardTileActions.openServiceDue(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.accessCode,
        iconPath: AssetConstants.panelActionAccessCodeIcon,
        onTap: () => ProjectDashboardTileActions.openAccessCode(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.panelInfo,
        iconPath: AssetConstants.panelActionPanelInfoIcon,
        onTap: () => ProjectDashboardTileActions.openPanelInfo(controller),
      ),
      WindowsDashboardTileConfig(
        label: 'General',
        iconPath: AssetConstants.panelActionGeneralModuleIcon,
        iconHeight: 36,
        iconWidth: 36,
        onTap: () => ProjectDashboardTileActions.openGeneralModule(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
        iconPath: AssetConstants.diagnosticIcon,
        isDisabled: !DemoBle.enabled,
        onTap:
            () => ProjectDashboardTileActions.openLiveDiagnostics(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.walkTest,
        iconPath: AssetConstants.walkTestIcon,
        isDisabled: true,
        iconHeight: 32,
        iconWidth: 32,
        onTap: () => ProjectDashboardTileActions.openWalkTest(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.configLog,
        iconPath: AssetConstants.panelActionConfigLogIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openConfigLog(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.testMode,
        iconPath: AssetConstants.peripheralProgHoldIcon,
        isDisabled: true,
        iconHeight: 24,
        iconWidth: 24,
        onTap: () => ProjectDashboardTileActions.openTestMode(controller),
      ),
    ];
  }
}
