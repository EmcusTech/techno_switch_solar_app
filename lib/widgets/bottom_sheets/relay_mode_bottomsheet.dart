import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/relay_mode_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class RelayModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const RelayModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<RelayModeBottomSheet> createState() => RelayModeBottomSheetState();
}

class RelayModeBottomSheetState extends State<RelayModeBottomSheet> {
  late final RelayModeController controller;

  int _expandedTileCount = 0;

  final ScrollController _scrollController = ScrollController();

  late final List<GlobalKey> _tileKeys;

  @override
  void initState() {
    super.initState();
    _tileKeys = List.generate(3, (_) => GlobalKey());
    controller = Get.put(
      RelayModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<RelayModeController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RelayModeController>(
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
                StringConstants.relayModeConfiguration,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textDark,
                ),
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
                      children: List.generate(3, (i) => _relayTile(i)),
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
                            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              _dragHandle(),
                              _title('Relay Mode'),
                              Expanded(
                                child:
                                    NotificationListener<UserScrollNotification>(
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
                                        (i) => _relayTile(i),
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
          ),
        );
      },
    );
  }

  Widget _relayTile(int index) {
    final relay = controller.relays[index];

    return Container(
      color: ColorConstants.white,
      key: _tileKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorConstants.borderMuted),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: ColorConstants.transparent,
            ),
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
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Relay ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textDark,
                ),
              ),
              children: [
                _outputTextField(relay: relay, relayIndex: index),
                DropdownWidget(
                  label: StringConstants.group,
                  value: relay.group,
                  items: controller.groupOptions,
                  onChanged: (v) => controller.setGroup(index, v),
                ),
                DropdownWidget(
                  label: StringConstants.function,
                  value: relay.function,
                  items: controller.functionOptionsMap[relay.group]!,
                  onChanged: (v) => controller.setFunction(index, v),
                ),
                if (relay.group == 'Zone')
                  _zoneDynamicField(relay: relay, relayIndex: index),
                if (relay.group == StringConstants.extOut)
                  _extOutDynamicField(relay: relay),
                DropdownWidget(
                  label: StringConstants.enabled,
                  value: relay.enabled,
                  items: controller.yesNoOptions,
                  onChanged: (v) => controller.setEnabled(index, v),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
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

  Widget _outputTextField({
    required RelayConfig relay,
    required int relayIndex,
  }) {
    final errorMsg = controller.outputTextErrors[relayIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(StringConstants.outputText),
          const SizedBox(height: 6),
          TextField(
            controller: relay.outputTextController,
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorConstants.textDark,
            ),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zoneDynamicField({
    required RelayConfig relay,
    required int relayIndex,
  }) {
    final errorMsg = controller.dynamicFieldErrors[relayIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Zone'),
          const SizedBox(height: 6),
          TextField(
            controller: relay.dynamicController,
            onChanged: (_) => controller.onDynamicFieldChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: _inputDecoration(hasError: errorMsg != null),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _extOutDynamicField({required RelayConfig relay}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(StringConstants.extOut),
          const SizedBox(height: 6),
          TextField(
            controller: relay.dynamicController,
            readOnly: true,
            enabled: false,
            decoration: _inputDecoration(),
          ),
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
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
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
