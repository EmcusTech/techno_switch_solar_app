import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/app_styled_dialogs.dart';

/// Connect-time site resolution for panels whose BLE name is `TECHNOSWITCH_XXXX`.
class PanelSiteConnectFlow {
  PanelSiteConnectFlow._();

  /// When an offline-provisioned site exists for the parsed panel id, prompts the
  /// user once to confirm linking. Already BLE-linked panels return [siteId]
  /// silently.
  ///
  /// Returns a site id when resolved, `null` when the caller should continue
  /// with the standard flow, or `-1` when cancelled.
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

    // Already linked to this hardware — go straight to the site.
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
      title: 'Site found for this panel',
      message:
          'A site "${site.siteName}" was created for panel ID $logicalId. '
          'Assign this panel to that site, or create or choose a different site?',
      leadingActionLabel: 'New site',
      trailingActionLabel: 'Use site',
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

    // User chose a different site — unassign so standard flow can re-link.
    await panelService.unassignPanelFromSite(logicalId);
    return null;
  }
}
