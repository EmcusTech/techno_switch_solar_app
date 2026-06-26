import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/app_styled_dialogs.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelSiteConnectFlow {
  PanelSiteConnectFlow._();

  static Future<int?> tryTechnoswitchRecoveredSite({
    required BuildContext context,
    required DiscoveredDevice device,
    required PanelService panelService,
    required SiteService siteService,
  }) async {
    final bleName = device.name.trim();
    final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
    if (logicalId == null) return null;

    final panel = await panelService.getPanelByPanelId(logicalId);
    final siteId = panel?.siteId;
    if (siteId == null) return null;

    final site = await siteService.getSiteById(siteId);
    if (site == null) return null;

    if (panel!.isLinkedToBleMac(device.id) || !panel.isOfflineProvisionedOnly) {
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
      return siteId;
    }

    if (!context.mounted) return -1;

    final choice = await showAppStyledTwoActionDialog<String>(
      context: context,
      title: StringConstants.siteFoundForThisPanel,
      message:
          'A site "${site.siteName}" was created for panel ID $logicalId. '
          'Assign this panel to that site, or create or choose a different site?',
      leadingActionLabel: 'New site',
      trailingActionLabel: StringConstants.aSiteSiteSiteNameWasCreatedForPanelIDLogicalId,
      leadingValue: 'new',
      trailingValue: 'assign',
      icon: Icons.location_city,
    );

    if (!context.mounted) return -1;
    if (choice == null) return -1;

    if (choice == 'assign') {
      await siteService.assignPanelToSite(
        logicalId,
        siteId,
        panelName: bleName,
      );
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
      return siteId;
    }

    await panelService.unassignPanelFromSite(logicalId);
    return null;
  }
}
