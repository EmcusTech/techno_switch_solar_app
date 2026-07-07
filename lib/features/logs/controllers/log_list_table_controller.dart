import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Scoped controller for interactive column sorting in the event log list table.
///
/// Registered by [_LogListView] via `Get.put` and deleted on dispose. Keeps
/// table-only sort state out of [LogController].
class LogListTableController extends GetxController {
  LogListTableController({required List<LogModel> displayLogs}) {
    _displayLogs = List<LogModel>.from(displayLogs);
    _rebuildSortedLogs();
  }

  late List<LogModel> _displayLogs;
  List<LogModel> sortedLogs = [];

  String? sortColumn;
  bool sortAscending = true;

  void updateDisplayLogs(List<LogModel> displayLogs) {
    _displayLogs = List<LogModel>.from(displayLogs);
    _rebuildSortedLogs();
    update();
  }

  void sortByColumn(String column) {
    if (sortColumn == column) {
      if (sortAscending) {
        sortAscending = false;
      } else {
        sortColumn = null;
        sortAscending = true;
        _rebuildSortedLogs();
        update();
        return;
      }
    } else {
      sortColumn = column;
      sortAscending = true;
    }

    _rebuildSortedLogs();
    update();
  }

  void _rebuildSortedLogs() {
    sortedLogs = List<LogModel>.from(_displayLogs);
    if (sortColumn == null) return;
    sortedLogs.sort(
      (a, b) => _compareLogs(a, b, sortColumn!, sortAscending),
    );
  }

  static int _compareLogs(
    LogModel a,
    LogModel b,
    String column,
    bool ascending,
  ) {
    var comparison = 0;

    switch (column) {
      case StringConstants.eventid:
        final aId = int.tryParse(a.eventId ?? '0') ?? 0;
        final bId = int.tryParse(b.eventId ?? '0') ?? 0;
        comparison = aId.compareTo(bId);
      case StringConstants.datetime:
        if (a.eventDateTime != null && b.eventDateTime != null) {
          comparison = a.eventDateTime!.compareTo(b.eventDateTime!);
        } else if (a.eventDateTime != null) {
          comparison = 1;
        } else if (b.eventDateTime != null) {
          comparison = -1;
        }
      case 'status':
        comparison = (a.eventStatus ?? '').compareTo(b.eventStatus ?? '');
      case 'class':
        comparison = (a.eventClass ?? '').compareTo(b.eventClass ?? '');
      case 'type':
        comparison = (a.eventType ?? '').compareTo(b.eventType ?? '');
      case StringConstants.subtype:
        comparison = (a.eventSubType ?? '').compareTo(b.eventSubType ?? '');
      case 'source':
        comparison = (a.eventSource ?? '').compareTo(b.eventSource ?? '');
      case 'identifier':
        comparison = (a.identifier ?? '').compareTo(b.identifier ?? '');
      case 'text':
        comparison = (a.text ?? '').compareTo(b.text ?? '');
      case StringConstants.panelno:
        comparison = (a.panelNo ?? '').compareTo(b.panelNo ?? '');
      case StringConstants.moduleno:
        comparison = (a.moduleNo ?? '').compareTo(b.moduleNo ?? '');
      case StringConstants.lbusno:
        comparison = (a.lBusNo ?? '').compareTo(b.lBusNo ?? '');
    }

    return ascending ? comparison : -comparison;
  }
}
