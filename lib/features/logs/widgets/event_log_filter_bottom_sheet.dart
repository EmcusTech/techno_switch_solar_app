import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/event_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class EventLogFilterBottomSheet extends StatelessWidget {
  const EventLogFilterBottomSheet({
    super.key,
    required this.controller,
    required this.onSheetStateChange,
    required this.onApply,
    required this.onReset,
  });

  final LogController controller;
  final VoidCallback onSheetStateChange;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final columnWidth = (MediaQuery.sizeOf(context).width - 56) / 3;

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
                      child: _DatePickerField(
                        label: StringConstants.from,
                        date: controller.fromDate,
                        onTap: () async {
                          await controller.selectDate(true);
                          onSheetStateChange();
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: StringConstants.to,
                        date: controller.toDate,
                        onTap: () async {
                          await controller.selectDate(false);
                          onSheetStateChange();
                        },
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
                        return _FilterCheckboxTile(
                          width: columnWidth,
                          label: status,
                          isSelected: controller.selectedStatuses.contains(
                            status,
                          ),
                          onChanged: (_) {
                            controller.toggleStatus(status);
                            onSheetStateChange();
                          },
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
                        var displayName = eventClass;
                        if (eventClass == StringConstants.release) {
                          displayName = StringConstants.extRelease;
                        }
                        if (eventClass == StringConstants.evacuation) {
                          displayName = StringConstants.fire;
                        }

                        return _FilterCheckboxTile(
                          width: columnWidth,
                          label: displayName,
                          isSelected: controller.selectedEventClasses.contains(
                            eventClass,
                          ),
                          onChanged: (_) {
                            controller.toggleEventClass(eventClass);
                            onSheetStateChange();
                          },
                        );
                      }).toList(),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: onReset,
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
                      onTap: onApply,
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
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StyleConstants.black14w400Style),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: ColorConstants.borderGray),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  date != null
                      ? DateFormat(
                        StringConstants.ddMMYyyyHHMmSs,
                      ).format(date!)
                      : label,
                  style: StyleConstants.textMuted14w400Style,
                ),
                Spacer(),
                SvgPicture.asset(AssetConstants.calendarIcon),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCheckboxTile extends StatelessWidget {
  const _FilterCheckboxTile({
    required this.width,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  final double width;
  final String label;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onChanged(!isSelected),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              value: isSelected,
              activeColor: ColorConstants.primary,
              onChanged: onChanged,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleConstants.textMuted14w400Style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
