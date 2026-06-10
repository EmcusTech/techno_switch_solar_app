import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

class AppState {
  AppState._internal();
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  static AppState get instance => _instance;

  static final ValueNotifier<PanelConnectionState> connectionState =
      ValueNotifier(PanelConnectionState.notConnected);

  static final ValueNotifier<int> logsCount = ValueNotifier(0);

  static final ValueNotifier<List<LogModel>> currentLogs =
      ValueNotifier<List<LogModel>>([]);

  static final ValueNotifier<String> connectionStatus = ValueNotifier(
    'Disconnected',
  );

  static final ValueNotifier<String?> connectedDeviceName =
      ValueNotifier<String?>(null);

  static final ValueNotifier<double> logRetrievalProgress = ValueNotifier(0.0);

  static final ValueNotifier<bool> isRetrievingLogs = ValueNotifier(false);

  static void updateConnectionState(PanelConnectionState state) {
    connectionState.value = state;
  }

  static void updateLogsCount(int count) {
    logsCount.value = count;
  }

  static void addLog(LogModel log) {
    final currentLogsList = List<LogModel>.from(currentLogs.value);
    currentLogsList.insert(0, log);
    currentLogs.value = currentLogsList;
    updateLogsCount(currentLogsList.length);
  }

  static void setLogs(List<LogModel> logs) {
    currentLogs.value = logs;
    updateLogsCount(logs.length);
  }

  static void clearLogs() {
    currentLogs.value = [];
    updateLogsCount(0);
  }

  static void updateConnectionStatus(String status) {
    connectionStatus.value = status;
  }

  static void updateConnectedDeviceName(String? deviceName) {
    connectedDeviceName.value = deviceName;
  }

  static void updateLogRetrievalProgress(double progress) {
    logRetrievalProgress.value = progress;
  }

  static void setLogRetrievalStatus(bool isRetrieving) {
    isRetrievingLogs.value = isRetrieving;
    if (!isRetrieving) {
      logRetrievalProgress.value = 0.0;
    }
  }

  static void reset() {
    connectionState.value = PanelConnectionState.notConnected;
    logsCount.value = 0;
    currentLogs.value = [];
    connectionStatus.value = 'Disconnected';
    connectedDeviceName.value = null;
    logRetrievalProgress.value = 0.0;
    isRetrievingLogs.value = false;
  }

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
