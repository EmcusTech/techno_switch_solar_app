import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/zone_mode_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ZoneBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ZoneBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<ZoneBottomSheet> createState() => ZoneBottomSheetState();
}

class ZoneBottomSheetState extends State<ZoneBottomSheet> {
  late final ZoneModeController controller;

  int _expandedTileCount = 0;

  final ScrollController _scrollController = ScrollController();

  late final List<GlobalKey> _tileKeys;

  @override
  void initState() {
    super.initState();
    _tileKeys = List.generate(3, (_) => GlobalKey());
    controller = Get.put(
      ZoneModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<ZoneModeController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ZoneModeController>(
      init: controller,
      builder: (c) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight =
            _expandedTileCount > 0 ? screenHeight * 0.8 : screenHeight * 0.5;
        c.updateValidationErrors();
        final isValid = c.computeIsValid();

        if (widget.embedInCreateFlow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                StringConstants.zoneConfiguration,
                style: StyleConstants.textDark20w700Style,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction != ScrollDirection.idle) {
                      FocusScope.of(context).unfocus();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: List.generate(3, (i) => _zoneTile(i)),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

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
                            left: 24.0,
                            right: 24.0,
                            top: 16.0,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              _dragHandle(),
                              _title(StringConstants.zoneMode),
                              Expanded(
                                child: NotificationListener<
                                  UserScrollNotification
                                >(
                                  onNotification: (notification) {
                                    if (notification.direction !=
                                        ScrollDirection.idle) {
                                      FocusScope.of(context).unfocus();
                                    }
                                    return false;
                                  },
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Column(
                                      children: List.generate(
                                        3,
                                        (i) => _zoneTile(i),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _downloadButton()),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _applyButton(isValid: isValid),
                                  ),
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

  // ───────────────── ZONE TILE ─────────────────

  Widget _zoneTile(int index) {
    final zone = controller.zones[index];

    return Container(
      key: _tileKeys[index],
      child: Padding(
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
              onExpansionChanged: (expanded) async {
                setState(() {
                  _expandedTileCount += expanded ? 1 : -1;
                });

                if (expanded) {
                  await Future.delayed(const Duration(milliseconds: 250));

                  final context = _tileKeys[index].currentContext;

                  if (context != null && context.mounted) {
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                }
              },
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Zone ${zone.zoneNumber}',
                style: StyleConstants.textDark15w600Style,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      _zoneTextField(zone: zone, zoneIndex: index),
                      DropdownWidget(
                        label: StringConstants.type,
                        value: zone.type,
                        items: controller.typeOptions,
                        onChanged: (v) => controller.setType(index, v),
                      ),
                      DropdownWidget(
                        label: StringConstants.enabled,
                        value: zone.enabled,
                        items: controller.yesNoOptions,
                        onChanged: (v) => controller.setEnabled(index, v),
                      ),
                      DropdownWidget(
                        label: StringConstants.mode,
                        value: zone.mode,
                        items: controller.modeOptions,
                        onChanged: (v) => controller.setMode(index, v),
                      ),
                      _verificationTimeField(zone: zone, zoneIndex: index),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── ZONE TEXT & VERIFICATION FIELDS ─────────────────

  Widget _zoneTextField({required ZoneConfig zone, required int zoneIndex}) {
    final errorMsg = controller.zoneTextErrors[zoneIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(StringConstants.zoneText),
          const SizedBox(height: 6),
          TextField(
            controller: zone.zoneTextController,
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
            decoration: _inputDecoration(hasError: errorMsg != null),
            style: StyleConstants.textDark14w500Style,
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(errorMsg, style: StyleConstants.primary12w500Style),
          ],
        ],
      ),
    );
  }

  Widget _verificationTimeField({
    required ZoneConfig zone,
    required int zoneIndex,
  }) {
    final isReadOnly =
        zone.mode == StringConstants.normal ||
        zone.mode == StringConstants.none ||
        zone.mode == StringConstants.immediate;
    final errorMsg = controller.verificationErrors[zoneIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(StringConstants.verificationTimeS),
          const SizedBox(height: 6),
          TextField(
            controller: zone.verificationTimeController,
            readOnly: isReadOnly,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => controller.onVerificationTimeChanged(),
            decoration: _inputDecoration(hasError: errorMsg != null),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(errorMsg, style: StyleConstants.primary12w500Style),
          ],
        ],
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

  // ───────────────── UI HELPERS ─────────────────

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
}
