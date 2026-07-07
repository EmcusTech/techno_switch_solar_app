/// SQL fragments and migration statements.
abstract final class DbSql {
  static const String dbName = 'techno_switch_solar.db';
  static const String sitesOrderByCreatedAtDesc = 'created_at DESC';
  static const String lastConnectedThenCreatedAtDesc =
      'last_connected DESC, created_at DESC';

  static const String createIndexLogRetrievalsRetrievalDate =
      'CREATE INDEX idx_log_retrievals_retrieval_date ON log_retrievals (retrieval_date)';
  static const String createIndexLogRetrievalsSiteId =
      'CREATE INDEX idx_log_retrievals_site_id ON log_retrievals (site_id)';
  static const String createIndexLogsEventDate =
      'CREATE INDEX idx_logs_event_date ON logs (event_date_time)';
  static const String createIndexLogsRetrievalId =
      'CREATE INDEX idx_logs_retrieval_id ON logs (retrieval_id)';
  static const String createIndexLogsSiteId =
      'CREATE INDEX idx_logs_site_id ON logs (site_id)';
  static const String createIndexPanelsSiteId =
      'CREATE INDEX idx_panels_site_id ON panels (site_id)';
  static const String createIndexSitesCreatedAt =
      "CREATE INDEX idx_sites_created_at ON sites (created_at)";
  static const String createIndexPanelsPanelId =
      'CREATE INDEX idx_panels_panel_id ON panels (panel_id)';

  static const String selectCountFromLogs = 'SELECT COUNT(*) FROM logs';

  static const String createPanelsTable = '''
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
      ''';

  static const String createSitesTable = '''
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
    ''';

  static const String createLogRetrievalsTable = '''
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
      ''';

  static const String createLogsTable = '''
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
    ''';

  static const String getSitesWithLogCount = '''
      SELECT 
        s.*,
        COUNT(l.id) as log_count,
        MAX(l.retrieved_at) as last_log_retrieved
      FROM sites s 
      LEFT JOIN logs l ON s.id = l.site_id 
      GROUP BY s.id 
      ORDER BY s.created_at DESC
    ''';

  static const String getRecentActivity = '''
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
    ''';

  static const String alterTableLogsAddIsValid =
      'ALTER TABLE logs ADD COLUMN is_valid INTEGER';
  static const String alterTableLogsAddRetrievalId =
      'ALTER TABLE logs ADD COLUMN retrieval_id INTEGER';
}
