import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:Technoswitch/bindings/initial_binding.dart';
import 'package:Technoswitch/features/splash/bindings/splash_binding.dart';
import 'package:Technoswitch/techno_switch_app.dart';
import 'package:Technoswitch/utils/constants/strings/db_sql.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await _configureWindowsDatabasePath();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      center: true,
      title: 'Solar',
      size: Size(1280, 820),
      minimumSize: Size(1280, 820),
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  InitialBinding().dependencies();
  SplashBinding().dependencies();

  await InitialBinding().setAppInitials();

  runApp(const TechnoSwitchApp());
}

/// Keeps SQLite in Local AppData. Roaming AppData is redirected on some
/// domain laptops, and opening the database there never returns.
Future<void> _configureWindowsDatabasePath() async {
  final Directory roamingDir = await getApplicationSupportDirectory();
  final String? localAppData = Platform.environment['LOCALAPPDATA'];
  final Directory dir;
  if (localAppData != null && localAppData.isNotEmpty) {
    final String roamingRoot = Platform.environment['APPDATA'] ?? '';
    final String roamingPath = roamingDir.path;
    final bool underRoaming =
        roamingRoot.isNotEmpty &&
        roamingPath.toLowerCase().startsWith(roamingRoot.toLowerCase());
    final String relative =
        underRoaming
            ? roamingPath
                .substring(roamingRoot.length)
                .replaceFirst(RegExp(r'^[\\/]+'), '')
            : p.join('com.example', 'Technoswitch');
    final String folder =
        relative.isEmpty ? p.join('com.example', 'Technoswitch') : relative;
    dir = Directory(p.join(localAppData, folder));
  } else {
    dir = roamingDir;
  }

  await dir.create(recursive: true);
  if (p.normalize(dir.path).toLowerCase() !=
      p.normalize(roamingDir.path).toLowerCase()) {
    await _copyDatabaseIfMissing(from: roamingDir, to: dir);
  }
  await databaseFactory.setDatabasesPath(dir.path);
}

Future<void> _copyDatabaseIfMissing({
  required Directory from,
  required Directory to,
}) async {
  final File oldDb = File(p.join(from.path, DbSql.dbName));
  final File newDb = File(p.join(to.path, DbSql.dbName));
  if (await newDb.exists() || !await oldDb.exists()) return;

  await oldDb.copy(newDb.path);
  for (final String suffix in const ['-wal', '-shm']) {
    final File extra = File('${oldDb.path}$suffix');
    if (await extra.exists()) {
      await extra.copy('${newDb.path}$suffix');
    }
  }
}
