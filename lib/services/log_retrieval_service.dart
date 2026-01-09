import '../models/log_retrieval_model.dart';
import '../models/log_model.dart';
import 'database_helper.dart';

class LogRetrievalService {
  static final LogRetrievalService _instance = LogRetrievalService._internal();
  factory LogRetrievalService() => _instance;
  LogRetrievalService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Create a new log retrieval session when logs are saved to a site
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

  /// Get all log retrieval sessions for a specific site
  Future<List<LogRetrievalModel>> getLogRetrievalsForSite(int siteId) async {
    return await _databaseHelper.getLogRetrievalsBySite(siteId);
  }

  /// Get a specific log retrieval session by ID
  Future<LogRetrievalModel?> getLogRetrievalById(int id) async {
    return await _databaseHelper.getLogRetrievalById(id);
  }

  /// Update an existing log retrieval session
  Future<bool> updateLogRetrieval(LogRetrievalModel logRetrieval) async {
    final updatedLogRetrieval = logRetrieval.copyWith(
      updatedAt: DateTime.now(),
    );
    final result = await _databaseHelper.updateLogRetrieval(
      updatedLogRetrieval,
    );
    return result > 0;
  }

  /// Delete a log retrieval session
  Future<bool> deleteLogRetrieval(int id) async {
    final result = await _databaseHelper.deleteLogRetrieval(id);
    return result > 0;
  }

  /// Get the total number of log retrievals for a site
  Future<int> getLogRetrievalCount(int siteId) async {
    return await _databaseHelper.getLogRetrievalCountBySite(siteId);
  }

  /// Get the most recent log retrieval for a site
  Future<LogRetrievalModel?> getMostRecentLogRetrieval(int siteId) async {
    return await _databaseHelper.getMostRecentLogRetrieval(siteId);
  }

  /// Check if there are any log retrievals for a site
  Future<bool> hasLogRetrievals(int siteId) async {
    final count = await getLogRetrievalCount(siteId);
    return count > 0;
  }

  /// Get log retrieval statistics for a site
  Future<Map<String, dynamic>> getLogRetrievalStats(int siteId) async {
    final retrievals = await getLogRetrievalsForSite(siteId);

    if (retrievals.isEmpty) {
      return {
        'totalRetrievals': 0,
        'totalLogs': 0,
        'averageLogsPerRetrieval': 0.0,
        'firstRetrieval': null,
        'lastRetrieval': null,
      };
    }

    final totalLogs = retrievals.fold<int>(
      0,
      (sum, retrieval) => sum + retrieval.logCount,
    );
    final averageLogsPerRetrieval = totalLogs / retrievals.length;

    // Sort by retrieval date to get first and last
    final sortedRetrievals = List<LogRetrievalModel>.from(retrievals)
      ..sort((a, b) => a.retrievalDate.compareTo(b.retrievalDate));

    return {
      'totalRetrievals': retrievals.length,
      'totalLogs': totalLogs,
      'averageLogsPerRetrieval': averageLogsPerRetrieval,
      'firstRetrieval': sortedRetrievals.first.retrievalDate,
      'lastRetrieval': sortedRetrievals.last.retrievalDate,
    };
  }

  /// Get the logs that belong to a specific retrieval session.
  /// Tries direct retrieval_id linkage first, then falls back to the retrieval date range
  /// for backwards compatibility with logs stored before the retrieval_id column existed.
  Future<List<LogModel>> getLogsForRetrieval(LogRetrievalModel retrieval) async {
    if (retrieval.id == null) return [];

    // Primary lookup: by retrieval_id
    final linkedLogs = await _databaseHelper.getLogsByRetrievalId(retrieval.id!);
    if (linkedLogs.isNotEmpty) return linkedLogs;

    // Fallback lookup: match by site and retrieved_at on the same day
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
