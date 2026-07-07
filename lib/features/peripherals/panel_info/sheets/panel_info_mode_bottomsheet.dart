import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/peripherals/panel_info/controllers/panel_info_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class PanelInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const PanelInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<PanelInfoBottomSheet> createState() => PanelInfoBottomSheetState();
}

class PanelInfoBottomSheetState extends State<PanelInfoBottomSheet> {
  late final PanelInfoController controller;

  int _expandedTileCount = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PanelInfoController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PanelInfoController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  Widget _scrollContent() {
    return NotificationListener<UserScrollNotification>(
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
            if (widget.embedInCreateFlow)
              _title(StringConstants.panelInformation),
            _panelInfoTile(),
            _dateTimeTile(),
            _eventReminderTile(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PanelInfoController>(
      init: controller,
      builder: (c) {
        final screenHeight = MediaQuery.of(context).size.height;

        if (widget.embedInCreateFlow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: _scrollContent())],
          );
        }

        final maxHeight =
            _expandedTileCount > 0 ? screenHeight * 0.80 : screenHeight * 0.50;

        return SafeArea(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
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
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              _dragHandle(),
                              _title(StringConstants.panelInfo),
                              Expanded(child: _scrollContent()),
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
          ),
        );
      },
    );
  }

  // ───────── TILES ─────────

  Widget _panelInfoTile() {
    return _tileWrapper(
      title: StringConstants.panelInfo,
      children: [
        _textField(
          StringConstants.panelNo,
          controller.config.panelIdController,
          isNumeric: true,
          maxLength: 2,
        ),
        _textField(
          StringConstants.panelName,
          controller.config.panelNameController,
          maxLength: 21,
        ),
      ],
    );
  }

  /// Clock fields are still edited and applied here; bulk Config Log compare omits
  /// them so routine time drift does not mark Panel Info as mismatched.
  Widget _dateTimeTile() {
    return _tileWrapper(
      title: StringConstants.dateTime,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                StringConstants.useMobileDateTime,
                style: StyleConstants.black16w600Style,
              ),
            ),
            Switch(
              value: controller.useMobileTime,
              onChanged: controller.toggleMobileTime,
            ),
          ],
        ),
        _numberField(
          StringConstants.year,
          controller.config.yearController,
          maxLength: 4,
        ),
        _numberField(
          StringConstants.month,
          controller.config.monthController,
          maxLength: 2,
        ),
        _numberField(
          StringConstants.day,
          controller.config.dayController,
          maxLength: 2,
        ),
        _numberField(
          StringConstants.hour,
          controller.config.hourController,
          maxLength: 2,
        ),
        _numberField(
          StringConstants.minute,
          controller.config.minuteController,
          maxLength: 2,
        ),
        _numberField(
          StringConstants.second,
          controller.config.secondController,
          maxLength: 2,
        ),
      ],
    );
  }

  Widget _eventReminderTile() {
    return _tileWrapper(
      title: StringConstants.eventReminder,
      children: [
        _numberField(
          StringConstants.delayS,
          controller.config.delayController,
          maxLength: 3,
        ),
      ],
    );
  }

  // ───────── TILE WRAPPER ─────────

  Widget _tileWrapper({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorConstants.borderMuted),
        ),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: ColorConstants.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedTileCount += expanded ? 1 : -1;
              });
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(title, style: StyleConstants.textDark15w600Style),
            children: [...children, const SizedBox(height: 14)],
          ),
        ),
      ),
    );
  }

  // ───────── INPUTS ─────────

  Widget _textField(
    String label,
    TextEditingController fieldController, {
    bool isNumeric = false,
    int? maxLength,
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
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLength: maxLength,
            buildCounter:
                maxLength == null
                    ? null
                    : (
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
                            color:
                                currentLength == max
                                    ? ColorConstants.primary
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            inputFormatters: [
              if (isNumeric) FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController fieldController, {
    int? maxLength,
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => controller.onFieldChanged(),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: StyleConstants.black13w600Style);
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
          style: StyleConstants.white14w600Style,
        ),
      ),
    );
  }
}
