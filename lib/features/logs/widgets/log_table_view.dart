import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogTableView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const LogTableView({super.key, required this.displayLogs});

  @override
  State<LogTableView> createState() => _LogTableViewState();
}

class _LogTableViewState extends State<LogTableView>
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
