import 'dart:convert';
import '../models/panel_model.dart';
import 'database_helper.dart';

class PanelService {
  static final PanelService _instance = PanelService._internal();
  factory PanelService() => _instance;
  PanelService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Register or update a panel from device connection
  Future<PanelModel> registerPanelFromDevice({
    required dynamic device,
    required String scanType,
    int? siteId,
  }) async {
    final now = DateTime.now();

    // Generate panel info based on device type
    String panelId;
    String panelName;
    String deviceType;
    Map<String, dynamic> deviceInfo;

    if (scanType.toLowerCase() == 'bluetooth') {
      // Handle Bluetooth device
      String macAddress = '';
      String deviceName = '';
      int? rssi;

      if (device.runtimeType.toString().contains('ScanResult')) {
        // Extract from ScanResult
        final bluetoothDevice = (device as dynamic).device;
        macAddress = bluetoothDevice.remoteId.toString();
        deviceName = bluetoothDevice.platformName ?? 'BLE Solar Device';
        rssi = (device as dynamic).rssi;
      } else {
        // Direct BluetoothDevice
        macAddress = (device as dynamic).remoteId.toString();
        deviceName = (device as dynamic).platformName ?? 'BLE Solar Device';
      }

      panelId = PanelModel.generatePanelId(
        deviceType: 'bluetooth',
        bluetoothMac: macAddress,
        bluetoothName: deviceName,
      );

      panelName = deviceName.isNotEmpty ? deviceName : 'Solar Panel';
      deviceType = 'bluetooth';
      deviceInfo = PanelModel.createBluetoothDeviceInfo(
        macAddress: macAddress,
        deviceName: deviceName,
        rssi: rssi,
      );
    } else {
      // Handle USB device
      String? vid;
      String? pid;
      String? productName;

      if (device != null) {
        try {
          vid = (device as dynamic).vid?.toRadixString(16)?.toUpperCase();
          pid = (device as dynamic).pid?.toRadixString(16)?.toUpperCase();
          productName = (device as dynamic).productName;
        } catch (e) {
          // Fallback if device properties are not accessible
        }
      }

      panelId = PanelModel.generatePanelId(
        deviceType: 'usb',
        usbVid: vid,
        usbPid: pid,
        usbProductName: productName,
      );

      panelName = productName ?? 'USB Solar Device';
      deviceType = 'usb';
      deviceInfo = PanelModel.createUsbDeviceInfo(
        vid: vid,
        pid: pid,
        productName: productName,
      );
    }

    // Create panel model
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

    // Upsert panel (insert if new, update if existing)
    await _databaseHelper.upsertPanel(panel);

    // Return the registered panel
    return await getPanelByPanelId(panelId) ?? panel;
  }

  /// Get panel by panel ID
  Future<PanelModel?> getPanelByPanelId(String panelId) async {
    return await _databaseHelper.getPanelByPanelId(panelId);
  }

  /// Get all panels for a site
  Future<List<PanelModel>> getPanelsBySiteId(int siteId) async {
    return await _databaseHelper.getPanelsBySiteId(siteId);
  }

  /// Get unassigned panels
  Future<List<PanelModel>> getUnassignedPanels() async {
    return await _databaseHelper.getUnassignedPanels();
  }

  /// Assign panel to site
  Future<bool> assignPanelToSite(
    String panelId,
    int siteId, {
    String? panelName,
  }) async {
    // Check if panel exists, if not create it first
    var panel = await getPanelByPanelId(panelId);

    final now = DateTime.now();

    if (panel == null) {
      // Panel doesn't exist, create it with minimal info
      // This can happen if panel was never registered during connection
      // Detect device type from panel ID format
      String deviceType = 'bluetooth'; // Default
      if (panelId.startsWith('BT_') || panelId.startsWith('BLUETOOTH_')) {
        deviceType = 'bluetooth';
      } else if (panelId.startsWith('USB_')) {
        deviceType = 'usb';
      } else if (RegExp(
        r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$',
        caseSensitive: false,
      ).hasMatch(panelId)) {
        // MAC address format (e.g., DC:ED:12:B1:56:37)
        deviceType = 'bluetooth';
      }

      panel = PanelModel(
        panelId: panelId,
        panelName:
            (panelName ?? '').trim().isNotEmpty
                ? panelName!.trim()
                : 'Panel $panelId', // Fallback name
        deviceType: deviceType,
        deviceInfo: jsonEncode({'panelId': panelId}),
        siteId: null, // Will be set below
        createdAt: now,
        updatedAt: now,
        lastConnected: now,
      );
      await _databaseHelper.upsertPanel(panel);
    } else if ((panelName ?? '').trim().isNotEmpty &&
        panel.panelName != panelName!.trim()) {
      // Update panel name if a better one was provided
      final updatedPanel = panel.copyWith(
        panelName: panelName.trim(),
        updatedAt: now,
      );
      await _databaseHelper.upsertPanel(updatedPanel);
    }

    // Check if panel is already assigned to another site
    if (panel.siteId != null && panel.siteId != siteId) {
      throw Exception('Panel is already assigned to another site');
    }

    final result = await _databaseHelper.assignPanelToSite(panelId, siteId);
    return result > 0;
  }

  /// Unassign panel from site
  Future<bool> unassignPanelFromSite(String panelId) async {
    final result = await _databaseHelper.unassignPanelFromSite(panelId);
    return result > 0;
  }

  /// Update panel last connected time
  Future<bool> updatePanelLastConnected(String panelId) async {
    final result = await _databaseHelper.updatePanelLastConnected(panelId);
    return result > 0;
  }

  /// Get all panels
  Future<List<PanelModel>> getAllPanels() async {
    return await _databaseHelper.getAllPanels();
  }

  /// Delete panel
  Future<bool> deletePanel(String panelId) async {
    final result = await _databaseHelper.deletePanel(panelId);
    return result > 0;
  }

  /// Get panels with site information
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

  /// Check if panel can be assigned to site (not already assigned elsewhere)
  Future<bool> canAssignPanelToSite(String panelId, int siteId) async {
    final panel = await getPanelByPanelId(panelId);
    if (panel == null) return false;

    // Panel can be assigned if it's not assigned or already assigned to the same site
    return panel.siteId == null || panel.siteId == siteId;
  }

  /// Get site panels count
  Future<int> getSitePanelsCount(int siteId) async {
    final panels = await getPanelsBySiteId(siteId);
    return panels.length;
  }

  /// Generate a unique panel ID for testing purposes
  String generateTestPanelId(String deviceName) {
    return PanelModel.generatePanelId(
      deviceType: 'test',
      bluetoothName: deviceName,
    );
  }
}

/// Helper class to combine panel with site information
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
    if (!isAssigned) return 'Unassigned';
    if (siteName != null && siteName!.isNotEmpty) {
      return siteName!;
    }
    return 'Site #${panel.siteId}';
  }
}
