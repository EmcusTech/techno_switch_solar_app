import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/site_model.dart';
import '../../models/log_model.dart';
import '../../models/panel_model.dart';
import '../../models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), DbSql.dbName);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute(StringConstants.pragmaForeignKeysON);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DbSql.createSitesTable);
    await db.execute(DbSql.createLogRetrievalsTable);
    await db.execute(DbSql.createLogsTable);
    await db.execute(DbSql.createPanelsTable);
    await db.execute(DbSql.createIndexLogsSiteId);
    await db.execute(DbSql.createIndexLogsEventDate);
    await db.execute(DbSql.createIndexLogsRetrievalId);
    await db.execute(DbSql.createIndexSitesCreatedAt);
    await db.execute(DbSql.createIndexPanelsPanelId);
    await db.execute(DbSql.createIndexPanelsSiteId);
    await db.execute(DbSql.createIndexLogRetrievalsSiteId);
    await db.execute(DbSql.createIndexLogRetrievalsRetrievalDate);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DbSql.createPanelsTable);
      await db.execute(DbSql.createIndexPanelsPanelId);
      await db.execute(DbSql.createIndexPanelsSiteId);
    }

    if (oldVersion < 3) {
      await db.execute(DbSql.createLogRetrievalsTable);
      await db.execute(DbSql.createIndexLogRetrievalsSiteId);
      await db.execute(DbSql.createIndexLogRetrievalsRetrievalDate);
    }

    if (oldVersion < 4) {
      await db.execute(StringConstants.alterTABLELogsADDCOLUMNIsValidINTEGER);
    }

    if (oldVersion < 5) {
      await db.execute(
        StringConstants.alterTABLELogsADDCOLUMNRetrievalIdINTEGER,
      );
      await db.execute(DbSql.createIndexLogsRetrievalId);
    }
  }

  Future<int> insertSite(SiteModel site) async {
    final db = await database;
    return await db.insert('sites', site.toMap());
  }

  Future<List<SiteModel>> getAllSites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sites',
      orderBy: StringConstants.siteNameLIKEORInstallerNameLIKEORCompanyNameLIKE,
    );

    return List.generate(maps.length, (i) {
      return SiteModel.fromMap(maps[i]);
    });
  }

  Future<SiteModel?> getSiteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sites',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SiteModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSite(SiteModel site) async {
    final db = await database;
    return await db.update(
      'sites',
      site.toMap(),
      where: 'id = ?',
      whereArgs: [site.id],
    );
  }

  Future<int> deleteSite(int id) async {
    final db = await database;

    return await db.transaction((txn) async {
      await txn.delete('logs', where: 'site_id = ?', whereArgs: [id]);
      await txn.delete(
        StringConstants.id2,
        where: 'site_id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'panels',
        {'site_id': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'site_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('sites', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<SiteModel>> searchSites(String searchTerm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sites',
      where: 'site_name LIKE ? OR installer_name LIKE ? OR company_name LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
      orderBy: StringConstants.siteNameLIKEORInstallerNameLIKEORCompanyNameLIKE,
    );

    return List.generate(maps.length, (i) {
      return SiteModel.fromMap(maps[i]);
    });
  }

  Future<int> insertLog(LogModel log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  Future<void> insertLogs(List<LogModel> logs) async {
    final db = await database;
    final batch = db.batch();

    for (final log in logs) {
      batch.insert('logs', log.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<List<LogModel>> getLogsBySiteId(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: StringConstants.eventDateTimeDESCRetrievedAtDESC,
    );

    return List.generate(maps.length, (i) {
      return LogModel.fromMap(maps[i]);
    });
  }

  Future<List<LogModel>> getOrphanedLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: 'site_id IS NULL',
      orderBy: StringConstants.retrievedAtDESC,
    );

    return List.generate(maps.length, (i) {
      return LogModel.fromMap(maps[i]);
    });
  }

  Future<List<LogModel>> getLogsByRetrievalId(int retrievalId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: StringConstants.retrievalId,
      whereArgs: [retrievalId],
      orderBy: StringConstants.eventDateTimeDESCRetrievedAtDESC,
    );

    return List.generate(maps.length, (i) {
      return LogModel.fromMap(maps[i]);
    });
  }

  Future<List<LogModel>> getLogsBySiteIdAndRetrievedRange(
    int siteId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: StringConstants.siteIdANDRetrievedAtANDRetrievedAt,
      whereArgs: [
        siteId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: StringConstants.eventDateTimeDESCRetrievedAtDESC,
    );

    return List.generate(maps.length, (i) {
      return LogModel.fromMap(maps[i]);
    });
  }

  Future<int> associateLogsWithSite(List<int> logIds, int siteId) async {
    final db = await database;
    final batch = db.batch();

    for (final logId in logIds) {
      batch.update(
        'logs',
        {'site_id': siteId},
        where: 'id = ?',
        whereArgs: [logId],
      );
    }

    final results = await batch.commit();
    return results.length;
  }

  Future<int> deleteLogsBySiteId(int siteId) async {
    final db = await database;
    return await db.delete('logs', where: 'site_id = ?', whereArgs: [siteId]);
  }

  Future<int> deleteOldOrphanedLogs(int daysOld) async {
    final db = await database;
    final cutoffTime =
        DateTime.now().subtract(Duration(days: daysOld)).millisecondsSinceEpoch;

    return await db.delete(
      'logs',
      where: StringConstants.siteIdISNULLANDRetrievedAt,
      whereArgs: [cutoffTime],
    );
  }

  Future<List<Map<String, dynamic>>> getSitesWithLogCount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      DbSql.getSitesWithLogCount,
    );

    return maps;
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      DbSql.getRecentActivity,
      [limit],
    );

    return maps;
  }

  Future<int> upsertPanel(PanelModel panel) async {
    final db = await database;
    final existing = await db.query(
      'panels',
      where: StringConstants.panelId,
      whereArgs: [panel.panelId],
    );

    if (existing.isNotEmpty) {
      final existingSiteId = existing.first['site_id'] as int?;
      final updatedPanel = panel.copyWith(
        id: existing.first['id'] as int,
        siteId: panel.siteId ?? existingSiteId,
        updatedAt: DateTime.now(),
        lastConnected: DateTime.now(),
      );
      await db.update(
        'panels',
        updatedPanel.toMap(),
        where: StringConstants.panelId,
        whereArgs: [panel.panelId],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('panels', panel.toMap());
    }
  }

  Future<PanelModel?> getPanelByPanelId(String panelId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      where: StringConstants.panelId,
      whereArgs: [panelId],
    );

    if (maps.isNotEmpty) {
      return PanelModel.fromMap(maps.first);
    }
    return null;
  }

  Future<PanelModel?> getPanelByPanelName(String panelName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      where: StringConstants.panelName2,
      whereArgs: [panelName],
    );

    if (maps.isNotEmpty) {
      return PanelModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PanelModel>> getPanelsBySiteId(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: StringConstants.siteIdISNULL,
    );

    return List.generate(maps.length, (i) {
      return PanelModel.fromMap(maps[i]);
    });
  }

  Future<List<PanelModel>> getUnassignedPanels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      where: 'site_id IS NULL',
      orderBy: StringConstants.siteIdISNULL,
    );

    return List.generate(maps.length, (i) {
      return PanelModel.fromMap(maps[i]);
    });
  }

  Future<int> assignPanelToSite(String panelId, int siteId) async {
    final db = await database;
    return await db.update(
      'panels',
      {'site_id': siteId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: StringConstants.panelId,
      whereArgs: [panelId],
    );
  }

  Future<int> unassignPanelFromSite(String panelId) async {
    final db = await database;
    return await db.update(
      'panels',
      {'site_id': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: StringConstants.panelId,
      whereArgs: [panelId],
    );
  }

  Future<int> updatePanelLastConnected(String panelId) async {
    final db = await database;
    return await db.update(
      'panels',
      {
        'last_connected': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: StringConstants.panelId,
      whereArgs: [panelId],
    );
  }

  Future<List<PanelModel>> getAllPanels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      orderBy: StringConstants.siteIdISNULL,
    );

    return List.generate(maps.length, (i) {
      return PanelModel.fromMap(maps[i]);
    });
  }

  Future<int> deletePanel(String panelId) async {
    final db = await database;
    return await db.delete(
      'panels',
      where: StringConstants.panelId,
      whereArgs: [panelId],
    );
  }

  Future<int> insertLogRetrieval(LogRetrievalModel logRetrieval) async {
    final db = await database;
    return await db.insert(StringConstants.id2, logRetrieval.toMap());
  }

  Future<List<LogRetrievalModel>> getLogRetrievalsBySite(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      StringConstants.id2,
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: StringConstants.retrievalDateDESC,
    );

    return List.generate(maps.length, (i) {
      return LogRetrievalModel.fromMap(maps[i]);
    });
  }

  Future<LogRetrievalModel?> getLogRetrievalById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      StringConstants.id2,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LogRetrievalModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLogRetrieval(LogRetrievalModel logRetrieval) async {
    final db = await database;
    return await db.update(
      StringConstants.id2,
      logRetrieval.toMap(),
      where: 'id = ?',
      whereArgs: [logRetrieval.id],
    );
  }

  Future<int> deleteLogRetrieval(int id) async {
    final db = await database;
    return await db.delete(
      StringConstants.id2,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getLogRetrievalCountBySite(int siteId) async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            StringConstants.selectCOUNTFROMLogRetrievalsWHERESiteId,
            [siteId],
          ),
        ) ??
        0;
  }

  Future<LogRetrievalModel?> getMostRecentLogRetrieval(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      StringConstants.id2,
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: StringConstants.retrievalDateDESC,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return LogRetrievalModel.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final siteCount =
        Sqflite.firstIntValue(
          await db.rawQuery(StringConstants.selectCOUNTFROMSites),
        ) ??
        0;

    final logCount =
        Sqflite.firstIntValue(await db.rawQuery(DbSql.selectCountFromLogs)) ??
        0;

    final orphanedLogCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            StringConstants.selectCOUNTFROMLogsWHERESiteIdISNULL,
          ),
        ) ??
        0;

    return {
      'sites': siteCount,
      'logs': logCount,
      'orphaned_logs': orphanedLogCount,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), DbSql.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
