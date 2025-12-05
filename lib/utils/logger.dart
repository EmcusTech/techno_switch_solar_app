/*
* Project      : gemini-en54-2-mobile_app
* File         : logger.dart
* Description  : Singleton instance that formats and prints debug messages prefixed with a timestamp in a specified format, designed for logging purposes
* Author       : SrihariharanT
* Date         : 2024-06-21
* Version      : 1.0
* Ticket       : 
*/

import 'package:flutter_logs/flutter_logs.dart';

class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger(String message) {
    // Get current timestamp
    final DateTime now = DateTime.now();
    final String timestamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    // Format: [timestamp] message
    final String messageWithTimestamp = '[$timestamp] $message';

    FlutterLogs.logThis(
      tag: 'TechnoSwitchLogs',
      subTag: 'logData',
      logMessage: messageWithTimestamp,
      level: LogLevel.INFO,
    );

    return _instance;
  }

  Logger._internal();
}
