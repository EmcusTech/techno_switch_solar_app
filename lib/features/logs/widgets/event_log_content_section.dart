import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_list_view.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_table_view.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class EventLogContentSection extends StatelessWidget {
  const EventLogContentSection({
    super.key,
    required this.controller,
    required this.logsToDisplay,
  });

  final LogController controller;
  final List<LogModel> logsToDisplay;

  @override
  Widget build(BuildContext context) {
    final panelName = controller.resolvedPanelName();
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
                      controller.panelDisplayName(panelName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleConstants.textDark16w700Style,
                    ),
                    Text(
                      BleNameUtils.getDisplayIdFromBleName(panelName),
                      style: StyleConstants.textDisabled14w500Style,
                    ),
                    ValueListenableBuilder(
                      valueListenable: controller.ble.isConnectedNotifier,
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
                      controller: controller.eventIdFilterController,
                      onChanged: (_) => controller.onEventIdFilterChanged(),
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
                            controller.eventIdFilterController.text.isNotEmpty
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
                                    controller.eventIdFilterController.clear();
                                    controller.onEventIdFilterChanged();
                                  },
                                )
                                : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      controller.setListSelected(true);
                      controller.setSelectedViewIndex(0);
                    },
                    child:
                        controller.isListSelected
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
                      controller.setListSelected(false);
                      controller.setSelectedViewIndex(1);
                    },
                    child:
                        controller.isListSelected
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
              index: controller.selectedViewIndex,
              children: [
                LogListView(displayLogs: logsToDisplay),
                LogTableView(displayLogs: logsToDisplay),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
