import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

class LogReportPdfUtil {
  LogReportPdfUtil._();

  static final DateFormat _dtFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  // ─────────────────────────────────────────────
  // ENTRY POINT
  // ─────────────────────────────────────────────

  static Future<void> generate({
    required List<LogModel> logs,
    required String siteName,
    required String panelName,
    required String panelSerialNumber,
    required String installerName,
    required String saqccNo,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadImage('assets/images/logo.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),

        header: (context) => _header(context, logo),
        footer: _footer,

        build:
            (_) => [
              _reportInfo(
                siteName: siteName,
                panelName: panelName,
                panelSerialNumber: panelSerialNumber,
                installerName: installerName,
                saqccNo: saqccNo,
              ),
              pw.SizedBox(height: 16),
              _logTable(logs),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  static pw.Widget _header(pw.Context context, pw.MemoryImage logo) {
    final isFirst = context.pageNumber == 1;

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(logo, width: isFirst ? 80 : 50),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Log Retrieval Report',
                style: pw.TextStyle(
                  fontSize: isFirst ? 14 : 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (isFirst)
                pw.Text(
                  _dtFormat.format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REPORT INFO (ONLY PAGE 1)
  // ─────────────────────────────────────────────

  static pw.Widget _reportInfo({
    required String siteName,
    required String panelName,
    required String panelSerialNumber,
    required String installerName,
    required String saqccNo,
  }) {
    pw.Widget item(String label, String value) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),
          pw.Text(
            value.isEmpty ? '-' : value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Wrap(
        spacing: 40,
        runSpacing: 12,
        children: [
          item('Site Name', siteName),
          item('Panel Name', panelName),
          item('Panel Serial Number', panelSerialNumber),
          item('Installer Name', installerName),
          item('SAQCC No', saqccNo),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOG TABLE
  // ─────────────────────────────────────────────

  static pw.Widget _logTable(List<LogModel> logs) {
    if (logs.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No log entries available',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

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
    ];

    final rows =
        logs.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final log = entry.value;

          return [
            index.toString(),
            _formatDate(log.eventDateTime),
            _safe(log.eventStatus),
            _safe(log.eventClass),
            _safe(log.eventType),
            _safe(log.eventSubType),
            _safe(log.eventSource),
            _safe(log.identifier),
            _safe(log.text),
          ];
        }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 7),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(35),
      },
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────

  static pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'Page ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static String _safe(String? value) =>
      (value == null || value.isEmpty) ? '-' : value;

  static String _formatDate(DateTime? dt) =>
      dt == null ? '-' : _dtFormat.format(dt);

  static Future<pw.MemoryImage> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }
}
