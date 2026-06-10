import 'dart:convert';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/services/database_helper.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';

Future<void> seedMockData() async {
  const mockSiteName = 'Mock Test Site';
  const mockPanelId = 'BT_MOCK1234';
  const mockPanelName = 'TECHNOSWITCH_12345678';

  final siteService = SiteService();
  final db = DatabaseHelper();
  final allSites = await siteService.getAllSites();
  if (allSites.any((s) => s.siteName == mockSiteName)) {
    return;
  }
  final now = DateTime.now();
  final site = await siteService.createSite(
    siteName: mockSiteName,
    installerName: 'Mock Installer',
    companyName: 'Mock Company',
    saqccRegNumber: 'MOCK-SAQCC-001',
    buildingName: 'Mock Building',
    installerContactNumber: '+27 12 000 0000',
    installerEmail: 'mock@test.com',
    siteDescription: 'Mock site for testing',
  );

  if (site.id == null) return;

  final deviceInfo = PanelModel.createBluetoothDeviceInfo(
    macAddress: 'AA:BB:CC:DD:EE:FF',
    deviceName: mockPanelName,
    rssi: -65,
  );

  final panel = PanelModel(
    panelId: mockPanelId,
    panelName: mockPanelName,
    deviceType: 'bluetooth',
    deviceInfo: jsonEncode(deviceInfo),
    siteId: site.id,
    createdAt: now,
    updatedAt: now,
    lastConnected: now,
  );

  await db.upsertPanel(panel);
}
