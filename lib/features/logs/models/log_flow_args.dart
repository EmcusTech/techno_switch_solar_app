import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/scanning_screen.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

enum LogFlowMode { history, loading, completed, failed, eventLog }

class LogFlowArgs {
  const LogFlowArgs({required this.mode, this.history, this.loading, this.completed, this.eventLog});

  final LogFlowMode mode;
  final LogHistoryArgs? history;
  final LogLoadingArgs? loading;
  final LogCompletedArgs? completed;
  final LogEventLogArgs? eventLog;

  factory LogFlowArgs.history({
    required String panelName,
    required String panelVersionNo,
    required int? siteId,
  }) {
    return LogFlowArgs(
      mode: LogFlowMode.history,
      history: LogHistoryArgs(
        panelName: panelName,
        panelVersionNo: panelVersionNo,
        siteId: siteId,
      ),
    );
  }

  factory LogFlowArgs.loading({
    dynamic selectedDevice,
    required ScanType scanType,
    bool isLiveEvent = false,
    DiscoveredDevice? connectedDevice,
    String? panelId,
  }) {
    return LogFlowArgs(
      mode: LogFlowMode.loading,
      loading: LogLoadingArgs(
        selectedDevice: selectedDevice,
        scanType: scanType,
        isLiveEvent: isLiveEvent,
        connectedDevice: connectedDevice,
        panelId: panelId,
      ),
    );
  }

  factory LogFlowArgs.completed({
    required List<LogModel> logs,
    required String panelId,
    required String panelName,
    DiscoveredDevice? connectedDevice,
    bool isDirectLogRet = false,
  }) {
    return LogFlowArgs(
      mode: LogFlowMode.completed,
      completed: LogCompletedArgs(
        logs: logs,
        panelId: panelId,
        panelName: panelName,
        connectedDevice: connectedDevice,
        isDirectLogRet: isDirectLogRet,
      ),
    );
  }

  factory LogFlowArgs.failed() {
    return const LogFlowArgs(mode: LogFlowMode.failed);
  }

  factory LogFlowArgs.eventLog({
    required List<LogModel> logDataList,
    required String panelVersionNo,
    required String panelName,
    bool isStandalone = false,
    String? panelId,
    bool isHistoryView = false,
    DiscoveredDevice? connectedDevice,
    int? siteId,
    bool isLiveEventLogs = false,
    bool isDirectLogRet = false,
  }) {
    return LogFlowArgs(
      mode: LogFlowMode.eventLog,
      eventLog: LogEventLogArgs(
        logDataList: logDataList,
        panelVersionNo: panelVersionNo,
        panelName: panelName,
        isStandalone: isStandalone,
        panelId: panelId,
        isHistoryView: isHistoryView,
        connectedDevice: connectedDevice,
        siteId: siteId,
        isLiveEventLogs: isLiveEventLogs,
        isDirectLogRet: isDirectLogRet,
      ),
    );
  }
}

class LogHistoryArgs {
  const LogHistoryArgs({
    required this.panelName,
    required this.panelVersionNo,
    required this.siteId,
  });

  final String panelName;
  final String panelVersionNo;
  final int? siteId;
}

class LogLoadingArgs {
  const LogLoadingArgs({
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
    this.connectedDevice,
    this.panelId,
  });

  final dynamic selectedDevice;
  final ScanType scanType;
  final bool isLiveEvent;
  final DiscoveredDevice? connectedDevice;
  final String? panelId;
}

class LogCompletedArgs {
  const LogCompletedArgs({
    required this.logs,
    required this.panelId,
    required this.panelName,
    this.connectedDevice,
    this.isDirectLogRet = false,
  });

  final List<LogModel> logs;
  final String panelId;
  final String panelName;
  final DiscoveredDevice? connectedDevice;
  final bool isDirectLogRet;
}

class LogEventLogArgs {
  const LogEventLogArgs({
    required this.logDataList,
    required this.panelVersionNo,
    required this.panelName,
    this.isStandalone = false,
    this.panelId,
    this.isHistoryView = false,
    this.connectedDevice,
    this.siteId,
    this.isLiveEventLogs = false,
    this.isDirectLogRet = false,
  });

  final List<LogModel> logDataList;
  final String panelVersionNo;
  final String panelName;
  final bool isStandalone;
  final String? panelId;
  final bool isHistoryView;
  final DiscoveredDevice? connectedDevice;
  final int? siteId;
  final bool isLiveEventLogs;
  final bool isDirectLogRet;
}
