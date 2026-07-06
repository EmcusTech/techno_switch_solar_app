import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_tile_actions.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/peripheral_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

abstract final class DashboardTileRegistry {
  static List<DashboardTileConfig> overviewTiles(
    ProjectDashboardController controller,
  ) {
    return [
      DashboardTileConfig(
        label: StringConstants.relays,
        iconPath: AssetConstants.peripheralRelayIcon,
        onTap: () => ProjectDashboardTileActions.openRelays(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.inputs,
        iconPath: AssetConstants.peripheralInputIcon,
        onTap: () => ProjectDashboardTileActions.openInputs(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.zones,
        iconPath: AssetConstants.peripheralZonesIcon,
        onTap: () => ProjectDashboardTileActions.openZones(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.sounders,
        iconPath: AssetConstants.peripheralSounderIcon,
        onTap: () => ProjectDashboardTileActions.openSounders(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.radio,
        iconPath: AssetConstants.peripheralProgHoldIcon,
        isDisabled: true,
        iconHeight: 24,
        iconWidth: 24,
        onTap: () => ProjectDashboardTileActions.openRadio(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.moduleInfo,
        iconPath: AssetConstants.peripheralAuxIcon,
        onTap: () => ProjectDashboardTileActions.openModuleInfo(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.lBus,
        iconPath: AssetConstants.peripheralLBusIcon,
        onTap: () => ProjectDashboardTileActions.openLBus(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.extOut2,
        iconPath: AssetConstants.peripheralExtOutIcon,
        onTap: () => ProjectDashboardTileActions.openExtOut(controller),
      ),
    ];
  }

  static List<DashboardTileConfig> panelActionTiles(
    ProjectDashboardController controller,
  ) {
    return [
      DashboardTileConfig(
        label: StringConstants.eventLog,
        iconPath: AssetConstants.panelActionEventLogIcon,
        onTap: () => ProjectDashboardTileActions.openEventLog(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.fwUpgrade,
        iconPath: AssetConstants.firmwareIcon,
        onTap: () => ProjectDashboardTileActions.openFirmwareUpgrade(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.serviceDue,
        iconPath: AssetConstants.panelActionServiceDueIcon,
        onTap: () => ProjectDashboardTileActions.openServiceDue(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.accessCode,
        iconPath: AssetConstants.panelActionAccessCodeIcon,
        onTap: () => ProjectDashboardTileActions.openAccessCode(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.panelInfo,
        iconPath: AssetConstants.panelActionPanelInfoIcon,
        onTap: () => ProjectDashboardTileActions.openPanelInfo(controller),
      ),
      DashboardTileConfig(
        label: 'General',
        iconPath: AssetConstants.panelActionGeneralModuleIcon,
        iconHeight: 36,
        iconWidth: 36,
        onTap: () => ProjectDashboardTileActions.openGeneralModule(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime,
        iconPath: AssetConstants.diagnosticIcon,
        onTap: () => ProjectDashboardTileActions.openLiveDiagnostics(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.walkTest,
        iconPath: AssetConstants.walkTestIcon,
        iconHeight: 32,
        iconWidth: 32,
        onTap: () => ProjectDashboardTileActions.openWalkTest(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.configLog,
        iconPath: AssetConstants.panelActionConfigLogIcon,
        onTap: () => ProjectDashboardTileActions.openConfigLog(controller),
      ),
      DashboardTileConfig(
        label: StringConstants.testMode,
        iconPath: AssetConstants.peripheralProgHoldIcon,
        iconHeight: 24,
        iconWidth: 24,
        onTap: () => ProjectDashboardTileActions.openTestMode(controller),
      ),
    ];
  }
}
