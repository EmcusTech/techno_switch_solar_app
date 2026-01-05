import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/log_model.dart';

class EventLogCsvExporter {
  static Future<void> export(List<LogModel> logs) async {
    final rows = <List<String>>[];

    // Header
    rows.add([
      'ID',
      'Date & Time',
      'Status',
      'Class',
      'Type',
      'Sub Type',
      'Source',
      'Identifier',
      'Text',
      'Panel No',
      'Module No',
      'L-Bus No',
    ]);

    // Data
    for (final log in logs) {
      rows.add([
        log.eventId ?? '',
        log.eventDateTime != null
            ? DateFormat('dd-MM-yyyy HH:mm:ss').format(log.eventDateTime!)
            : '',
        log.eventStatus ?? '',
        log.eventClass ?? '',
        log.eventType ?? '',
        log.eventSubType ?? '',
        log.eventSource ?? '',
        log.identifier ?? '',
        log.text ?? '',
        log.panelNo ?? '',
        log.moduleNo ?? '',
        log.lBusNo ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/event_logs.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Event Logs CSV');
  }
}
