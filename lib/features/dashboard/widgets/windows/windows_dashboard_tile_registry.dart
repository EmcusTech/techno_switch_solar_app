import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_tile_actions.dart';
import 'package:Technoswitch/features/dashboard/widgets/peripheral_tile.dart';
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
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openSounders(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.radio,
        iconPath: AssetConstants.peripheralProgHoldIcon,
        isDisabled: true,
        iconHeight: 24,
        iconWidth: 24,
        onTap: () => ProjectDashboardTileActions.openRadio(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.moduleInfo,
        iconPath: AssetConstants.peripheralAuxIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openModuleInfo(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.lBus,
        iconPath: AssetConstants.peripheralLBusIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openLBus(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.extOut2,
        iconPath: AssetConstants.peripheralExtOutIcon,
        isDisabled: true,
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
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openServiceDue(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.accessCode,
        iconPath: AssetConstants.panelActionAccessCodeIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openAccessCode(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.panelInfo,
        iconPath: AssetConstants.panelActionPanelInfoIcon,
        isDisabled: true,
        onTap: () => ProjectDashboardTileActions.openPanelInfo(controller),
      ),
      WindowsDashboardTileConfig(
        label: 'General',
        iconPath: AssetConstants.panelActionGeneralModuleIcon,
        isDisabled: true,
        iconHeight: 36,
        iconWidth: 36,
        onTap: () => ProjectDashboardTileActions.openGeneralModule(controller),
      ),
      WindowsDashboardTileConfig(
        label: StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
        iconPath: AssetConstants.diagnosticIcon,
        isDisabled: true,
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
