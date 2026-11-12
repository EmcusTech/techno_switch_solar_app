import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/peripherals/date_time/controllers/panel_date_time_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

class PanelDateTimeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const PanelDateTimeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<PanelDateTimeBottomSheet> createState() =>
      _PanelDateTimeBottomSheetState();
}

class _PanelDateTimeBottomSheetState extends State<PanelDateTimeBottomSheet> {
  late final PanelDateTimeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PanelDateTimeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PanelDateTimeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PanelDateTimeController>(
      init: controller,
      builder: (c) {
        final scroll = SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: peripheralSheetScrollPadding(top: 16, bottom: 16),
          child: _form(c),
        );

        final maxHeight = MediaQuery.of(context).size.height * 0.80;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: PeripheralSheetChrome.lipColor,
                borderRadius: PeripheralSheetChrome.topRadius(),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: PeripheralSheetChrome.lipPadding),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: PeripheralSheetChrome.topRadius(),
                  ),
                  child: Stack(
                    children: [
                      const PeripheralSheetHeaderRow(),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          children: [
                            const PeripheralSheetDragHandle(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  StringConstants.dateTime,
                                  style: StyleConstants.textDark20w700Style,
                                ),
                              ),
                            ),
                            Expanded(child: scroll),
                            const SizedBox(height: 12),
                            _applyButton(c),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _form(PanelDateTimeController c) {
    final locked = c.useSystemTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  StringConstants.useSystemTime,
                  style: StyleConstants.black16w600Style,
                ),
              ),
              Switch(value: c.useSystemTime, onChanged: c.toggleSystemTime),
            ],
          ),
        ),
        peripheralSheetFieldGrid([
          DropdownWidget(
            label: StringConstants.hour,
            value: _two(c.hour),
            items: _range(0, 23),
            enabled: !locked,
            onChanged: (value) => c.setHour(int.parse(value)),
          ),
          DropdownWidget(
            label: StringConstants.minute,
            value: _two(c.minute),
            items: _range(0, 59),
            enabled: !locked,
            onChanged: (value) => c.setMinute(int.parse(value)),
          ),
          DropdownWidget(
            label: StringConstants.second,
            value: _two(c.second),
            items: _range(0, 59),
            enabled: !locked,
            onChanged: (value) => c.setSecond(int.parse(value)),
          ),
          DropdownWidget(
            label: StringConstants.dateField,
            value: _two(c.day),
            items: _range(1, c.daysInMonth),
            enabled: !locked,
            onChanged: (value) => c.setDay(int.parse(value)),
          ),
          DropdownWidget(
            label: StringConstants.month,
            value: _two(c.month),
            items: _range(1, 12),
            enabled: !locked,
            onChanged: (value) => c.setMonth(int.parse(value)),
          ),
          DropdownWidget(
            label: StringConstants.year,
            value: c.year.toString(),
            items: c.yearChoices.map((year) => year.toString()).toList(),
            enabled: !locked,
            onChanged: (value) => c.setYear(int.parse(value)),
          ),
        ]),
      ],
    );
  }

  Widget _applyButton(PanelDateTimeController c) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            c.computeIsValid()
                ? () async {
                  if (await c.commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static List<String> _range(int start, int end) {
    return <String>[for (var value = start; value <= end; value++) _two(value)];
  }
}
