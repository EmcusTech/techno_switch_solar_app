import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_diff_labels.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Site / panel summary + peripheral sections (cache-backed), same PDF chrome as log report.
class ProjectReportPdfUtil {
  ProjectReportPdfUtil._();

  static final DateFormat _dtFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat _dateOnly = DateFormat('dd/MM/yyyy');

  static Map<String, Object?>? _asMap(Object? o) =>
      o is Map ? Map<String, Object?>.from(o) : null;

  static String _scalar(
    String sectionKey,
    String path,
    Object? value,
    Object? sideRoot,
  ) {
    return PeripheralConfigDiffLabels.formatScalar(
      sectionKey,
      path,
      value,
      sideRoot,
    );
  }

  static String _serviceDateFromDue(Map<String, dynamic>? due) {
    if (due == null) return '-';
    final y = due['year'];
    final m = due['month'];
    final d = due['day'];
    if (y is! num || m is! num || d is! num) return '-';
    try {
      return _dateOnly.format(DateTime(y.toInt(), m.toInt(), d.toInt()));
    } catch (_) {
      return '-';
    }
  }

  static String _dash(String v) => v.trim().isEmpty ? '-' : v.trim();

  /// Loads cached setup for [deviceId] and opens the print/share PDF dialog.
  static Future<void> generate({
    required String deviceId,
    required String siteName,
    required String installerName,
    required String companyName,
    required String saqccNo,
    required String receivedPanelName,
    required String advertisedPanelName,
    required String hardwareVersion,
    required String firmwareVersion,
    required String firmwareDate,
    required String protocolVersion,
  }) async {
    final zone = await PeripheralSetupCache.loadZoneSetup(deviceId);
    final input = await PeripheralSetupCache.loadInputSetup(deviceId);
    final relay = await PeripheralSetupCache.loadRelaySetup(deviceId);
    final extOut = await PeripheralSetupCache.loadExtOutSetup(deviceId);
    final lBus = await PeripheralSetupCache.loadLBusSetup(deviceId);
    final sounder = await PeripheralSetupCache.loadSounderSetup(deviceId);
    final serviceDue = await PeripheralSetupCache.loadServiceDueSetup(deviceId);

    final serviceDate = _serviceDateFromDue(serviceDue);

    final pdf = pw.Document();
    final logo = await _loadImage('assets/images/full_logo.png');
    final watermarkSvg = await _loadSvg('assets/svgs/log_report_watermark.svg');

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _header(context, logo),
        footer: _footer,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat(
            PdfPageFormat.a4.height,
            PdfPageFormat.a4.width,
          ),
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 48),
          buildForeground: (context) {
            return pw.Align(
              alignment: pw.Alignment.bottomCenter,
              child: pw.Opacity(
                opacity: 0.008,
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 24),
                  child: watermarkSvg,
                ),
              ),
            );
          },
        ),
        build:
            (_) => [
              _projectInfoRow(
                siteName: siteName,
                installerName: installerName,
                companyName: companyName,
                saqccNo: saqccNo,
                serviceDate: serviceDate,
              ),
              _panelInfoSection(
                receivedPanelName: receivedPanelName,
                advertisedPanelName: advertisedPanelName,
                hardwareVersion: hardwareVersion,
                firmwareVersion: firmwareVersion,
                firmwareDate: firmwareDate,
                protocolVersion: protocolVersion,
              ),
              _sectionHeader('ZONE INFO'),
              _zoneBlock(zone),
              _sectionHeader('INPUT INFO'),
              _inputBlock(input),
              _sectionHeader('RELAY INFO'),
              _relayBlock(relay),
              _sectionHeader('EXTINGUISHING OUTPUT (EXT OUT)'),
              _extOutBlock(extOut),
              _sectionHeader('L-BUS INFO'),
              _lBusBlock(lBus),
              _sectionHeader('SOUNDER INFO'),
              _sounderBlock(sounder),
            ],
      ),
    );

    final fileName =
        'project_report_${DateFormat('dd-MM-yyyy_HH-mm-ss').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      name: fileName,
      format: PdfPageFormat(PdfPageFormat.a4.height, PdfPageFormat.a4.width),
      onLayout: (format) async => pdf.save(),
    );
  }

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
                'Project Configuration Report',
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

  static pw.Widget _item(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value.isEmpty ? '-' : value,
          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF3A3A3A)),
        ),
      ],
    );
  }

  /// Three equal-width columns so rows line up in a grid (landscape page).
  static pw.Widget _panelInfoGridRow(
    String title1,
    String value1,
    String title2,
    String value2,
    String title3,
    String value3, {
    double gutter = 10,
  }) {
    pw.Widget cell(String title, String value, {bool trailingGutter = true}) {
      return pw.Expanded(
        child: pw.Padding(
          padding: pw.EdgeInsets.only(right: trailingGutter ? gutter : 0),
          child: _item(title, _dash(value)),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        cell(title1, value1),
        cell(title2, value2),
        cell(title3, value3, trailingGutter: false),
      ],
    );
  }

  static pw.Widget _projectInfoRow({
    required String siteName,
    required String installerName,
    required String companyName,
    required String saqccNo,
    required String serviceDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('PROJECT INFO'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _item('Site Name', siteName),
            _item('Installer Name', installerName),
            _item('Company', companyName),
            _item('SAQCC No', saqccNo),
            _item('Service Date', serviceDate),
          ],
        ),
        pw.Divider(color: PdfColor.fromInt(0xFFD9D9D9)),
      ],
    );
  }

  static pw.Widget _panelInfoSection({
    required String receivedPanelName,
    required String advertisedPanelName,
    required String hardwareVersion,
    required String firmwareVersion,
    required String firmwareDate,
    required String protocolVersion,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('PANEL INFO'),
        _panelInfoGridRow(
          'Product Name',
          receivedPanelName,
          'Product Id',
          advertisedPanelName.split("_").last,
          'Hardware version',
          hardwareVersion,
        ),
        pw.SizedBox(height: 8),
        _panelInfoGridRow(
          'Firmware version',
          firmwareVersion,
          'Firmware date',
          firmwareDate,
          'Protocol version',
          protocolVersion,
        ),
        pw.Divider(color: PdfColor.fromInt(0xFFD9D9D9)),
      ],
    );
  }

  static pw.Widget _missing(String message) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _zoneBlock(Map<String, dynamic>? zone) {
    if (zone == null) {
      return _missing('No cached zone setup for this device.');
    }
    final children = <pw.Widget>[];
    for (final key in ['z1', 'z2', 'z3']) {
      final z = _asMap(zone[key]);
      if (z == null) continue;
      final n = key.substring(1);
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Zone $n',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Type: ${_scalar('zone', '$key.type', z['type'], zone)} · '
                'Enabled: ${_scalar('zone', '$key.enabled', z['enabled'], zone)} · '
                'Test: ${_scalar('zone', '$key.test', z['test'], zone)} · '
                'Mode: ${_scalar('zone', '$key.detectionMode', z['detectionMode'], zone)} · '
                'Verification (s): ${_scalar('zone', '$key.verificationTime', z['verificationTime'], zone)} · '
                'Text: ${_scalar('zone', '$key.text', z['text'], zone)}',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _inputBlock(Map<String, dynamic>? input) {
    if (input == null) {
      return _missing('No cached input setup for this device.');
    }
    return pw.Text(
      'Group: ${_scalar('input', 'group', input['group'], input)} · '
      'Function: ${_scalar('input', 'function', input['function'], input)} · '
      'Enabled: ${_scalar('input', 'enabled', input['enabled'], input)} · '
      'Test: ${_scalar('input', 'test', input['test'], input)} · '
      'Inverted: ${_scalar('input', 'inverted', input['inverted'], input)} · '
      'Text: ${_scalar('input', 'text', input['text'], input)}',
      style: const pw.TextStyle(fontSize: 8),
    );
  }

  static pw.Widget _relayBlock(Map<String, dynamic>? relay) {
    if (relay == null) {
      return _missing('No cached relay setup for this device.');
    }
    final children = <pw.Widget>[];
    for (final key in ['r1', 'r2', 'r3']) {
      final r = _asMap(relay[key]);
      if (r == null) continue;
      final n = key.substring(1);
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            'Relay $n - '
            'Enabled: ${_scalar('relay', '$key.enabled', r['enabled'], relay)} · '
            'Test: ${_scalar('relay', '$key.test', r['test'], relay)} · '
            'Group: ${_scalar('relay', '$key.group', r['group'], relay)} · '
            'Function: ${_scalar('relay', '$key.function', r['function'], relay)} · '
            'Output text: ${_scalar('relay', '$key.outputText', r['outputText'], relay)} · '
            'Zone / dynamic: ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay)}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _extOutBlock(Map<String, dynamic>? ext) {
    if (ext == null) {
      return _missing('No cached extinguishing output setup for this device.');
    }
    return pw.Text(
      'Enabled: ${_scalar('ext_out', 'enabled', ext['enabled'], ext)} · '
      'Actuator: ${_scalar('ext_out', 'actuatorType', ext['actuatorType'], ext)} · '
      'Function: ${_scalar('ext_out', 'function', ext['function'], ext)} · '
      'Reset in count: ${_scalar('ext_out', 'resetAllowed', ext['resetAllowed'], ext)} · '
      'Hold: ${_scalar('ext_out', 'holdMode', ext['holdMode'], ext)} · '
      'Action: ${_scalar('ext_out', 'action', ext['action'], ext)} · '
      'Countdown auto: ${_scalar('ext_out', 'countdownAuto', ext['countdownAuto'], ext)} · '
      'Countdown man: ${_scalar('ext_out', 'countdownMan', ext['countdownMan'], ext)} · '
      'Release time: ${_scalar('ext_out', 'releaseTime', ext['releaseTime'], ext)} · '
      'Reset delay: ${_scalar('ext_out', 'resetDelay', ext['resetDelay'], ext)} · '
      'Text: ${_scalar('ext_out', 'text', ext['text'], ext)}',
      style: const pw.TextStyle(fontSize: 7),
    );
  }

  static pw.Widget _lBusBlock(List<Map<String, dynamic>>? buses) {
    if (buses == null || buses.isEmpty) {
      return _missing('No cached L-Bus setup for this device.');
    }
    final rows = <pw.Widget>[];
    rows.add(
      pw.Container(
        color: PdfColor.fromInt(0xFFF0F0F0),
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: pw.Row(
          children: [
            _lCell('No', 16),
            _lCell('En', 18),
            _lCell('LED', 18),
            _lCell('Prod', 38),
            _lCell('Device text', 72),
            _lCell('Id', 18),
            _lCell('Rev', 16),
            _lCell('HW', 40),
            _lCell('FW', 40),
            _lCell('Date', 38),
            _lCell('Proto', 22),
          ],
        ),
      ),
    );
    for (var i = 0; i < buses.length; i++) {
      final d = LBusSetupData.fromJson(buses[i]);
      final isEven = i % 2 == 0;
      rows.add(
        pw.Container(
          color: isEven ? PdfColor.fromInt(0xFFF9F9F9) : PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _lCell('${i + 1}', 16),
              _lCell(d.enabled, 18),
              _lCell(d.idLed, 18),
              _lCell(d.product, 38),
              _lCell(d.deviceText, 72),
              _lCell('${d.id}', 18),
              _lCell('${d.revision}', 16),
              _lCell(d.hardware, 40),
              _lCell(d.firmware, 40),
              _lCell(d.date, 38),
              _lCell('${d.protocol}', 22),
            ],
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows,
    );
  }

  static pw.Widget _lCell(String t, double w) {
    return pw.Container(
      width: w,
      child: pw.Text(
        t.isEmpty ? 'N/A' : t,
        style: const pw.TextStyle(fontSize: 5.5),
      ),
    );
  }

  static pw.Widget _sounderBlock(Map<String, dynamic>? s) {
    if (s == null) {
      return _missing('No cached sounder setup for this device.');
    }
    final lines = <pw.Widget>[];

    void addLine(String title, String text) {
      lines.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        ),
      );
    }

    for (final key in ['s1', 's2', 's3']) {
      final block = _asMap(s[key]);
      if (block == null) continue;
      final n = key.substring(1);
      addLine(
        'Sounder output $n',
        'Enabled: ${_scalar('sounder', '$key.enabled', block['enabled'], s)} · '
            'Test: ${_scalar('sounder', '$key.test', block['test'], s)} · '
            'Type: ${_scalar('sounder', '$key.normal', block['normal'], s)} · '
            'Output text: ${_scalar('sounder', '$key.outputText', block['outputText'], s)} · '
            'Group: ${_scalar('sounder', '$key.group', block['group'], s)} · '
            'Function: ${_scalar('sounder', '$key.function', block['function'], s)} · '
            'Function no: ${_scalar('sounder', '$key.functionNo', block['functionNo'], s)}',
      );
    }
    for (final key in ['z1', 'z2', 'z3']) {
      final block = _asMap(s[key]);
      if (block == null) continue;
      final n = key.substring(1);
      addLine(
        'Sounder · Zone $n',
        'Enabled: ${_scalar('sounder', '$key.enabled', block['enabled'], s)} · '
            'Test: ${_scalar('sounder', '$key.test', block['test'], s)} · '
            'Action: ${_scalar('sounder', '$key.action', block['action'], s)}',
      );
    }
    for (final key in ['e1', 'e2', 'e3']) {
      final block = _asMap(s[key]);
      if (block == null) continue;
      final n = key.substring(1);
      addLine(
        'Sounder · Ext. out $n',
        'Enabled: ${_scalar('sounder', '$key.enabled', block['enabled'], s)} · '
            'Test: ${_scalar('sounder', '$key.test', block['test'], s)} · '
            'Countdown: ${_scalar('sounder', '$key.countdownAction', block['countdownAction'], s)} · '
            'Hold: ${_scalar('sounder', '$key.holdAction', block['holdAction'], s)} · '
            'Release: ${_scalar('sounder', '$key.releaseAction', block['releaseAction'], s)}',
      );
    }
    final g = _asMap(s['general']);
    if (g != null) {
      addLine(
        'Sounder · General delay',
        'Enabled: ${_scalar('sounder', 'general.enabled', g['enabled'], s)} · '
            'Test: ${_scalar('sounder', 'general.test', g['test'], s)} · '
            'Delayed: ${_scalar('sounder', 'general.delayed', g['delayed'], s)} · '
            'Action: ${_scalar('sounder', 'general.action', g['action'], s)} · '
            'Delay (s): ${_scalar('sounder', 'general.delay', g['delay'], s)}',
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines,
    );
  }

  static Future<pw.MemoryImage> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  static Future<pw.SvgImage> _loadSvg(String path) async {
    final svg = await rootBundle.loadString(path);
    return pw.SvgImage(svg: svg);
  }
}
