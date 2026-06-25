import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

enum PanelConnectionState { notConnected, connected, processing }

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
