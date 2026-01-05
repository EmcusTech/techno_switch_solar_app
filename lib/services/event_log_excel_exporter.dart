import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/log_model.dart';

class EventLogExcelExporter {
  static Future<void> export(List<LogModel> logs) async {
    final excel = Excel.createExcel();
    final sheet = excel['Event Logs'];

    final headers = [
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
    ];

    sheet.appendRow(headers.map(TextCellValue.new).toList());

    for (final log in logs) {
      sheet.appendRow([
        TextCellValue(log.eventId ?? ''),
        TextCellValue(
          log.eventDateTime != null
              ? DateFormat('dd-MM-yyyy HH:mm:ss').format(log.eventDateTime!)
              : '',
        ),
        TextCellValue(log.eventStatus ?? ''),
        TextCellValue(log.eventClass ?? ''),
        TextCellValue(log.eventType ?? ''),
        TextCellValue(log.eventSubType ?? ''),
        TextCellValue(log.eventSource ?? ''),
        TextCellValue(log.identifier ?? ''),
        TextCellValue(log.text ?? ''),
        TextCellValue(log.panelNo ?? ''),
        TextCellValue(log.moduleNo ?? ''),
        TextCellValue(log.lBusNo ?? ''),
      ]);
    }

    // Auto-freeze header row
    sheet.setDefaultRowHeight(18);
    sheet.setColumnAutoFit(0);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/event_logs.xlsx');
    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)], text: 'Event Logs Excel');
  }
}
