import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/site_model.dart';
import '../models/log_model.dart';
import '../models/panel_model.dart';

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
      version: 2, // Increment version to add panels table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sites table
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

    // Create logs table
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_id INTEGER,
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
        FOREIGN KEY (site_id) REFERENCES sites (id) ON DELETE CASCADE
      )
    ''');

    // Create panels table
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

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_logs_site_id ON logs (site_id)');
    await db.execute(
      'CREATE INDEX idx_logs_event_date ON logs (event_date_time)',
    );
    await db.execute('CREATE INDEX idx_sites_created_at ON sites (created_at)');
    await db.execute('CREATE INDEX idx_panels_panel_id ON panels (panel_id)');
    await db.execute('CREATE INDEX idx_panels_site_id ON panels (site_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add panels table if upgrading from version 1
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
  }

  // SITE OPERATIONS

  /// Insert a new site into the database
  Future<int> insertSite(SiteModel site) async {
    final db = await database;
    return await db.insert('sites', site.toMap());
  }

  /// Get all sites from the database, ordered by most recent first
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

  /// Get a specific site by ID
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

  /// Update an existing site
  Future<int> updateSite(SiteModel site) async {
    final db = await database;
    return await db.update(
      'sites',
      site.toMap(),
      where: 'id = ?',
      whereArgs: [site.id],
    );
  }

  /// Delete a site and all its associated logs
  Future<int> deleteSite(int id) async {
    final db = await database;
    return await db.delete('sites', where: 'id = ?', whereArgs: [id]);
  }

  /// Search sites by name
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

  // LOG OPERATIONS

  /// Insert a new log into the database
  Future<int> insertLog(LogModel log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  /// Insert multiple logs in a transaction for better performance
  Future<void> insertLogs(List<LogModel> logs) async {
    final db = await database;
    final batch = db.batch();

    for (final log in logs) {
      batch.insert('logs', log.toMap());
    }

    await batch.commit(noResult: true);
  }

  /// Get all logs for a specific site
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

  /// Get all logs that are not associated with any site (orphaned logs)
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

  /// Update logs to associate them with a site
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

  /// Delete logs for a specific site
  Future<int> deleteLogsBySiteId(int siteId) async {
    final db = await database;
    return await db.delete('logs', where: 'site_id = ?', whereArgs: [siteId]);
  }

  /// Delete orphaned logs older than specified days
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

  // COMBINED OPERATIONS

  /// Get site with its log count
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

  /// Get recent activity (sites and their latest logs)
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

  // PANEL OPERATIONS

  /// Insert or update a panel (upsert based on panel_id)
  Future<int> upsertPanel(PanelModel panel) async {
    final db = await database;

    // Check if panel already exists
    final existing = await db.query(
      'panels',
      where: 'panel_id = ?',
      whereArgs: [panel.panelId],
    );

    if (existing.isNotEmpty) {
      // Update existing panel - preserve siteId if it exists and panel.siteId is null
      final existingSiteId = existing.first['site_id'] as int?;
      final updatedPanel = panel.copyWith(
        id: existing.first['id'] as int,
        siteId:
            panel.siteId ??
            existingSiteId, // Preserve existing siteId if new one is null
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
      // Insert new panel
      return await db.insert('panels', panel.toMap());
    }
  }

  /// Get panel by panel_id
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

  /// Get all panels for a specific site
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

  /// Get all panels that are not associated with any site
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

  /// Associate a panel with a site
  Future<int> assignPanelToSite(String panelId, int siteId) async {
    final db = await database;
    return await db.update(
      'panels',
      {'site_id': siteId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  /// Remove panel from site (unassign)
  Future<int> unassignPanelFromSite(String panelId) async {
    final db = await database;
    return await db.update(
      'panels',
      {'site_id': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  /// Update panel last connected time
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

  /// Get all panels
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

  /// Delete a panel
  Future<int> deletePanel(String panelId) async {
    final db = await database;
    return await db.delete(
      'panels',
      where: 'panel_id = ?',
      whereArgs: [panelId],
    );
  }

  // DATABASE MAINTENANCE

  /// Get database statistics
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

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Delete the entire database (for testing purposes)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'techno_switch_solar.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
