import 'dart:convert';
import '../models/panel_model.dart';
import 'storage/database_helper.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelService {
  static final PanelService _instance = PanelService._internal();
  factory PanelService() => _instance;
  PanelService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<PanelModel> registerPanelFromDevice({
    required dynamic device,
    required String scanType,
    int? siteId,
  }) async {
    final now = DateTime.now();

    String panelId;
    String panelName;
    String deviceType;
    Map<String, dynamic> deviceInfo;

    if (scanType.toLowerCase() == 'bluetooth') {
      String macAddress = '';
      String deviceName = '';
      int? rssi;

      if (device.runtimeType.toString().contains(StringConstants.scanresult)) {
        final bluetoothDevice = (device as dynamic).device;
        macAddress = bluetoothDevice.remoteId.toString();
        deviceName =
            bluetoothDevice.platformName ?? StringConstants.bleSolarDevice;
        rssi = (device as dynamic).rssi;
      } else {
        macAddress = (device as dynamic).remoteId.toString();
        deviceName =
            (device as dynamic).platformName ?? StringConstants.bleSolarDevice;
      }

      panelId = PanelModel.generatePanelId(
        deviceType: 'bluetooth',
        bluetoothMac: macAddress,
        bluetoothName: deviceName,
      );

      panelName =
          deviceName.isNotEmpty ? deviceName : StringConstants.solarPanel;
      deviceType = 'bluetooth';
      deviceInfo = PanelModel.createBluetoothDeviceInfo(
        macAddress: macAddress,
        deviceName: deviceName,
        rssi: rssi,
      );
    } else {
      String? vid;
      String? pid;
      String? productName;

      if (device != null) {
        try {
          vid = (device as dynamic).vid?.toRadixString(16)?.toUpperCase();
          pid = (device as dynamic).pid?.toRadixString(16)?.toUpperCase();
          productName = (device as dynamic).productName;
        } catch (_) {}
      }

      panelId = PanelModel.generatePanelId(
        deviceType: 'usb',
        usbVid: vid,
        usbPid: pid,
        usbProductName: productName,
      );

      panelName = productName ?? StringConstants.usbSolarDevice;
      deviceType = 'usb';
      deviceInfo = PanelModel.createUsbDeviceInfo(
        vid: vid,
        pid: pid,
        productName: productName,
      );
    }

    final panel = PanelModel(
      panelId: panelId,
      panelName: panelName,
      deviceType: deviceType,
      deviceInfo: jsonEncode(deviceInfo),
      siteId: siteId,
      createdAt: now,
      updatedAt: now,
      lastConnected: now,
    );

    await _databaseHelper.upsertPanel(panel);

    return await getPanelByPanelId(panelId) ?? panel;
  }

  Future<PanelModel?> getPanelByPanelId(String panelId) async {
    return await _databaseHelper.getPanelByPanelId(panelId);
  }

  Future<PanelModel?> getPanelByBleName(String bleName) async {
    return await _databaseHelper.getPanelByPanelName(bleName);
  }

  Future<List<PanelModel>> getPanelsBySiteId(int siteId) async {
    return await _databaseHelper.getPanelsBySiteId(siteId);
  }

  Future<List<PanelModel>> getUnassignedPanels() async {
    return await _databaseHelper.getUnassignedPanels();
  }

  Future<bool> assignPanelToSite(
    String panelId,
    int siteId, {
    String? panelName,
    bool offlineProvisioned = false,
  }) async {
    var panel = await getPanelByPanelId(panelId);

    final now = DateTime.now();

    if (panel == null) {
      String deviceType = 'bluetooth';
      if (panelId.startsWith(StringConstants.bt) ||
          panelId.startsWith(StringConstants.bluetooth2)) {
        deviceType = 'bluetooth';
      } else if (panelId.startsWith('USB_')) {
        deviceType = 'usb';
      } else if (RegExp(
        r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$',
        caseSensitive: false,
      ).hasMatch(panelId)) {
        deviceType = 'bluetooth';
      }

      panel = PanelModel(
        panelId: panelId,
        panelName:
            (panelName ?? '').trim().isNotEmpty
                ? panelName!.trim()
                : 'Panel $panelId',
        deviceType: deviceType,
        deviceInfo: jsonEncode(
          offlineProvisioned
              ? PanelModel.createOfflineProvisionedDeviceInfo(panelId)
              : {StringConstants.offlineprovisioned: panelId},
        ),
        siteId: null,
        createdAt: now,
        updatedAt: now,
        lastConnected: offlineProvisioned ? null : now,
      );
      await _databaseHelper.upsertPanel(panel);
    } else {
      var updatedPanel = panel;
      if ((panelName ?? '').trim().isNotEmpty &&
          panel.panelName != panelName!.trim()) {
        updatedPanel = updatedPanel.copyWith(panelName: panelName.trim());
      }
      if (offlineProvisioned && !panel.isOfflineProvisionedOnly) {
        updatedPanel = updatedPanel.copyWith(
          deviceInfo: jsonEncode(
            PanelModel.createOfflineProvisionedDeviceInfo(panelId),
          ),
        );
      }
      if (updatedPanel.panelName != panel.panelName ||
          updatedPanel.deviceInfo != panel.deviceInfo) {
        await _databaseHelper.upsertPanel(
          updatedPanel.copyWith(updatedAt: now),
        );
        panel = updatedPanel;
      }
    }

    if (panel.siteId != null && panel.siteId != siteId) {
      throw Exception(StringConstants.panelIsAlreadyAssignedToAnotherSite);
    }

    final result = await _databaseHelper.assignPanelToSite(panelId, siteId);
    return result > 0;
  }

  Future<bool> markPanelBleLinked(
    String panelId, {
    required String macAddress,
    required String bleName,
    int? rssi,
  }) async {
    final panel = await getPanelByPanelId(panelId);
    if (panel == null) return false;

    final now = DateTime.now();
    final deviceInfo = PanelModel.createBluetoothDeviceInfo(
      macAddress: macAddress,
      deviceName: bleName,
      rssi: rssi,
    );
    deviceInfo['offlineProvisioned'] = false;
    deviceInfo[StringConstants.offlineprovisioned] = panelId;

    final updatedPanel = panel.copyWith(
      panelName: bleName.trim().isNotEmpty ? bleName.trim() : panel.panelName,
      deviceType: 'bluetooth',
      deviceInfo: jsonEncode(deviceInfo),
      updatedAt: now,
      lastConnected: now,
    );
    await _databaseHelper.upsertPanel(updatedPanel);
    await _databaseHelper.updatePanelLastConnected(panelId);
    return true;
  }

  Future<bool> unassignPanelFromSite(String panelId) async {
    final result = await _databaseHelper.unassignPanelFromSite(panelId);
    return result > 0;
  }

  Future<bool> updatePanelLastConnected(String panelId) async {
    final result = await _databaseHelper.updatePanelLastConnected(panelId);
    return result > 0;
  }

  Future<List<PanelModel>> getAllPanels() async {
    return await _databaseHelper.getAllPanels();
  }

  Future<bool> deletePanel(String panelId) async {
    final result = await _databaseHelper.deletePanel(panelId);
    return result > 0;
  }

  Future<List<PanelWithSiteInfo>> getPanelsWithSiteInfo() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        p.*,
        s.site_name,
        s.installer_name,
        s.company_name
      FROM panels p 
      LEFT JOIN sites s ON p.site_id = s.id 
      ORDER BY p.last_connected DESC, p.created_at DESC
    ''');

    return maps.map((data) {
      final panel = PanelModel.fromMap(data);
      return PanelWithSiteInfo(
        panel: panel,
        siteName: data['site_name'] as String?,
        installerName: data['installer_name'] as String?,
        companyName: data['company_name'] as String?,
      );
    }).toList();
  }

  Future<bool> canAssignPanelToSite(String panelId, int siteId) async {
    final panel = await getPanelByPanelId(panelId);
    if (panel == null) return false;

    return panel.siteId == null || panel.siteId == siteId;
  }

  Future<int> getSitePanelsCount(int siteId) async {
    final panels = await getPanelsBySiteId(siteId);
    return panels.length;
  }

  String generateTestPanelId(String deviceName) {
    return PanelModel.generatePanelId(
      deviceType: 'test',
      bluetoothName: deviceName,
    );
  }
}

class PanelWithSiteInfo {
  final PanelModel panel;
  final String? siteName;
  final String? installerName;
  final String? companyName;

  PanelWithSiteInfo({
    required this.panel,
    this.siteName,
    this.installerName,
    this.companyName,
  });

  bool get isAssigned => panel.siteId != null;

  String get displaySiteInfo {
    if (!isAssigned) return StringConstants.unassigned;
    if (siteName != null && siteName!.isNotEmpty) {
      return siteName!;
    }
    return 'Site #${panel.siteId}';
  }
}
