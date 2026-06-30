import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/radio_mode_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class RadioModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const RadioModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<RadioModeBottomSheet> createState() => _RadioModeBottomSheetState();
}

class _RadioModeBottomSheetState extends State<RadioModeBottomSheet> {
  late final RadioModeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      RadioModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<RadioModeController>();
    super.dispose();
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RadioModeController>(
      init: controller,
      builder: (c) {
        final screenHeight = MediaQuery.of(context).size.height;

        c.updateValidationErrors();
        final isValid = c.computeIsValid();

        return SafeArea(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
              child: Container(
                decoration: const BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  children: [
                    _dragHandle(),
                    _title(StringConstants.radioConfiguration),
                    Expanded(
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          if (notification.direction != ScrollDirection.idle) {
                            FocusScope.of(context).unfocus();
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16),
                          child: _radioFields(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _downloadButton()),
                        const SizedBox(width: 12),
                        Expanded(child: _applyButton(isValid)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────── FIELDS ─────────────────

  Widget _radioFields() {
    final radio = controller.radio;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.borderMuted),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _disabledField(StringConstants.enabled, StringConstants.yes),
          DropdownWidget(
            label: StringConstants.module,
            value: radio.module,
            items: controller.moduleOptions,
            onChanged: (v) => controller.setModule(v),
          ),
          _textField(
            label: StringConstants.name,
            fieldController: radio.nameController,
            error: controller.nameError,
            maxLength: 21,
          ),
          _textField(
            label: 'Number',
            fieldController: radio.numberController,
            error: controller.numberError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          DropdownWidget(
            label: StringConstants.advertise,
            value: radio.advertise,
            items: controller.yesNoOptions,
            onChanged: (v) => controller.setAdvertise(v),
          ),
          DropdownWidget(
            label: StringConstants.connection,
            value: radio.connection,
            items: controller.yesNoOptions,
            onChanged: (v) => controller.setConnection(v),
          ),
          DropdownWidget(
            label: StringConstants.service,
            value: radio.service,
            items: controller.yesNoOptions,
            onChanged: (v) => controller.setService(v),
          ),
          DropdownWidget(
            label: StringConstants.programming,
            value: radio.programming,
            items: controller.yesNoOptions,
            onChanged: (v) => controller.setProgramming(v),
          ),
          DropdownWidget(
            label: StringConstants.boot,
            value: radio.boot,
            items: controller.yesNoOptions,
            onChanged: (v) => controller.setBoot(v),
          ),
        ],
      ),
    );
  }

  // ───────────────── APPLY ─────────────────

  Widget _applyButton(bool isValid) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            isValid && controller.manager != null
                ? () {
                  controller.pushToManager();
                  widget.onApply();
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: widget.onDownload,
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: const BorderSide(color: ColorConstants.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          StringConstants.download,
          style: StyleConstants.primary16w600Style,
        ),
      ),
    );
  }

  // ───────────────── SHARED UI ─────────────────

  Widget _textField({
    required String label,
    required TextEditingController fieldController,
    String? error,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: _inputDecoration(hasError: error != null),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error, style: StyleConstants.primary12w400Style),
            ),
        ],
      ),
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
      child: Text(text, style: StyleConstants.black20w700Style),
    );
  }

  Widget _disabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderLight),
            ),
            alignment: Alignment.centerLeft,
            child: Text(value, style: StyleConstants.textDark14w500Style),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: StyleConstants.black13w600Style);
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;

    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }
}
