import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/log_model.dart';

class EventLogPdfExporter {
  static Future<void> export({
    required List<LogModel> logs,
    required String panelName,
    required String panelVersion,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build:
            (context) => [
              _buildHeader(panelName, panelVersion),
              pw.SizedBox(height: 16),
              _buildTable(logs),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'event_logs_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(String panelName, String panelVersion) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Event Logs Report',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Panel: $panelName'),
        pw.Text('Version: $panelVersion'),
        pw.Text(
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
        ),
      ],
    );
  }

  static pw.Widget _buildTable(List<LogModel> logs) {
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

    final data =
        logs.map((log) {
          return [
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
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
      },
    );
  }
}
