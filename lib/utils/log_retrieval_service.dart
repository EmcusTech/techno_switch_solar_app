import '../models/log_retrieval_model.dart';
import '../models/log_model.dart';
import 'storage/database_helper.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogRetrievalService {
  static final LogRetrievalService _instance = LogRetrievalService._internal();
  factory LogRetrievalService() => _instance;
  LogRetrievalService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<LogRetrievalModel> createLogRetrievalSession({
    required int siteId,
    required String siteName,
    required List<LogModel> logs,
    DateTime? retrievalDate,
  }) async {
    final now = DateTime.now();
    final actualRetrievalDate = retrievalDate ?? now;

    final sessionName = LogRetrievalModel.generateSessionName(
      siteName,
      actualRetrievalDate,
    );

    final logRetrieval = LogRetrievalModel(
      siteId: siteId,
      sessionName: sessionName,
      logCount: logs.length,
      retrievalDate: actualRetrievalDate,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _databaseHelper.insertLogRetrieval(logRetrieval);
    return logRetrieval.copyWith(id: id);
  }

  Future<List<LogRetrievalModel>> getLogRetrievalsForSite(int siteId) async {
    return await _databaseHelper.getLogRetrievalsBySite(siteId);
  }

  Future<LogRetrievalModel?> getLogRetrievalById(int id) async {
    return await _databaseHelper.getLogRetrievalById(id);
  }

  Future<bool> updateLogRetrieval(LogRetrievalModel logRetrieval) async {
    final updatedLogRetrieval = logRetrieval.copyWith(
      updatedAt: DateTime.now(),
    );
    final result = await _databaseHelper.updateLogRetrieval(
      updatedLogRetrieval,
    );
    return result > 0;
  }

  Future<bool> deleteLogRetrieval(int id) async {
    final result = await _databaseHelper.deleteLogRetrieval(id);
    return result > 0;
  }

  Future<int> getLogRetrievalCount(int siteId) async {
    return await _databaseHelper.getLogRetrievalCountBySite(siteId);
  }

  Future<LogRetrievalModel?> getMostRecentLogRetrieval(int siteId) async {
    return await _databaseHelper.getMostRecentLogRetrieval(siteId);
  }

  Future<bool> hasLogRetrievals(int siteId) async {
    final count = await getLogRetrievalCount(siteId);
    return count > 0;
  }

  Future<Map<String, dynamic>> getLogRetrievalStats(int siteId) async {
    final retrievals = await getLogRetrievalsForSite(siteId);

    if (retrievals.isEmpty) {
      return {
        'totalRetrievals': 0,
        StringConstants.totallogs: 0,
        StringConstants.averagelogsperretrieval: 0.0,
        StringConstants.firstretrieval: null,
        StringConstants.lastretrieval: null,
      };
    }

    final totalLogs = retrievals.fold<int>(
      0,
      (sum, retrieval) => sum + retrieval.logCount,
    );
    final averageLogsPerRetrieval = totalLogs / retrievals.length;

    final sortedRetrievals = List<LogRetrievalModel>.from(retrievals)
      ..sort((a, b) => a.retrievalDate.compareTo(b.retrievalDate));

    return {
      'totalRetrievals': retrievals.length,
      StringConstants.totallogs: totalLogs,
      StringConstants.averagelogsperretrieval: averageLogsPerRetrieval,
      StringConstants.firstretrieval: sortedRetrievals.first.retrievalDate,
      StringConstants.lastretrieval: sortedRetrievals.last.retrievalDate,
    };
  }

  Future<List<LogModel>> getLogsForRetrieval(
    LogRetrievalModel retrieval,
  ) async {
    if (retrieval.id == null) return [];

    final linkedLogs = await _databaseHelper.getLogsByRetrievalId(
      retrieval.id!,
    );
    if (linkedLogs.isNotEmpty) return linkedLogs;

    final startOfDay = DateTime(
      retrieval.retrievalDate.year,
      retrieval.retrievalDate.month,
      retrieval.retrievalDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _databaseHelper.getLogsBySiteIdAndRetrievedRange(
      retrieval.siteId,
      startOfDay,
      endOfDay,
    );
  }
}
