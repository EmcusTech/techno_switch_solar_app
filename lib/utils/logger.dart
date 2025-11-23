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
    FlutterLogs.logThis(
      tag: 'TechnoSwitchLogs',
      subTag: 'logData',
      logMessage: message,
      level: LogLevel.INFO,
    );

    return _instance;
  }

  Logger._internal();
}
