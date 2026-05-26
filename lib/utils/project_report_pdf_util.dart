import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/commissioning_test_results_helper.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_diff_labels.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';
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
    ).replaceAll('"', '');
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
    final walkTestResults = await CommissioningTestResultsCache.loadItems(
      deviceId,
      CommissioningTestType.walkTest,
    );
    final relayTestResults = await CommissioningTestResultsCache.loadItems(
      deviceId,
      CommissioningTestType.relayTest,
    );
    final sounderTestResults = await CommissioningTestResultsCache.loadItems(
      deviceId,
      CommissioningTestType.sounderTest,
    );

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
              _sectionHeader('ZONES'),
              _zoneBlock(zone),
              _sectionHeader('INPUTS'),
              // _inputBlock(input),
              _newInputBlock(input),
              _sectionHeader('RELAYS'),
              // _relayBlock(relay),
              _newRelayBlock(relay),
              _sectionHeader('EXTINGUISHING OUTPUT'),
              // _extOutBlock(extOut),
              _newExtOutBlock(extOut),
              _sectionHeader('SOUNDER'),
              // _sounderBlock(sounder),
              _newSounderBlock(sounder),
              _sectionHeader('L-BUS'),
              // _lBusBlock(lBus),
              _newLBusBlock(lBus),
              _sectionHeader('WALK TEST RESULTS'),
              _commissioningTestResultsBlock(
                walkTestResults,
                CommissioningTestType.walkTest,
                'No walk test results recorded for this device.',
              ),
              _sectionHeader('RELAY TEST RESULTS'),
              _commissioningTestResultsBlock(
                relayTestResults,
                CommissioningTestType.relayTest,
                'No relay test results recorded for this device.',
              ),
              _sectionHeader('SOUNDER TEST RESULTS'),
              _commissioningTestResultsBlock(
                sounderTestResults,
                CommissioningTestType.sounderTest,
                'No sounder test results recorded for this device.',
              ),
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

  static String _formatTestResult(String? result) {
    return switch (result) {
      'pass' => 'Pass',
      'fail' => 'Fail',
      _ => '-',
    };
  }

  static String _formatTestedAt(Object? testedAt) {
    if (testedAt is! String || testedAt.isEmpty) return '-';
    try {
      return _dtFormat.format(DateTime.parse(testedAt));
    } catch (_) {
      return testedAt;
    }
  }

  static pw.Widget _commissioningTestResultsBlock(
    Map<String, dynamic> results,
    CommissioningTestType type,
    String emptyMessage,
  ) {
    if (results.isEmpty) {
      return _missing(emptyMessage);
    }

    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final sortedKeys = results.keys.toList()..sort();
    final dataRows = <pw.Widget>[];
    for (final key in sortedKeys) {
      final entry = _asMap(results[key]);
      if (entry == null) continue;
      dataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(commissioningTestItemLabel(type, key)),
            dataCell(
              _formatTestResult(
                CommissioningTestResultsCache.resultForItem(results, key),
              ),
            ),
            dataCell(_formatTestedAt(entry['testedAt'])),
          ],
        ),
      );
    }

    if (dataRows.isEmpty) {
      return _missing(emptyMessage);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            headerCell('Item'),
            headerCell('Result'),
            headerCell('Tested At'),
          ],
        ),
        ...dataRows,
      ],
    );
  }

  static String _zoneEnabledStatus(Map<String, Object?> z) {
    final v = z['enabled'];
    if (v is bool) return v ? 'Enabled' : 'Disabled';
    if (v == 1) return 'Enabled';
    if (v == 0) return 'Disabled';
    final s = _scalar('zone', 'z1.enabled', v, {'z1': z});
    if (s == 'Yes') return 'Enabled';
    if (s == 'No') return 'Disabled';
    return s;
  }

  static String _zoneVerifiTime(
    String key,
    Map<String, Object?>? z,
    Object? root,
  ) {
    if (z == null) return '-';
    final s = _scalar(
      'zone',
      '$key.verificationTime',
      z['verificationTime'],
      root,
    );
    if (s == '-' || s == '—' || s.isEmpty) return '-';
    final t = s.trim();
    if (t.toLowerCase().endsWith('s')) return t;
    print("The verification time is: $t");
    return '${t.replaceAll('"', '')}s';
  }

  static pw.Widget _zoneBlock(Map<String, dynamic>? zone) {
    if (zone == null) {
      return _missing('No cached zone setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Zone No'),
        headerCell('Type'),
        headerCell('Zone'),
        headerCell('Mode'),
        headerCell('Verifi.Time'),
      ],
    );

    final dataRows = <pw.Widget>[];
    for (final key in ['z1', 'z2', 'z3']) {
      final z = _asMap(zone[key]);
      final no = key.substring(1);
      if (z == null) {
        dataRows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              dataCell(no),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
            ],
          ),
        );
        continue;
      }
      dataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(no),
            dataCell(_scalar('zone', '$key.type', z['type'], zone)),
            dataCell(_zoneEnabledStatus(z)),
            dataCell(
              _scalar('zone', '$key.detectionMode', z['detectionMode'], zone),
            ),
            dataCell(_zoneVerifiTime(key, z, zone)),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _newInputBlock(Map<String, dynamic>? input) {
    if (input == null) {
      return _missing('No cached input setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Input No'),
        headerCell('Group'),
        headerCell('Function'),
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Inverted'),
        headerCell('Text'),
      ],
    );

    final dataRows = <pw.Widget>[];
    dataRows.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          dataCell('1'),
          dataCell(_scalar('input', 'group', input['group'], input)),
          dataCell(_scalar('input', 'function', input['function'], input)),
          dataCell(_scalar('input', 'enabled', input['enabled'], input)),
          dataCell(_scalar('input', 'test', input['test'], input)),
          dataCell(_scalar('input', 'inverted', input['inverted'], input)),
          dataCell(_scalar('input', 'text', input['text'], input)),
        ],
      ),
    );
    // for (final key in ['z1', 'z2', 'z3']) {
    //   final z = _asMap(zone[key]);
    //   final no = key.substring(1);
    //   if (z == null) {
    //     dataRows.add(
    //       pw.Row(
    //         crossAxisAlignment: pw.CrossAxisAlignment.start,
    //         children: [
    //           dataCell(no),
    //           dataCell('-'),
    //           dataCell('-'),
    //           dataCell('-'),
    //           dataCell('-'),
    //         ],
    //       ),
    //     );
    //     continue;
    //   }
    //   dataRows.add(
    //     pw.Row(
    //       crossAxisAlignment: pw.CrossAxisAlignment.start,
    //       children: [
    //         dataCell(no),
    //         dataCell(_scalar('zone', '$key.type', z['type'], zone)),
    //         dataCell(_zoneEnabledStatus(z)),
    //         dataCell(
    //           _scalar('zone', '$key.detectionMode', z['detectionMode'], zone),
    //         ),
    //         dataCell(_zoneVerifiTime(key, z, zone)),
    //       ],
    //     ),
    //   );
    // }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [headerRow, ...dataRows],
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

  static pw.Widget _newRelayBlock(Map<String, dynamic>? relay) {
    if (relay == null) {
      return _missing('No cached zone setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Relay No'),
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Group'),
        headerCell('Function'),
        headerCell('Output Text'),
        headerCell('Zone/Ext.Out Val'),
      ],
    );

    final dataRows = <pw.Widget>[];
    for (final key in ['r1', 'r2', 'r3']) {
      final r = _asMap(relay[key]);
      final no = key.substring(1);
      if (r == null) {
        dataRows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              dataCell(no),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
            ],
          ),
        );
        continue;
      }
      dataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(no),
            dataCell(_scalar('relay', '$key.enabled', r['enabled'], relay)),
            dataCell(_scalar('relay', '$key.test', r['test'], relay)),
            dataCell(_scalar('relay', '$key.group', r['group'], relay)),
            dataCell(_scalar('relay', '$key.function', r['function'], relay)),
            dataCell(
              _scalar('relay', '$key.outputText', r['outputText'], relay),
            ),
            dataCell(
              _scalar('relay', '$key.group', r['group'], relay).contains("Zone")
                  ? "Zone ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay)}"
                  : _scalar(
                    'relay',
                    '$key.group',
                    r['group'],
                    relay,
                  ).contains("Ext. Out")
                  ? "Ext. Out ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay)}"
                  : "-",
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [headerRow, ...dataRows],
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
      print(
        "The dynamic text is: ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay).contains("0")}",
      );
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child:
              _scalar(
                    'relay',
                    '$key.dynamicText',
                    r['dynamicText'],
                    relay,
                  ).contains("0")
                  ? pw.Text(
                    'Relay $n - '
                    'Enabled: ${_scalar('relay', '$key.enabled', r['enabled'], relay)} · '
                    'Test: ${_scalar('relay', '$key.test', r['test'], relay)} · '
                    'Group: ${_scalar('relay', '$key.group', r['group'], relay)} · '
                    'Function: ${_scalar('relay', '$key.function', r['function'], relay)} · '
                    'Output text: ${_scalar('relay', '$key.outputText', r['outputText'], relay)} · ',
                    style: const pw.TextStyle(fontSize: 7),
                  )
                  : _scalar(
                    'relay',
                    '$key.group',
                    r['group'],
                    relay,
                  ).contains("Zone")
                  ? pw.Text(
                    'Relay $n - '
                    'Enabled: ${_scalar('relay', '$key.enabled', r['enabled'], relay)} · '
                    'Test: ${_scalar('relay', '$key.test', r['test'], relay)} · '
                    'Group: ${_scalar('relay', '$key.group', r['group'], relay)} · '
                    'Function: ${_scalar('relay', '$key.function', r['function'], relay)} · '
                    'Output text: ${_scalar('relay', '$key.outputText', r['outputText'], relay)} · '
                    'Zone: ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay)}',
                    style: const pw.TextStyle(fontSize: 7),
                  )
                  : pw.Text(
                    'Relay $n - '
                    'Enabled: ${_scalar('relay', '$key.enabled', r['enabled'], relay)} · '
                    'Test: ${_scalar('relay', '$key.test', r['test'], relay)} · '
                    'Group: ${_scalar('relay', '$key.group', r['group'], relay)} · '
                    'Function: ${_scalar('relay', '$key.function', r['function'], relay)} · '
                    'Output text: ${_scalar('relay', '$key.outputText', r['outputText'], relay)} · '
                    'Ext.Out: ${_scalar('relay', '$key.dynamicText', r['dynamicText'], relay)}',
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

  static pw.Widget _newExtOutBlock(Map<String, dynamic>? ext) {
    if (ext == null) {
      return _missing('No cached extinguishing output setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Ext. Out No'),
        headerCell('Enabled'),
        headerCell('Actuator'),
        headerCell('Function'),
        headerCell('Reset'),
        headerCell('Hold'),
        headerCell('Action'),
        headerCell('CD Auto'),
        headerCell('CD Man'),
        headerCell('Rel Time'),
        headerCell('Reset Delay'),
        headerCell('Text'),
      ],
    );

    final dataRows = <pw.Widget>[];
    dataRows.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          dataCell('1'),
          dataCell(_scalar('ext_out', 'enabled', ext['enabled'], ext)),
          dataCell(
            _scalar('ext_out', 'actuatorType', ext['actuatorType'], ext),
          ),
          dataCell(_scalar('ext_out', 'function', ext['function'], ext)),
          dataCell(
            _scalar('ext_out', 'resetAllowed', ext['resetAllowed'], ext),
          ),
          dataCell(_scalar('ext_out', 'holdMode', ext['holdMode'], ext)),
          dataCell(_scalar('ext_out', 'action', ext['action'], ext)),
          dataCell(
            _scalar('ext_out', 'countdownAuto', ext['countdownAuto'], ext),
          ),
          dataCell(
            _scalar('ext_out', 'countdownMan', ext['countdownMan'], ext),
          ),
          dataCell(_scalar('ext_out', 'releaseTime', ext['releaseTime'], ext)),
          dataCell(_scalar('ext_out', 'resetDelay', ext['resetDelay'], ext)),
          dataCell(_scalar('ext_out', 'text', ext['text'], ext)),
        ],
      ),
    );
    // for (final key in ['z1', 'z2', 'z3']) {
    //   final z = _asMap(zone[key]);
    //   final no = key.substring(1);
    //   if (z == null) {
    //     dataRows.add(
    //       pw.Row(
    //         crossAxisAlignment: pw.CrossAxisAlignment.start,
    //         children: [
    //           dataCell(no),
    //           dataCell('-'),
    //           dataCell('-'),
    //           dataCell('-'),
    //           dataCell('-'),
    //         ],
    //       ),
    //     );
    //     continue;
    //   }
    //   dataRows.add(
    //     pw.Row(
    //       crossAxisAlignment: pw.CrossAxisAlignment.start,
    //       children: [
    //         dataCell(no),
    //         dataCell(_scalar('zone', '$key.type', z['type'], zone)),
    //         dataCell(_zoneEnabledStatus(z)),
    //         dataCell(
    //           _scalar('zone', '$key.detectionMode', z['detectionMode'], zone),
    //         ),
    //         dataCell(_zoneVerifiTime(key, z, zone)),
    //       ],
    //     ),
    //   );
    // }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [headerRow, ...dataRows],
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

  static pw.Widget _newLBusBlock(List<Map<String, dynamic>>? buses) {
    if (buses == null) {
      return _missing('No cached L-Bus setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('L-Bus No'),
        headerCell('Enabled'),
        headerCell('LED'),
        headerCell('Product'),
        headerCell('Text'),
        headerCell('ID'),
        headerCell('Revision'),
        headerCell('HW Version'),
        headerCell('FW Version'),
        headerCell('Date'),
        headerCell('Protocol'),
      ],
    );

    final dataRows = <pw.Widget>[];
    for (var i = 0; i < buses.length; i++) {
      final d = LBusSetupData.fromJson(buses[i]);
      dataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell('${i + 1}'),
            dataCell(d.enabled),
            dataCell(d.idLed),
            dataCell(d.product),
            dataCell(d.deviceText),
            dataCell('${d.id}'),
            dataCell('${d.revision}'),
            dataCell(d.hardware),
            dataCell(d.firmware),
            dataCell(d.date),
            dataCell('${d.protocol}'),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [headerRow, ...dataRows],
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

  static pw.Widget _newSounderBlock(Map<String, dynamic>? s) {
    if (s == null) {
      return _missing('No cached sounder setup for this device.');
    }

    /// Five equal-width columns (same approach as panel info grid rows).
    pw.Widget headerCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
    }

    pw.Widget dataCell(String text) {
      return pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF3A3A3A),
            ),
          ),
        ),
      );
    }

    pw.Widget headerTitle(String title) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    final outputHeaderRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Sounder No'),
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Type'),
        headerCell('Output Text'),
        headerCell('Group'),
        headerCell('Function'),
        headerCell('Zone/Ext.Out Val'),
      ],
    );

    final outputDataRows = <pw.Widget>[];
    for (final key in ['s1', 's2', 's3']) {
      final block = _asMap(s[key]);
      final no = key.substring(1);
      if (block == null) {
        outputDataRows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              dataCell(no),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
            ],
          ),
        );
        continue;
      }
      outputDataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(no),
            dataCell(_scalar('sounder', '$key.enabled', block['enabled'], s)),
            dataCell(_scalar('sounder', '$key.test', block['test'], s)),
            dataCell(_scalar('sounder', '$key.normal', block['normal'], s)),
            dataCell(
              _scalar('sounder', '$key.outputText', block['outputText'], s),
            ),
            dataCell(_scalar('sounder', '$key.group', block['group'], s)),
            dataCell(_scalar('sounder', '$key.function', block['function'], s)),
            dataCell(
              _scalar(
                    'sounder',
                    '$key.group',
                    block['group'],
                    s,
                  ).contains("Zone")
                  ? "Zone ${_scalar('sounder', '$key.functionNo', block['functionNo'], s)}"
                  : _scalar(
                    'sounder',
                    '$key.group',
                    block['group'],
                    s,
                  ).contains("Ext. Out")
                  ? "Ext. Out ${_scalar('sounder', '$key.functionNo', block['functionNo'], s)}"
                  : "-",
            ),
          ],
        ),
      );
    }

    final zoneHeaderRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Zone No'),
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Action'),
      ],
    );

    final zoneDataRows = <pw.Widget>[];
    for (final key in ['z1', 'z2', 'z3']) {
      final block = _asMap(s[key]);
      final no = key.substring(1);
      if (block == null) {
        zoneDataRows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              dataCell(no),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
            ],
          ),
        );
        continue;
      }
      zoneDataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(no),
            dataCell(_scalar('sounder', '$key.enabled', block['enabled'], s)),
            dataCell(_scalar('sounder', '$key.test', block['test'], s)),
            dataCell(_scalar('sounder', '$key.action', block['action'], s)),
          ],
        ),
      );
    }

    // EXT. OUT HEADER ROW

    final extOutHeaderRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Ext. Out'),
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Countdown'),
        headerCell('Hold'),
        headerCell('Release'),
      ],
    );

    final extOutDataRows = <pw.Widget>[];
    for (final key in ['e1', 'e2', 'e3']) {
      final block = _asMap(s[key]);
      final no = key.substring(1);
      if (block == null) {
        extOutDataRows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              dataCell(
                no == "1"
                    ? 'Ext. Snd'
                    : no == "2"
                    ? 'Ext. Snd 2'
                    : 'Man. Release Snd',
              ),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
              dataCell('-'),
            ],
          ),
        );
        continue;
      }
      extOutDataRows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(
              no == "1"
                  ? 'Ext. Snd'
                  : no == "2"
                  ? 'Ext. Snd 2'
                  : 'Man. Release Snd',
            ),
            dataCell(_scalar('sounder', '$key.enabled', block['enabled'], s)),
            dataCell(_scalar('sounder', '$key.test', block['test'], s)),
            dataCell(
              _scalar(
                'sounder',
                '$key.countdownAction',
                block['countdownAction'],
                s,
              ),
            ),
            dataCell(
              _scalar('sounder', '$key.holdAction', block['holdAction'], s),
            ),
            dataCell(
              _scalar(
                'sounder',
                '$key.releaseAction',
                block['releaseAction'],
                s,
              ),
            ),
          ],
        ),
      );
    }

    // General Delay
    final generalDelayHeaderRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerCell('Enabled'),
        headerCell('Test'),
        headerCell('Delayed'),
        headerCell('Action'),
        headerCell('Delay (s)'),
      ],
    );

    final generalDelayDataRow = <pw.Widget>[];

    final g = _asMap(s['general']);

    if (g == null) {
      generalDelayDataRow.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell('-'),
            dataCell('-'),
            dataCell('-'),
            dataCell('-'),
            dataCell('-'),
          ],
        ),
      );
    } else {
      generalDelayDataRow.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            dataCell(_scalar('sounder', 'general.enabled', g['enabled'], s)),
            dataCell(_scalar('sounder', 'general.test', g['test'], s)),
            dataCell(_scalar('sounder', 'general.delayed', g['delayed'], s)),
            dataCell(_scalar('sounder', 'general.action', g['action'], s)),
            dataCell(_scalar('sounder', 'general.delay', g['delay'], s)),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        headerTitle('Sounder Output'),
        outputHeaderRow,
        ...outputDataRows,
        headerTitle('Sounder Zone'),
        zoneHeaderRow,
        ...zoneDataRows,
        headerTitle('Sounder Ext. Out'),
        extOutHeaderRow,
        ...extOutDataRows,
        headerTitle('Sounder General Delay'),
        generalDelayHeaderRow,
        ...generalDelayDataRow,
      ],
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
