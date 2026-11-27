import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:Technoswitch/features/logs/views/new_event_log_values_screen.dart';
import 'package:Technoswitch/models/event_log_retrieval_handle.dart';
import 'package:Technoswitch/models/log_model.dart';
import 'package:Technoswitch/models/new_event_log_progress.dart';
import 'package:Technoswitch/models/saved_event_log_session.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/saved_event_log_store.dart';

class SavedEventLogHistoryScreen extends StatefulWidget {
  const SavedEventLogHistoryScreen({
    super.key,
    required this.bleName,
    required this.deviceId,
    required this.onRetrieve,
    this.embedded = false,
  });

  final String bleName;
  final String deviceId;
  final Future<EventLogRetrievalHandle?> Function() onRetrieve;
  final bool embedded;

  @override
  State<SavedEventLogHistoryScreen> createState() =>
      _SavedEventLogHistoryScreenState();
}

enum _SessionSort { date, records }

class _SavedEventLogHistoryScreenState
    extends State<SavedEventLogHistoryScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _tableScroll = ScrollController();
  List<SavedEventLogSession> _sessions = <SavedEventLogSession>[];
  bool _loading = true;
  _SessionSort _sortColumn = _SessionSort.date;
  bool _sortAscending = false;
  ValueNotifier<NewEventLogProgress>? _viewing;
  bool _ownsViewing = false;
  Future<void>? _saved;
  bool _busy = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _tableScroll.dispose();
    if (_ownsViewing) _viewing?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<SavedEventLogSession> sessions =
        await SavedEventLogStore.sessionsForDevice(
          bleName: widget.bleName,
          deviceId: widget.deviceId,
        );
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _open(SavedEventLogSession session) async {
    final List<LogModel> logs = await SavedEventLogStore.logsForSession(
      session.id,
    );
    if (!mounted) return;
    if (_ownsViewing) _viewing?.dispose();
    _ownsViewing = true;
    _saved = null;
    setState(() {
      _viewing = ValueNotifier<NewEventLogProgress>(
        NewEventLogProgress(percent: 100, logs: logs, done: true),
      );
    });
  }

  Future<void> _retrieve() async {
    if (_busy) return;
    setState(() => _busy = true);
    final EventLogRetrievalHandle? handle = await widget.onRetrieve();
    if (!mounted) return;
    if (handle == null) {
      setState(() => _busy = false);
      return;
    }
    _ownsViewing = false;
    _saved = handle.saved;
    setState(() {
      _viewing = handle.progress;
      _busy = false;
    });
  }

  Future<void> _closeView() async {
    if (_closing) return;
    _closing = true;
    final bool owned = _ownsViewing;
    final ValueNotifier<NewEventLogProgress>? notifier = _viewing;
    final Future<void>? saved = _saved;
    final bool stillRunning =
        notifier != null &&
        !owned &&
        !notifier.value.done &&
        !notifier.value.failed;
    _ownsViewing = false;
    _saved = null;
    if (!stillRunning && saved != null) await saved;
    final List<SavedEventLogSession> sessions =
        await SavedEventLogStore.sessionsForDevice(
          bleName: widget.bleName,
          deviceId: widget.deviceId,
        );
    if (owned) notifier?.dispose();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _viewing = null;
      _loading = false;
      _busy = stillRunning;
    });
    _closing = false;
    if (!stillRunning || saved == null) return;
    await saved;
    if (!mounted || _viewing != null) return;
    final List<SavedEventLogSession> refreshed =
        await SavedEventLogStore.sessionsForDevice(
          bleName: widget.bleName,
          deviceId: widget.deviceId,
        );
    if (!mounted || _viewing != null) return;
    setState(() {
      _sessions = refreshed;
      _busy = false;
    });
  }

  Future<void> _delete(SavedEventLogSession session) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => const _DeleteLogHistoryDialog(),
    );
    if (confirmed != true || !mounted) return;
    await SavedEventLogStore.deleteSession(session.id);
    if (!mounted) return;
    setState(() {
      _sessions =
          _sessions
              .where((SavedEventLogSession item) => item.id != session.id)
              .toList();
    });
  }

  void _toggleSort(_SessionSort column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
        return;
      }
      _sortColumn = column;
      _sortAscending = false;
    });
  }

  String _when(DateTime time) {
    final DateTime local = time.toLocal();
    final String date = DateFormat('d MMM y').format(local);
    final String clock = DateFormat('h:mm a').format(local);
    return '$date | $clock';
  }

  String _records(SavedEventLogSession session) => '${session.logCount} Events';

  List<SavedEventLogSession> get _visible {
    final String query = _search.text.trim().toLowerCase();
    final List<SavedEventLogSession> rows =
        _sessions.where((SavedEventLogSession session) {
          if (query.isEmpty) return true;
          final String when = _when(session.retrievedAt).toLowerCase();
          return when.contains(query) ||
              _records(session).toLowerCase().contains(query);
        }).toList();
    rows.sort((SavedEventLogSession a, SavedEventLogSession b) {
      final int order =
          _sortColumn == _SessionSort.date
              ? a.retrievedAt.compareTo(b.retrievedAt)
              : a.logCount.compareTo(b.logCount);
      return _sortAscending ? order : -order;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _viewing == null ? _listBody() : _detailBody();
    if (widget.embedded) {
      return ColoredBox(
        color: ColorConstants.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_titleRow(), Expanded(child: body)],
        ),
      );
    }
    return PopScope(
      canPop: _viewing == null,
      onPopInvoked: (bool didPop) {
        if (!didPop && _viewing != null) _closeView();
      },
      child: Scaffold(
        backgroundColor: ColorConstants.backgroundGray,
        appBar: AppBar(
          title: Text(
            StringConstants.logHistory,
            style: StyleConstants.textDark16w700Style,
          ),
          backgroundColor: ColorConstants.surfaceOffWhite,
          foregroundColor: ColorConstants.black,
          elevation: 0,
          leading: IconButton(
            onPressed:
                _viewing == null
                    ? () => Navigator.of(context).pop()
                    : _closeView,
            icon: SvgPicture.asset(AssetConstants.arrowBackIcon),
          ),
        ),
        body: body,
      ),
    );
  }

  Widget _titleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          if (_viewing != null) ...[
            GestureDetector(
              onTap: _closeView,
              child: SvgPicture.asset(AssetConstants.arrowBackIcon),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            StringConstants.logHistory,
            style: StyleConstants.black16w700Style,
          ),
        ],
      ),
    );
  }

  Widget _detailBody() {
    return NewEventLogValuesScreen(
      progress: _viewing!,
      embedded: true,
      showTitle: false,
      title: StringConstants.logHistory,
    );
  }

  Widget _listBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorConstants.primary),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sessions.isEmpty)
            Expanded(child: _empty())
          else ...[
            _searchField(),
            const SizedBox(height: 12),
            Expanded(child: _table(_visible)),
          ],
          const SizedBox(height: 12),
          _retrieveButton(),
        ],
      ),
    );
  }

  Widget _empty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AssetConstants.noLogsImage,
          width: 220,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          "No event logs found currently.\nClick Retrieve Logs to fetch the latest logs.",
          style: StyleConstants.textDisabled14w500Style,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _retrieveButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          disabledBackgroundColor: ColorConstants.primary.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _busy ? null : _retrieve,
        child: Text(
          StringConstants.retrieveLogs,
          style: StyleConstants.white14w600Style,
        ),
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: StyleConstants.textDark14w500Style,
              decoration: InputDecoration(
                hintText: 'Search for Date & Time or Records',
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
                  borderSide: BorderSide(color: ColorConstants.surfaceBorder),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                  borderSide: BorderSide(color: ColorConstants.surfaceBorder),
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
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
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
    );
  }

  Widget _table(List<SavedEventLogSession> sessions) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ColorConstants.surfaceBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          Expanded(
            child:
                sessions.isEmpty
                    ? Center(
                      child: Text(
                        'No matching logs',
                        style: StyleConstants.textDark14w500Style,
                      ),
                    )
                    : _body(sessions),
          ),
        ],
      ),
    );
  }

  static const Map<int, TableColumnWidth> _widths = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.1),
    1: FlexColumnWidth(2.4),
    2: FlexColumnWidth(1.4),
    3: FlexColumnWidth(1.3),
  };

  Widget _header() {
    return ColoredBox(
      color: ColorConstants.primary,
      child: DefaultTextStyle(
        style: StyleConstants.white14w500Style,
        child: Table(
          columnWidths: _widths,
          children: [
            TableRow(
              children: [
                _cell(0, 36, const Text('Log No')),
                _cell(1, 36, _sortHeader('Date & Time', _SessionSort.date)),
                _cell(2, 36, _sortHeader('Records', _SessionSort.records)),
                _cell(3, 36, const Text('Action')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortHeader(String title, _SessionSort column) {
    final bool active = _sortColumn == column;
    return InkWell(
      onTap: () => _toggleSort(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(width: 6),
          SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: SvgPicture.asset(
                !active
                    ? AssetConstants.tsSortIcon
                    : _sortAscending
                    ? AssetConstants.tsSortUpArrow
                    : AssetConstants.tsSortUpDown,
                width: active ? 8 : 16,
                height: active ? 6 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(List<SavedEventLogSession> sessions) {
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
          child: Table(
            columnWidths: _widths,
            children: [
              for (var row = 0; row < sessions.length; row++)
                TableRow(
                  decoration: BoxDecoration(
                    color:
                        row.isEven
                            ? const Color(0xFFF4F4F4)
                            : ColorConstants.white,
                  ),
                  children: [
                    _cell(
                      0,
                      40,
                      Text(
                        '${row + 1}',
                        style: StyleConstants.textDark14w500Style,
                      ),
                    ),
                    _cell(
                      1,
                      40,
                      Text(
                        _when(sessions[row].retrievedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleConstants.textDark14w500Style,
                      ),
                    ),
                    _cell(
                      2,
                      40,
                      Text(
                        _records(sessions[row]),
                        style: StyleConstants.textDark14w500Style,
                      ),
                    ),
                    _cell(3, 40, _actions(sessions[row])),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(SavedEventLogSession session) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _open(session),
            child: SvgPicture.asset(
              AssetConstants.viewLogIcon,
              width: 30,
              height: 30,
            ),
          ),
        ),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _delete(session),
            child: SvgPicture.asset(
              AssetConstants.deleteLogIcon,
              width: 30,
              height: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(int index, double height, Widget child) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: index == 0 ? 8 : 0,
          right: index == 3 ? 8 : 0,
        ),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

class _DeleteLogHistoryDialog extends StatelessWidget {
  const _DeleteLogHistoryDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorConstants.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: ColorConstants.primary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        StringConstants.confirmation,
                        style: StyleConstants.white16w600Style,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(
                        Icons.close,
                        color: ColorConstants.white,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                children: [
                  SvgPicture.asset(AssetConstants.confirmDeleteIcon),
                  const SizedBox(height: 16),
                  Text(
                    StringConstants.deleteLogHistoryMessage,
                    style: StyleConstants.textGray14w400Style,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        StringConstants.confirm,
                        style: StyleConstants.white14w600Style,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
