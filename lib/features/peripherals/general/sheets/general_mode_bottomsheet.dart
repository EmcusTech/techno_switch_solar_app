import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/peripherals/general/controllers/general_module_controller.dart';
import 'package:techno_switch_solar_app/widgets/common/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class GeneralModuleBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  /// Full-screen create-site step: no sheet chrome; use [GeneralModuleBottomSheetState.commitLocal] on Next.
  final bool embedInCreateFlow;

  const GeneralModuleBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<GeneralModuleBottomSheet> createState() =>
      GeneralModuleBottomSheetState();
}

class GeneralModuleBottomSheetState extends State<GeneralModuleBottomSheet> {
  late final GeneralModuleController controller;

  final FocusNode lvlTimeoutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    lvlTimeoutFocusNode.addListener(() {
      if (lvlTimeoutFocusNode.hasFocus) {
        debugPrint(StringConstants.lvlTimeOutFieldIsFocused);
      } else {
        debugPrint(StringConstants.lvlTimeOutFieldLostFocus);
      }
    });

    controller = Get.put(
      GeneralModuleController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    lvlTimeoutFocusNode.dispose();
    Get.delete<GeneralModuleController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  Widget _fieldsColumn() {
    return Column(
      children: [
        if (widget.embedInCreateFlow) _title(StringConstants.generalModule),
        _numberField(
          StringConstants.lvlTimeOutS,
          controller.lvlTimeoutController,
          maxLength: 3,
          focusNode: lvlTimeoutFocusNode,
        ),
        DropdownWidget(
          label: StringConstants.silenceBuzzerLevel2,
          value: controller.silenceBuzzerLevel,
          items: controller.buzzerOptions,
          onChanged: (v) => controller.setSilenceBuzzerLevel(v),
        ),
        DropdownWidget(
          label: StringConstants.silenceSoundersLevel2,
          value: controller.silenceSoundersLevel,
          items: controller.sounderOptions,
          onChanged: (v) => controller.setSilenceSoundersLevel(v),
        ),
        DropdownWidget(
          label: StringConstants.resetLevel2,
          value: controller.resetLevel,
          items: controller.resetOptions,
          onChanged: (v) => controller.setResetLevel(v),
        ),
        DropdownWidget(
          label: StringConstants.faultLatching,
          value: controller.faultLatching,
          items: controller.yesNoOptions,
          onChanged: (v) => controller.setFaultLatching(v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GeneralModuleController>(
      init: controller,
      builder: (c) {
        final scroll = NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: widget.embedInCreateFlow ? 0 : 16,
              bottom: 16,
            ),
            child: _fieldsColumn(),
          ),
        );

        if (widget.embedInCreateFlow) {
          return scroll;
        }

        final maxHeight = MediaQuery.of(context).size.height * 0.75;

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
                            _title(StringConstants.generalMode),
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

  // ───────── INPUTS ─────────

  Widget _numberField(
    String label,
    TextEditingController fieldController, {
    int? maxLength,
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => controller.onLvlTimeoutChanged(),
            decoration: _inputDecoration(),
          ),
          if (focusNode.hasFocus)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  StringConstants.lvlTimeOutMustBeBetween30And300Seconds,
                  style: StyleConstants.black12w400Style.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: StyleConstants.textDark13w600Style);
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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }

  // ───────── COMMON UI ─────────

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
            controller.computeIsValid()
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
