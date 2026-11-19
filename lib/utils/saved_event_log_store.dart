import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/models/panel_model.dart';
import 'package:Technoswitch/utils/constants/ble/ble_name_utils.dart';
import 'package:Technoswitch/utils/panel_service.dart';
import 'package:Technoswitch/utils/storage/database_helper.dart';

/// Normal event-log downloads stored against [PanelModel.panelId].
class SavedEventLogStore {
  SavedEventLogStore._();

  static final PanelService _panels = PanelService();
  static final DatabaseHelper _database = DatabaseHelper();

  static Future<String?> panelIdForDevice({
    required String bleName,
    required String deviceId,
  }) async {
    final String name = bleName.trim();
    final String? logicalId =
        name.isEmpty ? null : BleNameUtils.parseTechnoswitchPanelId(name);
    final PanelModel? panel =
        (logicalId == null ? null : await _panels.getPanelByPanelId(logicalId)) ??
        (name.isEmpty ? null : await _panels.getPanelByPanelId(name)) ??
        (name.isEmpty ? null : await _panels.getPanelByBleName(name));
    final String storedId = panel?.panelId ?? '';
    if (storedId.isNotEmpty) return storedId;
    if (logicalId != null && logicalId.isNotEmpty) return logicalId;
    if (deviceId.isEmpty && name.isEmpty) return null;
    return PanelModel.generatePanelId(
      deviceType: 'bluetooth',
      bluetoothMac: deviceId,
      bluetoothName: name,
    );
  }

  static Future<List<LogModel>> loadForDevice({
    required String bleName,
    required String deviceId,
  }) async {
    final String? panelId = await panelIdForDevice(
      bleName: bleName,
      deviceId: deviceId,
    );
    if (panelId == null || panelId.isEmpty) return <LogModel>[];
    return _database.getLogsByPanelId(panelId);
  }

  static Future<void> replaceForDevice({
    required String bleName,
    required String deviceId,
    required int? siteId,
    required List<LogModel> logs,
  }) async {
    final String? panelId = await panelIdForDevice(
      bleName: bleName,
      deviceId: deviceId,
    );
    if (panelId == null || panelId.isEmpty) return;
    await _database.replaceLogsForPanel(
      panelId: panelId,
      siteId: siteId,
      logs: logs,
    );
  }
}
