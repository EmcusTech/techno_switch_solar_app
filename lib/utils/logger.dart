import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

enum LogType { main, ble }

class Logger {
  static final Logger _instance = Logger._internal();

  static File? _mainLogFile;
  static File? _bleLogFile;

  static bool _isInitialized = false;

  Logger._internal();

  factory Logger(String message, {LogType type = LogType.main}) {
    final String timestamp = _timestamp();
    final String formatted = "[$timestamp] $message";

    FlutterLogs.logThis(
      tag: type == LogType.main ? "TechnoSwitchLogs" : "BLELogs",
      subTag: StringConstants.logdata,
      logMessage: formatted,
      level: LogLevel.INFO,
    );

    _writeToFile(formatted, type);

    return _instance;
  }

  static String _timestamp() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
  }

  static Future<void> _initializeLogFiles() async {
    if (_isInitialized) return;

    try {
      Directory? directory = await getExternalStorageDirectory();
      directory ??= await getApplicationDocumentsDirectory();

      final basePath = directory.path;
      final date = _dateString();

      _mainLogFile = File("$basePath/technoswitch_main_$date.txt");
      _bleLogFile = File("$basePath/technoswitch_ble_$date.txt");

      if (!await _mainLogFile!.exists()) {
        await _mainLogFile!.create(recursive: true);
        await _mainLogFile!.writeAsString(
          "=== TechnoSwitch MAIN Log ===\nCreated: ${DateTime.now()}\n================================\n\n",
        );
      }

      if (!await _bleLogFile!.exists()) {
        await _bleLogFile!.create(recursive: true);
        await _bleLogFile!.writeAsString(
          "=== TechnoSwitch BLE Log ===\nCreated: ${DateTime.now()}\n================================\n\n",
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint("Logger init failed: $e");
    }
  }

  static String _dateString() {
    final now = DateTime.now();
    return "${now.year}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}";
  }

  static Future<void> _writeToFile(String message, LogType type) async {
    try {
      if (!_isInitialized) {
        await _initializeLogFiles();
      }

      File? target = type == LogType.main ? _mainLogFile : _bleLogFile;

      if (target != null) {
        await target.writeAsString("$message\n", mode: FileMode.append);
      }
    } catch (e) {
      debugPrint("Failed writing log: $e");
    }
  }

  static Future<String?> getLogFilePath({LogType type = LogType.main}) async {
    if (!_isInitialized) {
      await _initializeLogFiles();
    }

    return type == LogType.main ? _mainLogFile?.path : _bleLogFile?.path;
  }

  static Future<void> clearLogFile({LogType type = LogType.main}) async {
    try {
      if (!_isInitialized) {
        await _initializeLogFiles();
      }

      final file = type == LogType.main ? _mainLogFile : _bleLogFile;

      if (file != null && await file.exists()) {
        await file.writeAsString(
          "=== Cleared ${type.name.toUpperCase()} log ===\nTime: ${DateTime.now()}\n================================\n\n",
          mode: FileMode.write,
        );
      }
    } catch (e) {
      debugPrint("Failed to clear log: $e");
    }
  }
}
