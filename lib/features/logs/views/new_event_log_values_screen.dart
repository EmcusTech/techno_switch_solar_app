import 'package:flutter/material.dart';
import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/models/new_event_log_progress.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/timestamp_converter.dart';
import 'package:Technoswitch/widgets/common/app_notice.dart';

class NewEventLogValuesScreen extends StatefulWidget {
  const NewEventLogValuesScreen({super.key, required this.progress});

  final ValueNotifier<NewEventLogProgress> progress;

  @override
  State<NewEventLogValuesScreen> createState() => _NewEventLogValuesScreenState();
}

class _NewEventLogValuesScreenState extends State<NewEventLogValuesScreen> {
  int _shownNoticeId = 0;

  void _showNotice(NewEventLogProgress value) {
    final String? message = value.notice;
    if (message == null || value.noticeId == _shownNoticeId) return;
    final int noticeId = value.noticeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shownNoticeId == noticeId) return;
      _shownNoticeId = noticeId;
      showAppNotice(context, message: message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundGray,
      appBar: AppBar(
        title: Text(
          StringConstants.eventLog,
          style: StyleConstants.textDark16w700Style,
        ),
        backgroundColor: ColorConstants.surfaceOffWhite,
        foregroundColor: ColorConstants.black,
        elevation: 0,
      ),
      body: ValueListenableBuilder<NewEventLogProgress>(
        valueListenable: widget.progress,
        builder: (context, value, _) {
          _showNotice(value);
          if (!value.done) return _RetrievalProgress(percent: value.percent);
          if (value.logs.isEmpty) {
            return Center(
              child: Text(
                'No event logs',
                style: StyleConstants.textDark14w500Style,
              ),
            );
          }
          return _EventLogGrid(logs: value.logs);
        },
      ),
    );
  }
}

class _RetrievalProgress extends StatelessWidget {
  const _RetrievalProgress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: StyleConstants.textDark16w700Style,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: ColorConstants.surfaceBorder,
              color: ColorConstants.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventLogGrid extends StatelessWidget {
  const _EventLogGrid({required this.logs});

  final List<LogModel> logs;

  static const Map<int, String> _sourceNames = <int, String>{
    0: 'Zone',
    1: 'Input',
    2: 'Relay',
    3: 'Sounder',
    4: 'Panel',
  };

  static const List<String> _columns = <String>[
    'Log',
    'Event id',
    'Display text',
    'Timestamp',
    'Configuration text',
    'Source',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth =
              constraints.maxWidth < 960 ? 960 : constraints.maxWidth;
          return Scrollbar(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 72,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowColor: const WidgetStatePropertyAll<Color>(
                      ColorConstants.backgroundGray,
                    ),
                    headingTextStyle: StyleConstants.textDisabled14w500Style,
                    dataTextStyle: StyleConstants.textDark14w500Style,
                    border: TableBorder.all(
                      color: ColorConstants.surfaceBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    columns: [
                      for (final String title in _columns)
                        DataColumn(label: Text(title)),
                    ],
                    rows: [
                      for (var index = 0; index < logs.length; index++)
                        DataRow(
                          cells: [
                            for (final String cell in _cells(index, logs[index]))
                              DataCell(Text(cell)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static List<String> _cells(int index, LogModel log) {
    return <String>[
      '${index + 1}',
      _eventId(log),
      _orDash(log.text),
      log.eventDateTime == null
          ? '0'
          : TimestampConverter.formatTimestamp(log.eventDateTime!),
      _orDash(log.configText),
      _source(log),
    ];
  }

  static String _eventId(LogModel log) {
    final int? eventNo = int.tryParse(log.eventId ?? '');
    if (eventNo == null) return log.eventId ?? '—';
    return '0x${eventNo.toRadixString(16).toUpperCase()}';
  }

  static String _orDash(String? value) {
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  static String _source(LogModel log) {
    final int? type = log.par0;
    final int? number = log.par1;
    if (type == null || number == null) return '—';
    final String name = _sourceNames[type] ?? type.toString();
    return '$name $number';
  }
}
