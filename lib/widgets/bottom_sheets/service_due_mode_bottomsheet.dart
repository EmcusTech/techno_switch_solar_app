import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/service_due_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ServiceDueBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ServiceDueBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<ServiceDueBottomSheet> createState() => ServiceDueBottomSheetState();
}

class ServiceDueBottomSheetState extends State<ServiceDueBottomSheet> {
  late final ServiceDueController controller;

  final FocusNode yearFocusNode = FocusNode();
  final FocusNode monthFocusNode = FocusNode();
  final FocusNode dayFocusNode = FocusNode();
  final FocusNode hourFocusNode = FocusNode();
  final FocusNode minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    yearFocusNode.addListener(() {
      if (yearFocusNode.hasFocus) {
        debugPrint(StringConstants.yearFieldIsFocused);
      } else {
        debugPrint(StringConstants.yearFieldLostFocus);
      }
    });
    monthFocusNode.addListener(() {
      if (monthFocusNode.hasFocus) {
        debugPrint(StringConstants.monthFieldIsFocused);
      } else {
        debugPrint(StringConstants.monthFieldLostFocus);
      }
    });
    dayFocusNode.addListener(() {
      hourFocusNode.addListener(() {
        if (hourFocusNode.hasFocus) {
          debugPrint(StringConstants.hourFieldIsFocused);
        } else {
          debugPrint(StringConstants.hourFieldLostFocus);
        }
      });
      minuteFocusNode.addListener(() {
        if (minuteFocusNode.hasFocus) {
          debugPrint(StringConstants.minuteFieldIsFocused);
        } else {
          debugPrint(StringConstants.minuteFieldLostFocus);
        }
      });
    });

    controller = Get.put(
      ServiceDueController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    yearFocusNode.dispose();
    monthFocusNode.dispose();
    dayFocusNode.dispose();
    hourFocusNode.dispose();
    minuteFocusNode.dispose();
    Get.delete<ServiceDueController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServiceDueController>(
      init: controller,
      builder: (c) {
        final scroll = SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: widget.embedInCreateFlow ? 0 : 16,
            bottom: 16,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: _formColumn(),
        );

        if (widget.embedInCreateFlow) {
          return scroll;
        }

        final maxHeight = MediaQuery.of(context).size.height * 0.80;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: const BoxDecoration(
                color: ColorConstants.primaryVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(50),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(AssetConstants.bottomsheetLogo),
                          Padding(
                            padding: const EdgeInsets.only(right: 32.0),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorConstants.blackMaterial
                                      .withValues(alpha: 0.06),
                                ),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          children: [
                            _dragHandle(),
                            _title(StringConstants.serviceDueMode),
                            Expanded(child: scroll),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _downloadButton()),
                                const SizedBox(width: 12),
                                Expanded(child: _applyButton()),
                              ],
                            ),
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

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: StyleConstants.textDark20w700Style),
    );
  }

  Widget _label(String text) {
    return Text(text, style: StyleConstants.textDark13w600Style);
  }

  Widget? _relayStyleCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (!isFocused) return null;
    final max = maxLength ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$currentLength / $max',
        style: StyleConstants.primary12w400Style.copyWith(
          color: currentLength == max ? ColorConstants.primary : Colors.grey,
        ),
      ),
    );
  }

  Widget _contactField({
    required String label,
    required TextEditingController fieldController,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            keyboardType: TextInputType.phone,
            maxLength: 13,
            buildCounter: _relayStyleCounter,
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController fieldController,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            maxLength: 13,
            buildCounter: _relayStyleCounter,
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _formColumn() {
    return Column(
      children: [
        if (widget.embedInCreateFlow)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                StringConstants.serviceDueConfiguration,
                style: StyleConstants.textDark20w700Style,
              ),
            ),
          ),
        _numberField(
          label: 'Year',
          fieldController: controller.config.yearController,
          min: 0,
          max: 9999,
          errorMessage: StringConstants.yearMustBeBetween2010And9999,
          focusNode: yearFocusNode,
        ),
        _numberField(
          label: 'Month',
          fieldController: controller.config.monthController,
          min: 1,
          max: 12,
          errorMessage: StringConstants.monthMustBeBetween1And12,
          focusNode: monthFocusNode,
        ),
        _numberField(
          label: 'Day',
          fieldController: controller.config.dayController,
          min: 1,
          max: 31,
          errorMessage: StringConstants.dayMustBeBetween1And31,
          focusNode: dayFocusNode,
        ),
        _numberField(
          label: 'Hour',
          fieldController: controller.config.hourController,
          min: 0,
          max: 23,
          errorMessage: StringConstants.hourMustBeBetween0And23,
          focusNode: hourFocusNode,
        ),
        _numberField(
          label: 'Minute',
          fieldController: controller.config.minuteController,
          min: 0,
          max: 59,
          errorMessage: StringConstants.minuteMustBeBetween0And59,
          focusNode: minuteFocusNode,
        ),
        _textField(
          label: 'Company',
          fieldController: controller.config.companyController,
        ),
        _contactField(
          label: StringConstants.contact,
          fieldController: controller.config.contactController,
        ),
        DropdownWidget(
          label: StringConstants.reminder,
          value: controller.config.reminder,
          items: controller.reminderOptions,
          onChanged: (v) => controller.setReminder(v),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController fieldController,
    required int min,
    required int max,
    String? errorMessage,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
              RangeInputFormatter(min: min, max: max),
            ],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 4),
          if (errorMessage != null && focusNode?.hasFocus == true)
            Text(
              errorMessage,
              style: StyleConstants.black12w400Style.copyWith(
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: const BorderSide(color: ColorConstants.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          StringConstants.download,
          style: StyleConstants.primary16w600Style,
        ),
      ),
    );
  }

  Widget _applyButton() {
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
            (!controller.computeIsValid())
                ? null
                : () async {
                  if (await controller.commitLocal()) {
                    widget.onApply();
                  }
                },
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }
}

class RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  RangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text.length < oldValue.text.length) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value >= min && value <= max) return newValue;

    final maxDigits = max.toString().length;
    if (newValue.text.length < maxDigits && value <= max) return newValue;

    return oldValue;
  }
}
