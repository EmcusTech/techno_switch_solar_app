import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/ble/demo/demo_ble.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/models/new_event_log_progress.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/timestamp_converter.dart';
import 'package:Technoswitch/widgets/common/app_notice.dart';

class NewEventLogValuesScreen extends StatefulWidget {
  const NewEventLogValuesScreen({
    super.key,
    required this.progress,
    this.embedded = false,
  });

  final ValueNotifier<NewEventLogProgress> progress;
  final bool embedded;

  @override
  State<NewEventLogValuesScreen> createState() =>
      _NewEventLogValuesScreenState();
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

  Widget _progressBody() {
    return ValueListenableBuilder<NewEventLogProgress>(
      valueListenable: widget.progress,
      builder: (context, value, _) {
        _showNotice(value);
        if (!value.done) return _RetrievalProgress(percent: value.percent);
        return _EventLogGrid(logs: value.logs);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ColoredBox(
        color: ColorConstants.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                StringConstants.eventLog,
                style: StyleConstants.black16w700Style,
              ),
            ),
            Expanded(child: _progressBody()),
          ],
        ),
      );
    }
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
      body: _progressBody(),
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
            Text('$percent%', style: StyleConstants.textDark16w700Style),
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

class _EventLogGrid extends StatefulWidget {
  const _EventLogGrid({required this.logs, this.showClassFilters = true});

  final List<LogModel> logs;
  final bool showClassFilters;

  @override
  State<_EventLogGrid> createState() => _EventLogGridState();
}

enum _LogSortColumn { eventNo, timestamp, eventType, configText, eventText }

class _EventLogGridState extends State<_EventLogGrid> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _filterScroll = ScrollController();
  final ScrollController _tableScroll = ScrollController();
  _LogSortColumn? _sortColumn;
  bool _sortAscending = true;
  int _selectedFilter = 0;

  static const List<({String label, String? eventClass})> _classFilters =
      <({String label, String? eventClass})>[
        (label: 'All', eventClass: null),
        (label: 'EXT. Release', eventClass: 'Release'),
        (label: 'Fire', eventClass: 'Alarm'),
        (label: 'Fault', eventClass: 'Fault'),
        (label: 'Disablement', eventClass: 'Disablement'),
        (label: 'Condition', eventClass: 'Condition'),
        (label: 'Action', eventClass: 'Action'),
      ];

  @override
  void dispose() {
    _search.dispose();
    _filterScroll.dispose();
    _tableScroll.dispose();
    super.dispose();
  }

  List<({LogModel log, int eventNo})> get _visibleLogs {
    final List<({LogModel log, int eventNo})> entries = [
      for (var index = 0; index < widget.logs.length; index++)
        (log: widget.logs[index], eventNo: index + 1),
    ];
    final String? eventClass = _classFilters[_selectedFilter].eventClass;
    final List<({LogModel log, int eventNo})> byClass =
        eventClass == null
            ? entries
            : entries.where((({LogModel log, int eventNo}) entry) {
              return entry.log.eventClass == eventClass;
            }).toList();
    final String query = _search.text.trim().toLowerCase();
    final List<({LogModel log, int eventNo})> filtered =
        query.isEmpty
            ? byClass
            : byClass.where((({LogModel log, int eventNo}) entry) {
              return _cells(
                entry.log,
                entry.eventNo,
              ).any((String cell) => cell.toLowerCase().contains(query));
            }).toList();
    final _LogSortColumn? column = _sortColumn;
    if (column == null) return filtered;
    final List<({LogModel log, int eventNo})> sorted = List.of(filtered);
    sorted.sort((
      ({LogModel log, int eventNo}) a,
      ({LogModel log, int eventNo}) b,
    ) {
      final int compared = _compare(a, b, column);
      return _sortAscending ? compared : -compared;
    });
    return sorted;
  }

  void _toggleSort(_LogSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
        return;
      }
      _sortColumn = column;
      _sortAscending = true;
    });
  }

  int _compare(
    ({LogModel log, int eventNo}) a,
    ({LogModel log, int eventNo}) b,
    _LogSortColumn column,
  ) {
    switch (column) {
      case _LogSortColumn.eventNo:
        if (DemoBle.devMode) {
          final int aId = int.tryParse(a.log.eventId ?? '') ?? 0;
          final int bId = int.tryParse(b.log.eventId ?? '') ?? 0;
          return aId.compareTo(bId);
        }
        return a.eventNo.compareTo(b.eventNo);
      case _LogSortColumn.timestamp:
        final DateTime? aTime = a.log.eventDateTime;
        final DateTime? bTime = b.log.eventDateTime;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;
        return aTime.compareTo(bTime);
      case _LogSortColumn.eventType:
        return _source(
          a.log,
        ).toLowerCase().compareTo(_source(b.log).toLowerCase());
      case _LogSortColumn.eventText:
        return _orDash(
          a.log.text,
        ).toLowerCase().compareTo(_orDash(b.log.text).toLowerCase());
      case _LogSortColumn.configText:
        return _orDash(
          a.log.configText,
        ).toLowerCase().compareTo(_orDash(b.log.configText).toLowerCase());
    }
  }

  void _scrollFilters(double delta) {
    if (!_filterScroll.hasClients) return;
    final double target = (_filterScroll.offset + delta).clamp(
      0,
      _filterScroll.position.maxScrollExtent,
    );
    _filterScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Widget _classFilterRow() {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SvgPicture.asset(AssetConstants.tsFilterIcon, width: 16, height: 16),
          const SizedBox(width: 6),
          Text('Filter :', style: StyleConstants.textDark14w500Style),
          IconButton(
            onPressed: () => _scrollFilters(-140),
            icon: const Icon(Icons.chevron_left, size: 18),
            visualDensity: VisualDensity.compact,
            color: ColorConstants.black,
          ),
          Expanded(
            child: ListView.separated(
              controller: _filterScroll,
              scrollDirection: Axis.horizontal,
              itemCount: _classFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final bool selected = index == _selectedFilter;
                return InkWell(
                  onTap: () => setState(() => _selectedFilter = index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? ColorConstants.primary
                              : ColorConstants.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selected
                                ? ColorConstants.primary
                                : const Color(0xFF3D3D3D),
                      ),
                    ),
                    child: Text(
                      _classFilters[index].label,
                      style:
                          selected
                              ? StyleConstants.white14w500Style
                              : StyleConstants.textDark14w500Style,
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => _scrollFilters(140),
            icon: const Icon(Icons.chevron_right, size: 18),
            visualDensity: VisualDensity.compact,
            color: ColorConstants.black,
          ),
        ],
      ),
    );
  }

  Widget _sortHeader(String title, _LogSortColumn column) {
    final bool active = _sortColumn == column;
    return InkWell(
      onTap: () => _toggleSort(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(width: 6),
          Opacity(
            opacity: active ? 1 : 0.55,
            child: Transform.rotate(
              angle: active && !_sortAscending ? math.pi : 0,
              child: SvgPicture.asset(
                AssetConstants.tsSortIcon,
                width: 14,
                height: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<int, String> _sourceNames = <int, String>{
    0: 'Zone',
    1: 'Input',
    2: 'Relay',
    3: 'Sounder',
    4: 'Panel',
  };

  static const Color _oddRowColor = Color(0xFFF4F4F4);

  static const List<String> _columns = <String>[
    DemoBle.devMode ? 'Event id' : 'Event no',
    'Timestamp',
    'Event type',
    'Configuration text',
    'Event text',
  ];

  @override
  Widget build(BuildContext context) {
    final List<({LogModel log, int eventNo})> logs = _visibleLogs;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: StyleConstants.textDark14w500Style,
                    decoration: InputDecoration(
                      hintText:
                          'Search for Event Text, Configuration text, Time stamp, Event Type or Event No',
                      hintStyle: StyleConstants.textDisabled14w500Style,
                      isDense: true,
                      contentPadding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                      filled: true,
                      fillColor: ColorConstants.white,
                      suffixIcon: IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close,
                          color: ColorConstants.primary,
                          size: 18,
                        ),
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                        borderSide: BorderSide(
                          color: ColorConstants.surfaceBorder,
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                        borderSide: BorderSide(
                          color: ColorConstants.surfaceBorder,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                        borderSide: BorderSide(color: ColorConstants.primary),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: ColorConstants.primary,
                  child: InkWell(
                    onTap: () => setState(() {}),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.search,
                        color: ColorConstants.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showClassFilters) ...[
            const SizedBox(height: 12),
            _classFilterRow(),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),
          Expanded(child: _table(logs)),
        ],
      ),
    );
  }

  Widget _table(List<({LogModel log, int eventNo})> logs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth =
            constraints.maxWidth < 960 ? 960 : constraints.maxWidth;
        final Widget table = SizedBox(
          width: tableWidth,
          child: _dataTable(logs),
        );
        if (logs.isEmpty) {
          final String message =
              widget.logs.isEmpty ? 'No event logs' : 'No matching logs';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: table,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    message,
                    style: StyleConstants.textDark14w500Style,
                  ),
                ),
              ),
            ],
          );
        }
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            controller: _tableScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _tableScroll,
              padding: const EdgeInsets.only(right: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }

  DataTable _dataTable(List<({LogModel log, int eventNo})> logs) {
    return DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 32,
      columnSpacing: 24,
      horizontalMargin: 16,
      headingRowColor: const WidgetStatePropertyAll<Color>(
        ColorConstants.primary,
      ),
      headingTextStyle: StyleConstants.white14w500Style,
      dataTextStyle: StyleConstants.textDark14w500Style,
      dividerThickness: 0,
      border: const TableBorder(),
      columns: [
        for (var index = 0; index < _columns.length; index++)
          DataColumn(
            label: _sortHeader(_columns[index], _LogSortColumn.values[index]),
          ),
      ],
      rows: [
        for (var index = 0; index < logs.length; index++)
          DataRow(
            color: WidgetStatePropertyAll<Color>(
              index.isEven ? _oddRowColor : ColorConstants.white,
            ),
            cells: [
              for (final String cell in _cells(
                logs[index].log,
                logs[index].eventNo,
              ))
                DataCell(
                  Text(cell, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
      ],
    );
  }

  static List<String> _cells(LogModel log, int eventNo) {
    return <String>[
      DemoBle.devMode ? _eventId(log) : '$eventNo',
      log.eventDateTime == null
          ? '0'
          : TimestampConverter.formatTimestamp(log.eventDateTime!),
      _source(log),
      _orDash(log.configText),
      _orDash(log.text),
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
    if (type == 4) return name;
    return '$name ${number + 1}';
  }
}

/// Right-hand pane for a live session. The table is the event-log grid;
/// rows appear as the panel pushes them, newest first.
class LiveEventValuesScreen extends StatefulWidget {
  const LiveEventValuesScreen({
    super.key,
    required this.logs,
    required this.sessionOpen,
    required this.paneToken,
    required this.onStart,
    required this.onEnd,
    required this.onPaneClosed,
  });

  final ValueNotifier<List<LogModel>> logs;
  final ValueNotifier<bool> sessionOpen;
  final int paneToken;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final void Function(int token) onPaneClosed;

  @override
  State<LiveEventValuesScreen> createState() => _LiveEventValuesScreenState();
}

class _LiveEventValuesScreenState extends State<LiveEventValuesScreen> {
  @override
  void dispose() {
    widget.onPaneClosed(widget.paneToken);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorConstants.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  StringConstants.liveEvents,
                  style: StyleConstants.black16w700Style,
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.sessionOpen,
                  builder: (context, open, _) {
                    return Row(
                      children: [
                        _LiveEventActionButton(
                          label: StringConstants.start,
                          enabled: !open,
                          filled: true,
                          onPressed: widget.onStart,
                        ),
                        const SizedBox(width: 8),
                        _LiveEventActionButton(
                          label: 'End',
                          enabled: open,
                          filled: false,
                          onPressed: widget.onEnd,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: widget.logs,
              builder: (context, logs, _) {
                return _EventLogGrid(logs: logs.reversed.toList());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveEventActionButton extends StatelessWidget {
  const _LiveEventActionButton({
    required this.label,
    required this.enabled,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: filled ? ColorConstants.primary : ColorConstants.white,
      foregroundColor: filled ? ColorConstants.white : ColorConstants.primary,
      disabledBackgroundColor: ColorConstants.surfaceBorder,
      disabledForegroundColor: ColorConstants.textGray,
      elevation: 0,
      minimumSize: const Size(88, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: filled ? ColorConstants.primary : ColorConstants.primary,
        ),
      ),
    );
    return ElevatedButton(
      style: style,
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: StyleConstants.white14w600Style.copyWith(
          color:
              enabled
                  ? (filled ? ColorConstants.white : ColorConstants.primary)
                  : ColorConstants.textGray,
        ),
      ),
    );
  }
}

/// Large live-log window. Listening starts when the window opens.
/// Closing it sends the end command.
class LiveEventLogsDialog extends StatefulWidget {
  const LiveEventLogsDialog({
    super.key,
    required this.logs,
    required this.sessionOpen,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onRefresh,
    required this.onClosed,
  });

  final ValueNotifier<List<LogModel>> logs;
  final ValueNotifier<bool> sessionOpen;
  final VoidCallback onStart;
  final Future<void> Function() onPause;
  final Future<bool> Function() onResume;
  final VoidCallback onRefresh;
  final VoidCallback onClosed;

  @override
  State<LiveEventLogsDialog> createState() => _LiveEventLogsDialogState();
}

class _LiveEventLogsDialogState extends State<LiveEventLogsDialog> {
  bool _started = false;
  bool _busy = false;
  bool _closed = false;
  int _classFilter = 0;
  int _componentFilter = 0;

  static const List<String> _classFilters = <String>[
    'All',
    'EXT. Release',
    'Fire',
    'Fault',
    'Disablement',
    'Condition',
    'Action',
  ];

  static const List<({String label, String icon})> _components =
      <({String label, String icon})>[
        (label: 'Relay(1/2)', icon: AssetConstants.peripheralRelayIcon),
        (label: 'Input(2/2)', icon: AssetConstants.peripheralInputIcon),
        (label: 'Zones(3/3)', icon: AssetConstants.peripheralZonesIcon),
        (label: 'Sounder(3/3)', icon: AssetConstants.peripheralSounderIcon),
        (label: 'Prog/Hold(2/2)', icon: AssetConstants.peripheralProgHoldIcon),
        (label: 'Aux(2/2)', icon: AssetConstants.peripheralAuxIcon),
        (label: 'L-Bus(2/2)', icon: AssetConstants.peripheralLBusIcon),
        (label: 'Ext Out(1/1)', icon: AssetConstants.peripheralExtOutIcon),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closed) return;
      setState(() => _started = true);
      widget.onStart();
    });
  }

  Future<void> _togglePause() async {
    if (_busy || _closed || !_started) return;
    setState(() => _busy = true);
    if (widget.sessionOpen.value) {
      await widget.onPause();
    } else {
      await widget.onResume();
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    widget.onClosed();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      backgroundColor: ColorConstants.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: size.width * 0.86,
        height: size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const Divider(height: 1, color: ColorConstants.surfaceBorder),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: size.width * 0.86 * 0.4, child: _leftPane()),
                  const VerticalDivider(
                    width: 1,
                    color: ColorConstants.surfaceBorder,
                  ),
                  Expanded(child: _rightPane()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Text('Live Logs', style: StyleConstants.white16w600Style),
          const Spacer(),
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close, color: ColorConstants.white),
          ),
        ],
      ),
    );
  }

  Widget _leftPane() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Text('Action Buttons', style: StyleConstants.black16w700Style),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: widget.sessionOpen,
          builder: (context, running, _) {
            final bool showResume = _started && !running;
            return Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: showResume ? 'Resume' : 'Pause',
                    color:
                        showResume
                            ? ColorConstants.success
                            : ColorConstants.warningAmber,
                    icon: showResume ? Icons.play_arrow : Icons.pause,
                    onPressed: _busy || !_started ? null : _togglePause,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Refresh',
                    color: ColorConstants.primaryBlue,
                    icon: Icons.refresh,
                    onPressed: widget.onRefresh,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Filter by', style: StyleConstants.black16w700Style),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < _classFilters.length; index++)
              _chip(
                label: _classFilters[index],
                selected: index == _classFilter,
                onTap: () => setState(() => _classFilter = index),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Component Filter', style: StyleConstants.black16w700Style),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            for (var index = 0; index < _components.length; index++)
              _componentTile(index),
          ],
        ),
      ],
    );
  }

  Widget _rightPane() {
    return ValueListenableBuilder<List<LogModel>>(
      valueListenable: widget.logs,
      builder: (context, logs, _) {
        return _EventLogGrid(
          logs: logs.reversed.toList(),
          showClassFilters: false,
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: ColorConstants.white,
        elevation: 0,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: StyleConstants.white14w600Style),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primary : ColorConstants.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? ColorConstants.primary : const Color(0xFF3D3D3D),
          ),
        ),
        child: Text(
          label,
          style:
              selected
                  ? StyleConstants.white14w500Style
                  : StyleConstants.textDark14w500Style,
        ),
      ),
    );
  }

  Widget _componentTile(int index) {
    final bool selected = index == _componentFilter;
    final ({String label, String icon}) item = _components[index];
    final Color foreground =
        selected ? ColorConstants.white : ColorConstants.primary;
    return InkWell(
      onTap: () => setState(() => _componentFilter = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primary : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected
                    ? ColorConstants.primary
                    : ColorConstants.surfaceBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              item.icon,
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StyleConstants.textDark14w500Style.copyWith(
                fontSize: 11,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
