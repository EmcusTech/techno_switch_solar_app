import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

/// Global state management for the application
class AppState {
  // Private constructor for singleton pattern
  AppState._internal();
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  static AppState get instance => _instance;

  // Connection state notifier
  static final ValueNotifier<PanelConnectionState> connectionState =
      ValueNotifier(PanelConnectionState.notConnected);

  // Logs count notifier
  static final ValueNotifier<int> logsCount = ValueNotifier(0);

  // Current logs list notifier
  static final ValueNotifier<List<LogModel>> currentLogs =
      ValueNotifier<List<LogModel>>([]);

  // Connection status message notifier
  static final ValueNotifier<String> connectionStatus = ValueNotifier(
    'Disconnected',
  );

  // Device name notifier
  static final ValueNotifier<String?> connectedDeviceName =
      ValueNotifier<String?>(null);

  // Log retrieval progress notifier (0.0 to 1.0)
  static final ValueNotifier<double> logRetrievalProgress = ValueNotifier(0.0);

  // Is log retrieval in progress
  static final ValueNotifier<bool> isRetrievingLogs = ValueNotifier(false);

  /// Update connection state
  static void updateConnectionState(PanelConnectionState state) {
    connectionState.value = state;
  }

  /// Update logs count
  static void updateLogsCount(int count) {
    logsCount.value = count;
  }

  /// Add a new log to the current logs list
  static void addLog(LogModel log) {
    final currentLogsList = List<LogModel>.from(currentLogs.value);
    currentLogsList.insert(0, log); // Add at the beginning
    currentLogs.value = currentLogsList;
    updateLogsCount(currentLogsList.length);
  }

  /// Set the complete logs list
  static void setLogs(List<LogModel> logs) {
    currentLogs.value = logs;
    updateLogsCount(logs.length);
  }

  /// Clear all logs
  static void clearLogs() {
    currentLogs.value = [];
    updateLogsCount(0);
  }

  /// Update connection status message
  static void updateConnectionStatus(String status) {
    connectionStatus.value = status;
  }

  /// Update connected device name
  static void updateConnectedDeviceName(String? deviceName) {
    connectedDeviceName.value = deviceName;
  }

  /// Update log retrieval progress
  static void updateLogRetrievalProgress(double progress) {
    logRetrievalProgress.value = progress;
  }

  /// Set log retrieval status
  static void setLogRetrievalStatus(bool isRetrieving) {
    isRetrievingLogs.value = isRetrieving;
    if (!isRetrieving) {
      logRetrievalProgress.value = 0.0;
    }
  }

  /// Reset all state to initial values
  static void reset() {
    connectionState.value = PanelConnectionState.notConnected;
    logsCount.value = 0;
    currentLogs.value = [];
    connectionStatus.value = 'Disconnected';
    connectedDeviceName.value = null;
    logRetrievalProgress.value = 0.0;
    isRetrievingLogs.value = false;
  }

  /// Dispose all notifiers (call when app is closing)
  static void dispose() {
    connectionState.dispose();
    logsCount.dispose();
    currentLogs.dispose();
    connectionStatus.dispose();
    connectedDeviceName.dispose();
    logRetrievalProgress.dispose();
    isRetrievingLogs.dispose();
  }
}
