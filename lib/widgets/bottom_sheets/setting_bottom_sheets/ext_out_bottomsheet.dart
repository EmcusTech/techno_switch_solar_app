import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/ext_out_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ExtOutBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ExtOutBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<ExtOutBottomSheet> createState() => ExtOutBottomSheetState();
}

class ExtOutBottomSheetState extends State<ExtOutBottomSheet> {
  late final ExtOutController controller;

  final FocusNode autoFocusNode = FocusNode();
  final FocusNode manFocusNode = FocusNode();
  final FocusNode releaseFocusNode = FocusNode();
  final FocusNode resetDelayFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    autoFocusNode.addListener(() {
      if (autoFocusNode.hasFocus) {
        debugPrint(StringConstants.autoFieldIsFocused);
      } else {
        debugPrint(StringConstants.autoFieldLostFocus);
      }
    });
    manFocusNode.addListener(() {
      if (manFocusNode.hasFocus) {
        debugPrint(StringConstants.manFieldIsFocused);
      } else {
        debugPrint(StringConstants.manFieldLostFocus);
      }
    });
    releaseFocusNode.addListener(() {
      if (releaseFocusNode.hasFocus) {
        debugPrint(StringConstants.releaseFieldIsFocused);
      } else {
        debugPrint(StringConstants.releaseFieldLostFocus);
      }
    });
    resetDelayFocusNode.addListener(() {
      if (resetDelayFocusNode.hasFocus) {
        debugPrint(StringConstants.resetDelayFieldIsFocused);
      } else {
        debugPrint(StringConstants.resetDelayFieldLostFocus);
      }
    });

    controller = Get.put(
      ExtOutController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
        embedInCreateFlow: widget.embedInCreateFlow,
      ),
    );
  }

  @override
  void dispose() {
    autoFocusNode.dispose();
    manFocusNode.dispose();
    releaseFocusNode.dispose();
    resetDelayFocusNode.dispose();
    Get.delete<ExtOutController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExtOutController>(
      init: controller,
      builder: (c) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        final formValid = c.computeIsValid();

        final scroll = NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.embedInCreateFlow) _headerRow(),
                _formFields(),
              ],
            ),
          ),
        );

        if (widget.embedInCreateFlow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: scroll)],
          );
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
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
                            _title(StringConstants.extOutMode),
                            const SizedBox(height: 4),
                            _modeBadge(),
                            const SizedBox(height: 8),
                            Expanded(child: scroll),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _downloadButton()),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: _applyButton(formValid: formValid)),
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

  Widget _modeBadge() {
    final manager = controller.manager;
    if (manager == null) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: manager.bleProcess.isExtOutApplyButtonActive,
      builder: (context, isSolar, _) {
        final bgColor = isSolar
            ? ColorConstants.successBackgroundLight
            : ColorConstants.errorBackgroundLight;

        final textColor =
            isSolar ? ColorConstants.successDark : ColorConstants.colorFfc62828;

        final icon = isSolar
            ? Icons.wb_sunny_rounded
            : Icons.settings_input_component_rounded;

        final label = isSolar ? StringConstants.solarMode : StringConstants.dipMode;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _title(StringConstants.extOutConfig),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _modeBadge(),
        ),
      ],
    );
  }

  Widget _formFields() {
    return Column(
      children: [
        DropdownWidget(
          label: StringConstants.enabled,
          value: controller.enabled,
          items: controller.enabledOptions,
          onChanged: (v) => controller.setEnabled(v),
        ),
        DropdownWidget(
          label: StringConstants.actuatorType,
          value: controller.actuatorType,
          items: controller.actuatorTypeOptions,
          onChanged: (v) => controller.setActuatorType(v),
        ),
        DropdownWidget(
          label: StringConstants.function,
          value: controller.function,
          items: controller.functionOptions,
          onChanged: (v) => controller.setFunction(v),
        ),
        _numberFieldWithValidation(
          label: StringConstants.countdownAutoS,
          fieldController: controller.autoCtrl,
          errorMsg: controller.autoError,
          focusNode: autoFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.countdownManS,
          fieldController: controller.manCtrl,
          errorMsg: controller.manError,
          focusNode: manFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.releaseTimeS,
          fieldController: controller.releaseCtrl,
          errorMsg: controller.releaseError,
          focusNode: releaseFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.resetDelayS,
          fieldController: controller.resetDelayCtrl,
          errorMsg: controller.resetDelayError,
          focusNode: resetDelayFocusNode,
        ),
        DropdownWidget(
          label: StringConstants.resetInCount,
          value: controller.resetInCount,
          items: controller.resetInCountOptions,
          onChanged: (v) => controller.setResetInCount(v),
        ),
        DropdownWidget(
          label: StringConstants.holdCount,
          value: controller.holdCount,
          items: controller.holdCountOptions,
          onChanged: (v) => controller.setHoldCount(v),
        ),
        DropdownWidget(
          label: StringConstants.action,
          value: controller.action,
          items: controller.actionOptions,
          onChanged: (v) => controller.setAction(v),
        ),
      ],
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
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColorConstants.textDark,
        ),
      ),
    );
  }

  Widget _numberFieldWithValidation({
    required String label,
    required TextEditingController fieldController,
    required String errorMsg,
    required FocusNode focusNode,
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
            onChanged: (_) => controller.onFieldChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(),
          ),
          if (focusNode.hasFocus) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ColorConstants.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;
    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.all(14),
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
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _applyButton({required bool formValid}) {
    final canApply = controller.canApply;

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
            (canApply && formValid && controller.manager != null)
                ? () async {
                  if (await controller.commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }
}
