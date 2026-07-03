import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/peripherals/inputs/controllers/input_mode_controller.dart';
import 'package:techno_switch_solar_app/widgets/common/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class InputModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const InputModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<InputModeBottomSheet> createState() => InputModeBottomSheetState();
}

class InputModeBottomSheetState extends State<InputModeBottomSheet> {
  late final InputModeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      InputModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<InputModeController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  Widget _formColumn() {
    return Column(
      children: [
        if (widget.embedInCreateFlow) _title('Input Mode Configuration'),
        _readOnlyField(
          StringConstants.inputModeConfiguration,
          StringConstants.progIN1,
        ),
        _inputTextField(),
        DropdownWidget(
          label: StringConstants.group,
          value: controller.group,
          items: controller.groupOptions,
          onChanged: (v) => controller.setGroup(v),
        ),
        DropdownWidget(
          label: StringConstants.function,
          value: controller.function,
          items: controller.functionOptionsMap[controller.group]!,
          onChanged: (v) => controller.setFunction(v),
        ),
        DropdownWidget(
          label: StringConstants.enabled,
          value: controller.enabled,
          items: controller.yesNoOptions,
          onChanged: (v) => controller.setEnabled(v),
        ),
        DropdownWidget(
          label: StringConstants.test,
          value: controller.test,
          items: controller.yesNoOptions,
          onChanged: (v) => controller.setTest(v),
        ),
        DropdownWidget(
          label: StringConstants.inverted,
          value: controller.inverted,
          items: controller.yesNoOptions,
          onChanged: (v) => controller.setInverted(v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InputModeController>(
      init: controller,
      builder: (c) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        c.updateValidationErrors();
        final isValid = c.computeIsValid();

        final scroll = NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: widget.embedInCreateFlow ? 0 : 16),
            child: _formColumn(),
          ),
        );

        if (widget.embedInCreateFlow) {
          return scroll;
        }

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
                          left: 24.0,
                          right: 24.0,
                          top: 16.0,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          children: [
                            _dragHandle(),
                            _title(StringConstants.inputMode),
                            Expanded(child: scroll),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _downloadButton()),
                                const SizedBox(width: 12),
                                Expanded(child: _applyButton(isValid: isValid)),
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

  // ───────────── UI HELPERS ─────────────

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

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: ColorConstants.colorFff0F0F0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderLight),
            ),
            child: Text(value, style: StyleConstants.textDark14w500Style),
          ),
        ],
      ),
    );
  }

  Widget _inputTextField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(StringConstants.inputText),
          const SizedBox(height: 6),
          TextField(
            controller: controller.inputTextCtrl,
            maxLength: 21,
            buildCounter: (
              context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              if (!isFocused) return null;

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "$currentLength / 21",
                  style: StyleConstants.primary12w400Style.copyWith(
                    color:
                        currentLength == 21
                            ? ColorConstants.primary
                            : Colors.grey,
                  ),
                ),
              );
            },
            inputFormatters: [LengthLimitingTextInputFormatter(21)],
            decoration: _inputDecoration(
              hasError: controller.inputTextError != null,
            ),
            style: StyleConstants.textDark14w500Style,
          ),
          if (controller.inputTextError != null) ...[
            const SizedBox(height: 4),
            Text(
              controller.inputTextError!,
              style: StyleConstants.primary12w500Style,
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;

    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _applyButton({required bool isValid}) {
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
                ? () async {
                  if (await controller.commitLocal()) {
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
}
