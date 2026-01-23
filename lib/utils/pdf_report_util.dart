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
    final logo = await _loadImage('assets/images/full_logo.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          PdfPageFormat.a4.height,
          PdfPageFormat.a4.width,
        ),

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
              _sectionHeader('LOG ENTRIES'),
              _logTable(logs),
            ],
      ),
    );

    final fileName =
        'logs_${DateFormat('dd/MM/yyyy_HH:mm:ss').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      name: fileName,
      format: PdfPageFormat(PdfPageFormat.a4.height, PdfPageFormat.a4.width),
      onLayout: (format) async => pdf.save(),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  static pw.Widget _sectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.red,
        ),
      ),
    );
  }

  static pw.Widget _header(pw.Context context, pw.MemoryImage logo) {
    final isFirst = context.pageNumber == 1;

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(logo, width: 150),
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
    pw.Widget item(String title, String value) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value.isEmpty ? '-' : value,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('REPORT INFO'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            item('Site Name', siteName),
            item('Panel Name', panelName),
            item('Panel Serial Number', panelSerialNumber),
            item('Installer Name', installerName),
            item('SAQCC No', saqccNo),
          ],
        ),
        pw.Divider(color: PdfColor.fromInt(0xFFD9D9D9)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LOG TABLE
  // ─────────────────────────────────────────────

  static pw.Widget _logTable(List<LogModel> logs) {
    if (logs.isEmpty) {
      return pw.Text('No log entries available');
    }

    pw.Widget headerCell(String text, {double width = 60}) {
      return pw.Container(
        width: width,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    pw.Widget cell(String text, {double width = 60}) {
      return pw.Container(
        width: width,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
      );
    }

    pw.Widget statusPill(String status) {
      PdfColor bg;
      PdfColor fg;

      switch (status.toLowerCase()) {
        case 'logged':
          bg = PdfColor.fromInt(0xFFE6F4EA);
          fg = PdfColor.fromInt(0xFF1E7F43);
          break;
        case 'active':
          bg = PdfColor.fromInt(0xFFFFF4CC);
          fg = PdfColor.fromInt(0xFF8A6D00);
          break;
        default:
          bg = PdfColors.grey300;
          fg = PdfColors.black;
      }

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: PdfColors.amber),
        ),
        child: pw.Text(
          status,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: fg,
          ),
        ),
      );
    }

    // ───────── HEADER ROW ─────────
    final headerRow = pw.Column(
      children: [
        pw.Row(
          children: [
            headerCell('ID', width: 20),
            headerCell('Date & Time', width: 80),
            headerCell('Status', width: 55),
            headerCell('Class', width: 60),
            headerCell('Type', width: 70),
            headerCell('Sub Type', width: 110),
            headerCell('Source', width: 80),
            headerCell('Identifier', width: 60),
            headerCell('Text', width: 90),
            headerCell('Panel No', width: 50),
            headerCell('Module No', width: 60),
            headerCell('L-Bus No', width: 60),
          ],
        ),
        pw.Divider(color: PdfColor.fromInt(0xFFD9D9D9)),
      ],
    );

    // ───────── DATA ROWS ─────────
    final dataRows = logs.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final log = entry.value;
      final isEven = i % 2 == 0;

      return pw.Container(
        color: isEven ? PdfColor.fromInt(0xFFF9F9F9) : PdfColors.white,
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            cell(i.toString(), width: 20),
            cell(_formatDate(log.eventDateTime), width: 80),
            cell(_safe(log.eventStatus), width: 55),
            cell(_safe(log.eventClass), width: 60),
            cell(_safe(log.eventType), width: 70),
            cell(_safe(log.eventSubType), width: 110),
            cell(_safe(log.eventSource), width: 80),
            cell(_safe(log.identifier), width: 60),
            cell(_safe(log.text), width: 90),
            cell(_safe(log.panelNo), width: 50),
            cell(_safe(log.moduleNo), width: 60),
            cell(_safe(log.lBusNo), width: 60),
          ],
        ),
      );
    });

    return pw.Column(children: [headerRow, ...dataRows]);
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
