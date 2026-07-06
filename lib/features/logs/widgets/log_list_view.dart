import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_list_table_controller.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/data_cell.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/header_cell.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogListView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const LogListView({super.key, required this.displayLogs});

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _horizontalController = ScrollController();
  late final LogListTableController _tableController;

  static const double wEventId = 80;
  static const double wDateTime = 140;
  static const double wEventStatus = 100;
  static const double wEventClass = 110;
  static const double wEventType = 160;
  static const double wEventSubType = 120;
  static const double wEventSource = 150;
  static const double wIdentifier = 180;
  static const double wText = 180;
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
  void didUpdateWidget(LogListView oldWidget) {
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
          HeaderCell(
            table: table,
            text: StringConstants.id,
            width: wEventId,
            columnKey: StringConstants.eventid,
          ),
          HeaderCell(
            table: table,
            text: StringConstants.dateTime,
            width: wDateTime,
            columnKey: StringConstants.datetime,
          ),
          HeaderCell(
            table: table,
            text: 'Status',
            width: wEventStatus,
            columnKey: 'status',
          ),
          HeaderCell(
            table: table,
            text: StringConstants.classLabel,
            width: wEventClass,
            columnKey: 'class',
          ),
          HeaderCell(
            table: table,
            text: StringConstants.type,
            width: wEventType,
            columnKey: 'type',
          ),
          HeaderCell(
            table: table,
            text: StringConstants.subType,
            width: wEventSubType,
            columnKey: StringConstants.subtype,
          ),
          HeaderCell(
            table: table,
            text: StringConstants.source,
            width: wEventSource,
            columnKey: 'source',
          ),
          HeaderCell(
            table: table,
            text: 'Identifier',
            width: wIdentifier,
            columnKey: 'identifier',
          ),
          HeaderCell(
            table: table,
            text: StringConstants.text,
            width: wText,
            columnKey: 'text',
          ),
          HeaderCell(
            table: table,
            text: 'Panel no',
            width: wPanelNo,
            columnKey: StringConstants.panelno,
          ),
          HeaderCell(
            table: table,
            text: 'Module no',
            width: wModuleNo,
            columnKey: StringConstants.moduleno,
          ),
          HeaderCell(
            table: table,
            text: 'L-Bus no',
            width: wLbusNo,
            columnKey: StringConstants.lbusno,
          ),
        ],
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
                                    DataCells(
                                      text: log.eventId ?? '',
                                      width: wEventId,
                                      dataType: DataType.id,
                                    ),
                                    DataCells(
                                      text:
                                          log.eventDateTime != null
                                              ? DateFormat(
                                                'dd/MM/yyyy\nhh:mm:ss a',
                                              ).format(log.eventDateTime!)
                                              : '',
                                      width: wDateTime,
                                      dataType: DataType.dateTime,
                                    ),
                                    DataCells(
                                      text: log.eventStatus ?? '',
                                      width: wEventStatus,
                                      dataType: DataType.status,
                                    ),
                                    DataCells(
                                      text: log.eventClass ?? '',
                                      width: wEventClass,
                                      dataType: DataType.eventClass,
                                    ),
                                    DataCells(
                                      text: log.eventType ?? '',
                                      width: wEventType,
                                      dataType: DataType.type,
                                    ),
                                    DataCells(
                                      text: log.eventSubType ?? '',
                                      width: wEventSubType,
                                      dataType: DataType.subType,
                                    ),
                                    DataCells(
                                      text: log.eventSource ?? '',
                                      width: wEventSource,
                                      dataType: DataType.source,
                                    ),
                                    DataCells(
                                      text: log.identifier ?? '',
                                      width: wIdentifier,
                                      dataType: DataType.identifier,
                                    ),
                                    DataCells(
                                      text: log.text ?? '',
                                      width: wText,
                                      dataType: DataType.text,
                                    ),
                                    DataCells(
                                      text: log.panelNo ?? '',
                                      width: wPanelNo,
                                      dataType: DataType.panelNo,
                                    ),
                                    DataCells(
                                      text: log.moduleNo ?? '',
                                      width: wModuleNo,
                                      dataType: DataType.moduleNo,
                                    ),
                                    DataCells(
                                      text: log.lBusNo ?? '',
                                      width: wLbusNo,
                                      dataType: DataType.lBusNo,
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
