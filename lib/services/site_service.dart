import '../models/site_model.dart';
import '../models/log_model.dart';
import '../models/panel_model.dart';
import '../models/log_retrieval_model.dart';
import 'database_helper.dart';
import 'panel_service.dart';
import 'log_retrieval_service.dart';

class SiteService {
  static final SiteService _instance = SiteService._internal();
  factory SiteService() => _instance;
  SiteService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PanelService _panelService = PanelService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();

  Future<SiteModel> createSite({
    required String siteName,
    required String installerName,
    required String companyName,
    required String saqccRegNumber,
    required String buildingName,
    required String installerContactNumber,
    required String installerEmail,
    required String siteDescription,
  }) async {
    final now = DateTime.now();

    final site = SiteModel(
      siteName: siteName.trim(),
      installerName: installerName.trim(),
      companyName: companyName.trim(),
      saqccRegNumber: saqccRegNumber.trim(),
      buildingName: buildingName.trim(),
      installerContactNumber: installerContactNumber.trim(),
      installerEmail: installerEmail.trim(),
      siteDescription: siteDescription.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final id = await _databaseHelper.insertSite(site);
    return site.copyWith(id: id);
  }

  Future<List<SiteModel>> getAllSites() async {
    return await _databaseHelper.getAllSites();
  }

  Future<SiteModel?> getSiteById(int id) async {
    return await _databaseHelper.getSiteById(id);
  }

  Future<SiteModel> updateSite(SiteModel site) async {
    final updatedSite = site.copyWith(updatedAt: DateTime.now());
    await _databaseHelper.updateSite(updatedSite);
    return updatedSite;
  }

  Future<bool> deleteSite(int id) async {
    final result = await _databaseHelper.deleteSite(id);
    return result > 0;
  }

  Future<List<SiteModel>> searchSites(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return await getAllSites();
    }
    return await _databaseHelper.searchSites(searchTerm.trim());
  }

  Future<List<SiteWithLogCount>> getSitesWithLogCount() async {
    final sitesData = await _databaseHelper.getSitesWithLogCount();

    return sitesData.map((data) {
      final site = SiteModel.fromMap(data);
      final logCount = data['log_count'] as int? ?? 0;
      final lastLogRetrieved =
          data['last_log_retrieved'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['last_log_retrieved'])
              : null;

      return SiteWithLogCount(
        site: site,
        logCount: logCount,
        lastLogRetrieved: lastLogRetrieved,
      );
    }).toList();
  }

  Future<int> associateLogsWithSite(List<LogModel> logs, int siteId) async {
    final logIds =
        logs.where((log) => log.id != null).map((log) => log.id!).toList();
    if (logIds.isEmpty) return 0;

    return await _databaseHelper.associateLogsWithSite(logIds, siteId);
  }

  Future<List<LogModel>> getLogsBySiteId(int siteId) async {
    return await _databaseHelper.getLogsBySiteId(siteId);
  }

  Future<void> storeLogs(List<LogModel> logs, {int? siteId}) async {
    LogRetrievalModel? retrievalSession;
    DateTime retrievalTimestamp = DateTime.now();

    if (siteId != null && logs.isNotEmpty) {
      try {
        print(
          'DEBUG: Creating log retrieval session for siteId: $siteId, logCount: ${logs.length}',
        );
        final site = await getSiteById(siteId);
        if (site != null) {
          print('DEBUG: Site found: ${site.siteName}');
          retrievalSession = await _logRetrievalService
              .createLogRetrievalSession(
                siteId: siteId,
                siteName: site.siteName,
                logs: logs,
              );
          retrievalTimestamp = retrievalSession.retrievalDate;
          print(
            'DEBUG: Log retrieval session created successfully: ${retrievalSession.sessionName}',
          );
        } else {
          print('DEBUG: ERROR - Site not found for siteId: $siteId');
        }
      } catch (e, stackTrace) {
        print('DEBUG: ERROR creating log retrieval session: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }
    } else {
      print(
        'DEBUG: Skipping log retrieval session creation - siteId: $siteId, logs.isEmpty: ${logs.isEmpty}',
      );
    }

    final logsWithSiteId =
        logs
            .map(
              (log) => log.copyWith(
                siteId: siteId,
                retrievalId: retrievalSession?.id,
                retrievedAt: log.retrievedAt ?? retrievalTimestamp,
              ),
            )
            .toList();

    await _databaseHelper.insertLogs(logsWithSiteId);
  }

  Future<List<LogModel>> getOrphanedLogs() async {
    return await _databaseHelper.getOrphanedLogs();
  }

  Future<int> cleanupOldOrphanedLogs({int daysOld = 30}) async {
    return await _databaseHelper.deleteOldOrphanedLogs(daysOld);
  }

  Future<Map<String, int>> getDatabaseStats() async {
    return await _databaseHelper.getDatabaseStats();
  }

  Future<List<RecentActivity>> getRecentActivity({int limit = 10}) async {
    final activityData = await _databaseHelper.getRecentActivity(limit);

    return activityData.map((data) {
      return RecentActivity(
        siteId: data['site_id'] as int,
        siteName: data['site_name'] as String,
        installerName: data['installer_name'] as String,
        companyName: data['company_name'] as String,
        siteCreatedAt: DateTime.fromMillisecondsSinceEpoch(
          data['site_created_at'],
        ),
        logId: data['log_id'] as int?,
        eventType: data['event_type'] as String?,
        eventDateTime:
            data['event_date_time'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['event_date_time'])
                : null,
        logRetrievedAt:
            data['retrieved_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['retrieved_at'])
                : null,
        activityTime: DateTime.fromMillisecondsSinceEpoch(
          data['activity_time'],
        ),
      );
    }).toList();
  }

  Map<String, String> validateSiteData({
    required String siteName,
    required String installerName,
    required String companyName,
    required String saqccRegNumber,
    required String buildingName,
    required String installerContactNumber,
    required String installerEmail,
    required String siteDescription,
  }) {
    final errors = <String, String>{};

    if (siteName.trim().isEmpty) {
      errors['siteName'] = 'Site name is required';
    }

    if (saqccRegNumber.trim().isEmpty) {
      errors['saqccRegNumber'] = 'SAQCC registration number is required';
    }

    if (installerEmail.trim().isNotEmpty &&
        !_isValidEmail(installerEmail.trim())) {
      errors['installerEmail'] = 'Please enter a valid email address';
    }

    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<List<PanelModel>> getSitePanels(int siteId) async {
    return await _panelService.getPanelsBySiteId(siteId);
  }

  Future<bool> assignPanelToSite(
    String panelId,
    int siteId, {
    String? panelName,
    bool offlineProvisioned = false,
  }) async {
    return await _panelService.assignPanelToSite(
      panelId,
      siteId,
      panelName: panelName,
      offlineProvisioned: offlineProvisioned,
    );
  }

  Future<List<PanelModel>> getUnassignedPanels() async {
    return await _panelService.getUnassignedPanels();
  }

  Future<PanelModel?> getPanelByPanelId(String panelId) async {
    return await _panelService.getPanelByPanelId(panelId);
  }

  Future<bool> associateCurrentPanelWithSite(
    String? panelId,
    int siteId, {
    String? panelName,
  }) async {
    if (panelId == null) return false;
    return await _panelService.assignPanelToSite(
      panelId,
      siteId,
      panelName: panelName,
    );
  }

  Future<bool> canAssignPanelToSite(String panelId, int siteId) async {
    return await _panelService.canAssignPanelToSite(panelId, siteId);
  }

  Future<int> getSitePanelCount(int siteId) async {
    return await _panelService.getSitePanelsCount(siteId);
  }

  Future<List<PanelModel>> getAllPanels() async {
    return await _panelService.getAllPanels();
  }
}

class SiteWithLogCount {
  final SiteModel site;
  final int logCount;
  final DateTime? lastLogRetrieved;

  SiteWithLogCount({
    required this.site,
    required this.logCount,
    this.lastLogRetrieved,
  });
}

class RecentActivity {
  final int siteId;
  final String siteName;
  final String installerName;
  final String companyName;
  final DateTime siteCreatedAt;
  final int? logId;
  final String? eventType;
  final DateTime? eventDateTime;
  final DateTime? logRetrievedAt;
  final DateTime activityTime;

  RecentActivity({
    required this.siteId,
    required this.siteName,
    required this.installerName,
    required this.companyName,
    required this.siteCreatedAt,
    this.logId,
    this.eventType,
    this.eventDateTime,
    this.logRetrievedAt,
    required this.activityTime,
  });

  bool get isLogActivity => logId != null;
  bool get isSiteCreation => logId == null;
}
