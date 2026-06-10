import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/site_model.dart';
import '../models/log_model.dart';
import '../models/panel_model.dart';
import '../models/log_retrieval_model.dart';

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
    String path = join(await getDatabasesPath(), 'techno_switch_solar.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_name TEXT NOT NULL,
        installer_name TEXT NOT NULL,
        company_name TEXT NOT NULL,
        saqcc_reg_number TEXT NOT NULL,
        building_name TEXT NOT NULL,
        installer_contact_number TEXT NOT NULL,
        installer_email TEXT NOT NULL,
        site_description TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE log_retrievals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_id INTEGER NOT NULL,
        session_name TEXT NOT NULL,
        log_count INTEGER NOT NULL,
        retrieval_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_id INTEGER,
        retrieval_id INTEGER,
        panel_text TEXT,
        event_id TEXT,
        event_date_time INTEGER,
        panel_no TEXT,
        l_bus_no TEXT,
        module_no TEXT,
        event_status TEXT,
        event_class TEXT,
        event_source TEXT,
        event_type TEXT,
        event_sub_type TEXT,
        identifier TEXT,
        text TEXT,
        retrieved_at INTEGER NOT NULL,
        is_valid INTEGER,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE,
        FOREIGN KEY (retrieval_id) REFERENCES log_retrievals (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE panels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        panel_id TEXT NOT NULL UNIQUE,
        panel_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        device_info TEXT NOT NULL,
        site_id INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_connected INTEGER,
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_logs_site_id ON logs (site_id)');
    await db.execute(
      'CREATE INDEX idx_logs_event_date ON logs (event_date_time)',
    );
    await db.execute(
      'CREATE INDEX idx_logs_retrieval_id ON logs (retrieval_id)',
    );
    await db.execute('CREATE INDEX idx_sites_created_at ON sites (created_at)');
    await db.execute('CREATE INDEX idx_panels_panel_id ON panels (panel_id)');
    await db.execute('CREATE INDEX idx_panels_site_id ON panels (site_id)');
    await db.execute(
      'CREATE INDEX idx_log_retrievals_site_id ON log_retrievals (site_id)',
    );
    await db.execute(
      'CREATE INDEX idx_log_retrievals_retrieval_date ON log_retrievals (retrieval_date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE panels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          panel_id TEXT NOT NULL UNIQUE,
          panel_name TEXT NOT NULL,
          device_type TEXT NOT NULL,
          device_info TEXT NOT NULL,
          site_id INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_connected INTEGER,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('CREATE INDEX idx_panels_panel_id ON panels (panel_id)');
      await db.execute('CREATE INDEX idx_panels_site_id ON panels (site_id)');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE log_retrievals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          site_id INTEGER NOT NULL,
          session_name TEXT NOT NULL,
          log_count INTEGER NOT NULL,
          retrieval_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_log_retrievals_site_id ON log_retrievals (site_id)',
      );
      await db.execute(
        'CREATE INDEX idx_log_retrievals_retrieval_date ON log_retrievals (retrieval_date)',
      );
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE logs ADD COLUMN is_valid INTEGER');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE logs ADD COLUMN retrieval_id INTEGER');
      await db.execute(
        'CREATE INDEX idx_logs_retrieval_id ON logs (retrieval_id)',
      );
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
      orderBy: 'created_at DESC',
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
      await txn.delete('log_retrievals', where: 'site_id = ?', whereArgs: [id]);
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
      orderBy: 'created_at DESC',
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
      orderBy: 'event_date_time DESC, retrieved_at DESC',
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
      orderBy: 'retrieved_at DESC',
    );

    return List.generate(maps.length, (i) {
      return LogModel.fromMap(maps[i]);
    });
  }

  Future<List<LogModel>> getLogsByRetrievalId(int retrievalId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: 'retrieval_id = ?',
      whereArgs: [retrievalId],
      orderBy: 'event_date_time DESC, retrieved_at DESC',
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
      where: 'site_id = ? AND retrieved_at >= ? AND retrieved_at < ?',
      whereArgs: [
        siteId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'event_date_time DESC, retrieved_at DESC',
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
      where: 'site_id IS NULL AND retrieved_at < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<List<Map<String, dynamic>>> getSitesWithLogCount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        s.*,
        COUNT(l.id) as log_count,
        MAX(l.retrieved_at) as last_log_retrieved
      FROM sites s 
      LEFT JOIN logs l ON s.id = l.site_id 
      GROUP BY s.id 
      ORDER BY s.created_at DESC
    ''');

    return maps;
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        s.id as site_id,
        s.site_name,
        s.installer_name,
        s.company_name,
        s.created_at as site_created_at,
        l.id as log_id,
        l.event_type,
        l.event_date_time,
        l.retrieved_at,
        CASE 
          WHEN l.retrieved_at IS NOT NULL THEN l.retrieved_at
          ELSE s.created_at
        END as activity_time
      FROM sites s 
      LEFT JOIN logs l ON s.id = l.site_id 
      ORDER BY activity_time DESC 
      LIMIT ?
    ''',
      [limit],
    );

    return maps;
  }

  Future<int> upsertPanel(PanelModel panel) async {
    final db = await database;
    final existing = await db.query(
      'panels',
      where: 'panel_id = ?',
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
        where: 'panel_id = ?',
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
      where: 'panel_id = ?',
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
      where: 'panel_name = ?',
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
      orderBy: 'last_connected DESC, created_at DESC',
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
      orderBy: 'last_connected DESC, created_at DESC',
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
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  Future<int> unassignPanelFromSite(String panelId) async {
    final db = await database;
    return await db.update(
      'panels',
      {'site_id': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'panel_id = ?',
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
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  Future<List<PanelModel>> getAllPanels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panels',
      orderBy: 'last_connected DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PanelModel.fromMap(maps[i]);
    });
  }

  Future<int> deletePanel(String panelId) async {
    final db = await database;
    return await db.delete(
      'panels',
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  Future<int> insertLogRetrieval(LogRetrievalModel logRetrieval) async {
    final db = await database;
    return await db.insert('log_retrievals', logRetrieval.toMap());
  }

  Future<List<LogRetrievalModel>> getLogRetrievalsBySite(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'log_retrievals',
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: 'retrieval_date DESC',
    );

    return List.generate(maps.length, (i) {
      return LogRetrievalModel.fromMap(maps[i]);
    });
  }

  Future<LogRetrievalModel?> getLogRetrievalById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'log_retrievals',
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
      'log_retrievals',
      logRetrieval.toMap(),
      where: 'id = ?',
      whereArgs: [logRetrieval.id],
    );
  }

  Future<int> deleteLogRetrieval(int id) async {
    final db = await database;
    return await db.delete('log_retrievals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getLogRetrievalCountBySite(int siteId) async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM log_retrievals WHERE site_id = ?',
            [siteId],
          ),
        ) ??
        0;
  }

  Future<LogRetrievalModel?> getMostRecentLogRetrieval(int siteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'log_retrievals',
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: 'retrieval_date DESC',
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
          await db.rawQuery('SELECT COUNT(*) FROM sites'),
        ) ??
        0;

    final logCount =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM logs')) ??
        0;

    final orphanedLogCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM logs WHERE site_id IS NULL'),
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
    String path = join(await getDatabasesPath(), 'techno_switch_solar.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
