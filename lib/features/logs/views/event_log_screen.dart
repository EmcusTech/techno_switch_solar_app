import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_list_table_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/event_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

class EventLogScreen extends StatelessWidget {
  const EventLogScreen({super.key, this.fromLogHistory = false});

  final bool fromLogHistory;

  LogController get _controller {
    if (fromLogHistory) {
      return LogBinding.findHistorySession();
    }
    return Get.find<LogController>();
  }

  @override
  Widget build(BuildContext context) {
    return _EventLogPageHost(
      controller: _controller,
      fromLogHistory: fromLogHistory,
    );
  }
}

class _EventLogPageHost extends StatefulWidget {
  const _EventLogPageHost({
    required this.controller,
    this.fromLogHistory = false,
  });

  final LogController controller;
  final bool fromLogHistory;

  @override
  State<_EventLogPageHost> createState() => _EventLogPageHostState();
}

class _EventLogPageHostState extends State<_EventLogPageHost>
    with LogUiDelegateMixin {
  LogController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (widget.fromLogHistory) {
      LogBinding.removeHistorySession();
    } else if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    super.dispose();
  }

  @override
  Future<bool?> showClearLogsDialog() async {
    return showDialog<bool>(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AssetConstants.clearIcon,
                      height: 28,
                      width: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.clearLogs,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants
                      .thisWillRemoveAllEntriesFromTheListThisCannotBeUndone,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.cancel,
                              style: StyleConstants.textGray16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.clear,
                              style: StyleConstants.white16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(
      onApply: () {
        _controller.applyFilters();
        Navigator.pop(uiContext);
      },
      onReset: () {
        _controller.resetFilters();
        Navigator.pop(uiContext);
      },
      builder: (sheetSetState) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: ColorConstants.buttonSecondaryBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        bottom: 12.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          StringConstants.filter,
                          style: StyleConstants.textBodyDark20w700Style,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 19),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringConstants.selectDate,
                      style: StyleConstants.textBodyDark14w700Style,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _controller.selectDate(true);
                              sheetSetState(() {});
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StringConstants.from,
                                  style: StyleConstants.black14w400Style,
                                ),
                                SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: ColorConstants.borderGray,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _controller.fromDate != null
                                            ? DateFormat(
                                              StringConstants.ddMMYyyyHHMmSs,
                                            ).format(_controller.fromDate!)
                                            : StringConstants.from,
                                        style:
                                            StyleConstants.textMuted14w400Style,
                                      ),
                                      Spacer(),
                                      SvgPicture.asset(
                                        AssetConstants.calendarIcon,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _controller.selectDate(false);
                              sheetSetState(() {});
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StringConstants.to,
                                  style: StyleConstants.black14w400Style,
                                ),
                                SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: ColorConstants.borderGray,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _controller.toDate != null
                                            ? DateFormat(
                                              StringConstants.ddMMYyyyHHMmSs,
                                            ).format(_controller.toDate!)
                                            : StringConstants.to,
                                        style:
                                            StyleConstants.textMuted14w400Style,
                                      ),
                                      Spacer(),
                                      SvgPicture.asset(
                                        AssetConstants.calendarIcon,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 21),
                    Text(
                      StringConstants.status2,
                      style: StyleConstants.textBodyDark14w700Style,
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          EventConstants.statusEventStatusValue.skip(1).map((
                            status,
                          ) {
                            return SizedBox(
                              width:
                                  (MediaQuery.of(uiContext).size.width - 56) /
                                  3,
                              child: SizedBox(
                                width:
                                    (MediaQuery.of(uiContext).size.width - 56) /
                                    3,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    sheetSetState(() {
                                      if (_controller.selectedStatuses.contains(
                                        status,
                                      )) {
                                        _controller.selectedStatuses.remove(
                                          status,
                                        );
                                      } else {
                                        _controller.selectedStatuses.add(
                                          status,
                                        );
                                      }
                                    });
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        value: _controller.selectedStatuses
                                            .contains(status),
                                        activeColor: ColorConstants.primary,
                                        onChanged: (value) {
                                          sheetSetState(() {
                                            if (value == true) {
                                              _controller.selectedStatuses.add(
                                                status,
                                              );
                                            } else {
                                              _controller.selectedStatuses
                                                  .remove(status);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          status,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              StyleConstants
                                                  .textMuted14w400Style,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 24),
                    Text(
                      StringConstants.eventClass,
                      style: StyleConstants.textBodyDark16w700Style,
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          EventConstants.statusEventClassNames.skip(1).map((
                            eventClass,
                          ) {
                            String displayName = eventClass;
                            if (eventClass == StringConstants.release) {
                              displayName = StringConstants.extRelease;
                            }
                            if (eventClass == StringConstants.evacuation) {
                              displayName = StringConstants.fire;
                            }

                            return SizedBox(
                              width:
                                  (MediaQuery.of(uiContext).size.width - 56) /
                                  3,
                              child: SizedBox(
                                width:
                                    (MediaQuery.of(uiContext).size.width - 56) /
                                    3,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    sheetSetState(() {
                                      if (_controller.selectedEventClasses
                                          .contains(eventClass)) {
                                        _controller.selectedEventClasses.remove(
                                          eventClass,
                                        );
                                      } else {
                                        _controller.selectedEventClasses.add(
                                          eventClass,
                                        );
                                      }
                                    });
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        value: _controller.selectedEventClasses
                                            .contains(eventClass),
                                        activeColor: ColorConstants.primary,
                                        onChanged: (value) {
                                          sheetSetState(() {
                                            if (value == true) {
                                              _controller.selectedEventClasses
                                                  .add(eventClass);
                                            } else {
                                              _controller.selectedEventClasses
                                                  .remove(eventClass);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              StyleConstants
                                                  .textMuted14w400Style,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _controller.resetFilters();
                            Navigator.pop(uiContext);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 32,
                            ),
                            side: BorderSide(color: ColorConstants.transparent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            StringConstants.reset,
                            style: StyleConstants.textBodyDark14w600Style,
                          ),
                        ),
                        SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            _controller.applyFilters();
                            Navigator.pop(uiContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorConstants.primary,
                              borderRadius: BorderRadius.circular(28.5),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 13,
                                ),
                                child: Text(
                                  StringConstants.applyNow,
                                  style: StyleConstants.white14boldStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogStatus(List<LogModel> logsToDisplay) {
    final panelName = _controller.resolvedPanelName();
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _controller.panelDisplayName(panelName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleConstants.textDark16w700Style,
                    ),
                    Text(
                      BleNameUtils.getDisplayIdFromBleName(panelName),
                      style: StyleConstants.textDisabled14w500Style,
                    ),
                    ValueListenableBuilder(
                      valueListenable: _controller.ble.isConnectedNotifier,
                      builder: (context, isConnected, child) {
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: StringConstants.status3,
                                style: StyleConstants.textDisabled14w500Style,
                              ),
                              TextSpan(
                                text:
                                    isConnected
                                        ? StringConstants.connected
                                        : StringConstants.disconnected,
                                style: StyleConstants.primary14w500Style
                                    .copyWith(
                                      color:
                                          isConnected
                                              ? ColorConstants.success
                                              : ColorConstants.primary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: ColorConstants.black.withAlpha(46), thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                StringConstants.logView,
                style: StyleConstants.textBodyDark16w700Style,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 98,
                    height: 32,
                    child: TextField(
                      controller: _controller.eventIdFilterController,
                      onChanged: (_) => _controller.onEventIdFilterChanged(),
                      keyboardType: TextInputType.text,
                      textAlignVertical: TextAlignVertical.center,
                      style: StyleConstants.textBodyDark13w500Style,
                      decoration: InputDecoration(
                        hintText: StringConstants.id,
                        hintStyle: StyleConstants.divider12w400Style,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.borderMedium,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.borderMedium,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon:
                            _controller.eventIdFilterController.text.isNotEmpty
                                ? IconButton(
                                  iconSize: 16,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: ColorConstants.textMuted,
                                  ),
                                  onPressed: () {
                                    _controller.eventIdFilterController.clear();
                                    _controller.onEventIdFilterChanged();
                                  },
                                )
                                : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.setListSelected(true);
                      _controller.setSelectedViewIndex(0);
                    },
                    child:
                        _controller.isListSelected
                            ? Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: SvgPicture.asset(
                                  AssetConstants.listDeselectedIcon,
                                  colorFilter: ColorFilter.mode(
                                    ColorConstants.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            )
                            : SvgPicture.asset(
                              AssetConstants.listDeselectedIcon,
                            ),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      _controller.setListSelected(false);
                      _controller.setSelectedViewIndex(1);
                    },
                    child:
                        _controller.isListSelected
                            ? SvgPicture.asset(
                              AssetConstants.tableDeselectedIcon,
                            )
                            : Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: SvgPicture.asset(
                                  AssetConstants.tableDeselectedIcon,
                                  colorFilter: ColorFilter.mode(
                                    ColorConstants.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 15),
          Expanded(
            child: IndexedStack(
              index: _controller.selectedViewIndex,
              children: [
                _LogListView(displayLogs: logsToDisplay),
                _LogTableView(displayLogs: logsToDisplay),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LogController>(
      tag: widget.fromLogHistory ? LogBinding.historySessionTag : null,
      init: widget.fromLogHistory ? widget.controller : null,
      builder: (controller) {
        final Widget logsSection =
            controller.useProvidedLogs
                ? _buildLogStatus(controller.getDisplayLogs())
                : ValueListenableBuilder<List<LogModel>>(
                  valueListenable: controller.ble.bleProcess.validEventLogs,
                  builder: (context, _, __) {
                    return _buildLogStatus(controller.getDisplayLogs());
                  },
                );

        return Scaffold(
          extendBody: true,
          body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              await controller.handleEventLogBackNavigation();
            },
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorConstants.scaffoldGradientTop,
                    ColorConstants.white,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  SvgPicture.asset(AssetConstants.background1),
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap:
                                    () async =>
                                        await controller
                                            .handleEventLogBackNavigation(),
                                child: SvgPicture.asset(
                                  AssetConstants.arrowBackIcon,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                StringConstants.eventLog,
                                style: StyleConstants.black20w700Style,
                              ),
                              const Spacer(),
                              if (controller.eventLogArgs?.isLiveEventLogs ==
                                  true)
                                Padding(
                                  padding: const EdgeInsets.only(right: 18.0),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        controller.canClearLogs
                                            ? () =>
                                                controller.confirmAndClearLogs()
                                            : null,
                                    child: Opacity(
                                      opacity:
                                          controller.canClearLogs ? 1.0 : 0,
                                      child: SvgPicture.asset(
                                        AssetConstants.clearIcon,
                                        height: 28,
                                        width: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap:
                                    () => showExportBottomSheet(
                                      onExportPdf: controller.exportEventLogPdf,
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: SvgPicture.asset(
                                    AssetConstants.shareIcon,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showFilterBottomSheet,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: SvgPicture.asset(
                                    AssetConstants.filterIcon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 19),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: logsSection,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum DataType {
  id,
  dateTime,
  status,
  eventClass,
  type,
  subType,
  source,
  identifier,
  text,
  panelNo,
  moduleNo,
  lBusNo,
}

class _LogListView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const _LogListView({required this.displayLogs});

  @override
  State<_LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<_LogListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _horizontalController = ScrollController();
  late final LogListTableController _tableController;

  static const double wEventId = 80;
  static const double wDateTime = 140;
  static const double wEventStatus = 100;
  static const double wEventClass = 90;
  static const double wEventType = 160;
  static const double wEventSubType = 200;
  static const double wEventSource = 120;
  static const double wIdentifier = 180;
  static const double wText = 150;
  static const double wPanelNo = 100;
  static const double wModuleNo = 100;
  static const double wLbusNo = 90;

  late final double _totalTableWidth =
      wEventId +
      wDateTime +
      wEventStatus +
      wEventClass +
      wEventType +
      wEventSubType +
      wEventSource +
      wIdentifier +
      wText +
      wPanelNo +
      wModuleNo +
      wLbusNo;

  static const double _rowHeight = 72.0;
  static const double _headerHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _tableController = Get.put(
      LogListTableController(displayLogs: widget.displayLogs),
    );
  }

  @override
  void didUpdateWidget(_LogListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayLogs.length != oldWidget.displayLogs.length ||
        !listEquals(widget.displayLogs, oldWidget.displayLogs)) {
      _tableController.updateDisplayLogs(widget.displayLogs);
    }
  }

  @override
  void dispose() {
    Get.delete<LogListTableController>();
    _horizontalController.dispose();
    super.dispose();
  }

  Widget _buildHeader(LogListTableController table) {
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: ColorConstants.white,
      child: Row(
        children: [
          _buildHeaderCell(
            table,
            StringConstants.id,
            wEventId,
            StringConstants.eventid,
          ),
          _buildHeaderCell(
            table,
            StringConstants.dateTime,
            wDateTime,
            StringConstants.datetime,
          ),
          _buildHeaderCell(table, 'Status', wEventStatus, 'status'),
          _buildHeaderCell(
            table,
            StringConstants.classLabel,
            wEventClass,
            'class',
          ),
          _buildHeaderCell(table, StringConstants.type, wEventType, 'type'),
          _buildHeaderCell(
            table,
            StringConstants.subType,
            wEventSubType,
            StringConstants.subtype,
          ),
          _buildHeaderCell(
            table,
            StringConstants.source,
            wEventSource,
            'source',
          ),
          _buildHeaderCell(table, 'Identifier', wIdentifier, 'identifier'),
          _buildHeaderCell(table, StringConstants.text, wText, 'text'),
          _buildHeaderCell(
            table,
            'Panel no',
            wPanelNo,
            StringConstants.panelno,
          ),
          _buildHeaderCell(
            table,
            'Module no',
            wModuleNo,
            StringConstants.moduleno,
          ),
          _buildHeaderCell(table, 'L-Bus no', wLbusNo, StringConstants.lbusno),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    LogListTableController table,
    String text,
    double width,
    String columnKey,
  ) {
    final bool isActive = table.sortColumn == columnKey;

    return GestureDetector(
      onTap: () => table.sortByColumn(columnKey),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                style: StyleConstants.primary12w600Style.copyWith(
                  color:
                      isActive
                          ? ColorConstants.primary
                          : ColorConstants.textBodyDark,
                ),
              ),
            ),
            SizedBox(width: 4),
            if (isActive)
              Icon(
                table.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: ColorConstants.primary,
              )
            else
              Icon(
                Icons.unfold_more,
                size: 16,
                color: ColorConstants.textPlaceholder,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, DataType dataType) {
    TextStyle textStyle = TextStyle();
    if (dataType == DataType.id) {
      textStyle = StyleConstants.textSecondary13boldStyle;
    } else if (dataType == DataType.dateTime) {
      textStyle = StyleConstants.textSecondary12w400Style;
    } else {
      textStyle = StyleConstants.textSecondary13w400Style;
    }
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GetBuilder<LogListTableController>(
      init: _tableController,
      builder: (table) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableHeight = constraints.maxHeight;

            return SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: _totalTableWidth + 16,
                height: availableHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(table),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: table.sortedLogs.length,
                        itemBuilder: (context, index) {
                          final log = table.sortedLogs[index];
                          return Column(
                            children: [
                              if (index > 0) const Divider(height: 1),
                              Container(
                                color:
                                    index % 2 == 0
                                        ? ColorConstants.white
                                        : ColorConstants.surfaceOffWhite,
                                height: _rowHeight,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildDataCell(
                                      log.eventId ?? '',
                                      wEventId,
                                      DataType.id,
                                    ),
                                    _buildDataCell(
                                      log.eventDateTime != null
                                          ? DateFormat(
                                            'dd/MM/yyyy\nhh:mm:ss a',
                                          ).format(log.eventDateTime!)
                                          : '',
                                      wDateTime,
                                      DataType.dateTime,
                                    ),
                                    _buildDataCell(
                                      log.eventStatus ?? '',
                                      wEventStatus,
                                      DataType.status,
                                    ),
                                    _buildDataCell(
                                      log.eventClass ?? '',
                                      wEventClass,
                                      DataType.eventClass,
                                    ),
                                    _buildDataCell(
                                      log.eventType ?? '',
                                      wEventType,
                                      DataType.type,
                                    ),
                                    _buildDataCell(
                                      log.eventSubType ?? '',
                                      wEventSubType,
                                      DataType.subType,
                                    ),
                                    _buildDataCell(
                                      log.eventSource ?? '',
                                      wEventSource,
                                      DataType.source,
                                    ),
                                    _buildDataCell(
                                      log.identifier ?? '',
                                      wIdentifier,
                                      DataType.identifier,
                                    ),
                                    _buildDataCell(
                                      log.text ?? '',
                                      wText,
                                      DataType.text,
                                    ),
                                    _buildDataCell(
                                      log.panelNo ?? '',
                                      wPanelNo,
                                      DataType.panelNo,
                                    ),
                                    _buildDataCell(
                                      log.moduleNo ?? '',
                                      wModuleNo,
                                      DataType.moduleNo,
                                    ),
                                    _buildDataCell(
                                      log.lBusNo ?? '',
                                      wLbusNo,
                                      DataType.lBusNo,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LogTableView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const _LogTableView({required this.displayLogs});

  @override
  State<_LogTableView> createState() => _LogTableViewState();
}

class _LogTableViewState extends State<_LogTableView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scrollbar(
      controller: _scrollController,
      trackVisibility: true,
      interactive: true,
      thickness: 12,
      radius: const Radius.circular(10),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: widget.displayLogs.length,
        separatorBuilder: (context, index) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final log = widget.displayLogs[index];
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstants.zebraStripeLight,
              border: Border.all(color: ColorConstants.borderMedium, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 19,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        log.eventDateTime != null
                            ? DateFormat(
                              StringConstants.ddMMYyyyHhMmSsA,
                            ).format(log.eventDateTime!.toLocal())
                            : StringConstants.nA,
                        style: StyleConstants.textSecondary12w400Style,
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.accentBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 0.5,
                          ),
                          child: Text(
                            log.eventId ?? '-',
                            style: StyleConstants.white13w700Style,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                        StringConstants.panelNo,
                        log.panelNo ?? '',
                      ),
                      _buildInfoColumn(
                        StringConstants.lBusNo,
                        log.lBusNo ?? '',
                      ),
                      _buildInfoColumn(
                        StringConstants.moduleNo,
                        log.moduleNo ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Status', log.eventStatus ?? ''),
                      _buildInfoColumn('Event Class', log.eventClass ?? ''),
                      _buildInfoColumn(
                        StringConstants.source,
                        log.eventSource ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Event Type', log.eventType ?? ''),
                      _buildInfoColumn(
                        StringConstants.eventType,
                        log.eventSubType ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Identifier', log.identifier ?? ''),
                      _buildInfoColumn(StringConstants.text, log.text ?? ''),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: StyleConstants.textBodyDark14w700Style),
          Text(value, style: StyleConstants.textSecondary14w400Style),
        ],
      ),
    );
  }
}
