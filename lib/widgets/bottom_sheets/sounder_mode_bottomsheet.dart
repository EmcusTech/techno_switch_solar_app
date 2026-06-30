import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/sounder_mode_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SounderModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const SounderModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<SounderModeBottomSheet> createState() => SounderModeBottomSheetState();
}

class SounderModeBottomSheetState extends State<SounderModeBottomSheet>
    with SingleTickerProviderStateMixin {
  late final SounderModeController controller;

  late TabController _tabController;
  final ScrollController sounderBottomSheetController = ScrollController();
  late final List<GlobalKey> _tileKeys;

  final FocusNode delayFocusNode = FocusNode();

  final String _delayError = StringConstants.delayMustBeBetween0And600Seconds;

  @override
  void initState() {
    super.initState();

    _tileKeys = List.generate(3, (_) => GlobalKey());

    delayFocusNode.addListener(() {
      if (delayFocusNode.hasFocus) {
        debugPrint(StringConstants.delayFieldIsFocused);
      } else {
        debugPrint(StringConstants.delayFieldLostFocus);
      }
    });

    _tabController = TabController(length: 4, vsync: this);

    controller = Get.put(
      SounderModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    sounderBottomSheetController.dispose();
    delayFocusNode.dispose();
    Get.delete<SounderModeController>();
    super.dispose();
  }

  /// Kept for the create-project wizard, which commits each embedded sheet via
  /// its `GlobalKey`.
  Future<bool> commitLocal() => controller.commitLocal();

  Widget _mainScrollBody() {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: sounderBottomSheetController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (widget.embedInCreateFlow)
              _title(StringConstants.sounderModeConfiguration),
            ...List.generate(3, (i) => _sounderTile(i)),
            const SizedBox(height: 24),
            _advancedHeader(),
            _advancedSection(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SounderModeController>(
      init: controller,
      builder: (c) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * 0.75;

        if (widget.embedInCreateFlow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: _mainScrollBody())],
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
                              _title('Sounder Mode'),
                              const SizedBox(height: 12),
                              Expanded(child: _mainScrollBody()),
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

  // ───────────────── SOUNDERS ─────────────────

  Widget _sounderTile(int index) {
    final sounder = controller.sounders[index];

    return Container(
      key: _tileKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _sectionContainer(
          child: ExpansionTile(
            onExpansionChanged: (expanded) async {
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
              'Sounder ${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ColorConstants.textDark,
              ),
            ),
            children: [
              _disabledField('Output', 'SNDR ${index + 1}'),
              _textField(
                label: StringConstants.outputText,
                fieldController: sounder.outputController,
                maxLength: 21,
              ),
              if (!sounder.groupLocked)
                DropdownWidget(
                  label: StringConstants.group,
                  value: sounder.group,
                  items: controller.groupOptions,
                  onChanged: (v) => controller.setSounderGroup(index, v),
                ),
              if (!sounder.functionLocked)
                DropdownWidget(
                  label: 'Function',
                  value: sounder.function,
                  items: controller.functionOptionsMap[sounder.group]!,
                  onChanged: (v) => controller.setSounderFunction(index, v),
                ),
              if (sounder.group == StringConstants.zone)
                _textField(
                  label: StringConstants.zone,
                  fieldController: sounder.dynamicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                ),
              if (sounder.group == StringConstants.extOut)
                _textField(
                  label: StringConstants.extOut,
                  fieldController: sounder.dynamicController,
                  enabled: false,
                ),
              if (sounder.group != StringConstants.extOut)
                DropdownWidget(
                  label: StringConstants.enabled,
                  value: sounder.enabled,
                  items: controller.yesNoOptions,
                  onChanged: (v) => controller.setSounderEnabled(index, v),
                ),
              DropdownWidget(
                label: StringConstants.type,
                value: sounder.type,
                items: controller.typeOptions,
                onChanged: (v) => controller.setSounderType(index, v),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── ADVANCED ─────────────────

  Widget _advancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text(
          StringConstants.advancedConfiguration,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ColorConstants.textDark,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _advancedSection() {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: ColorConstants.surfaceLight,
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.5, color: ColorConstants.primary),
            ),
            labelColor: ColorConstants.primary,
            unselectedLabelColor: ColorConstants.textSubtle,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'General'),
              Tab(text: StringConstants.zone),
              Tab(text: StringConstants.extOut2),
              Tab(text: 'Delay'),
            ],
            onTap: (_) {
              sounderBottomSheetController.animateTo(
                sounderBottomSheetController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabController,
            children: [_generalTab(), _zoneTab(), _extOutTab(), _delayTab()],
          ),
        ),
      ],
    );
  }

  Widget _generalTab() {
    final manager = controller.manager!;
    return Column(
      children: [
        _disabledField('Function', StringConstants.fireSnd),
        DropdownWidget(
          label: StringConstants.enabled,
          value: controller.yesNoOptions[manager.isSounderGeneralEnabled.value ? 1 : 0],
          items: controller.yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: StringConstants.test,
          value: controller.yesNoOptions[manager.isSounderGeneralTest.value ? 1 : 0],
          items: controller.yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: StringConstants.action,
          value: controller.actionOptions[manager.sounderGeneralAction.value],
          items: controller.actionOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _zoneTile(int index) {
    final zone = controller.zones[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Zone ${index + 1}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          children: [
            _disabledField('Function', StringConstants.fireSnd),
            _disabledField(StringConstants.zone, '${index + 1}'),
            DropdownWidget(
              label: StringConstants.enabled,
              value: zone.enabled,
              items: controller.yesNoOptions,
              onChanged: (v) => controller.setZoneEnabled(index, v),
            ),
            DropdownWidget(
              label: StringConstants.test,
              value: zone.test,
              items: controller.yesNoOptions,
              onChanged: (v) => controller.setZoneTest(index, v),
            ),
            DropdownWidget(
              label: StringConstants.action,
              value: zone.action,
              items: controller.actionOptions,
              onChanged: (v) => controller.setZoneAction(index, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneTab() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (_, i) {
        return _zoneTile(i);
      },
    );
  }

  Widget _extOutTile(int index) {
    final extOut = controller.extOuts[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            controller.functions[index],
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          children: [
            _disabledField('Function', controller.functions[index]),
            DropdownWidget(
              label: StringConstants.enabled,
              value: extOut.enabled,
              items: controller.yesNoOptions,
              onChanged: (v) => controller.setExtEnabled(index, v),
            ),
            DropdownWidget(
              label: StringConstants.test,
              value: extOut.test,
              items: controller.yesNoOptions,
              onChanged: (v) => controller.setExtTest(index, v),
            ),
            DropdownWidget(
              label: 'Countdown',
              value: extOut.countdownAction,
              items: controller.extOutActionOptions,
              onChanged: (v) => controller.setExtCountdown(index, v),
            ),
            DropdownWidget(
              label: 'Hold',
              value: extOut.holdAction,
              items: controller.extOutActionOptions,
              onChanged: (v) => controller.setExtHold(index, v),
            ),
            DropdownWidget(
              label: 'Release',
              value: extOut.releaseAction,
              items: controller.extOutActionOptions,
              onChanged: (v) => controller.setExtRelease(index, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _extOutTab() {
    return ListView.builder(
      itemCount: controller.functions.length,
      itemBuilder: (_, i) {
        return _extOutTile(i);
      },
    );
  }

  Widget _delayTab() {
    final manager = controller.manager!;
    return Column(
      children: [
        _textField(
          label: StringConstants.delayS,
          fieldController: controller.delayController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: _inputDecoration(),
          focusNode: delayFocusNode,
        ),
        if (delayFocusNode.hasFocus)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _delayError,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 14),
        DropdownWidget(
          label: StringConstants.delayed,
          value: controller.yesNoOptions[manager.isSounderGeneralDelay.value ? 1 : 0],
          items: controller.yesNoOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  // ───────────────── UI HELPERS ─────────────────

  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.borderMuted),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: ColorConstants.transparent,
        ),
        child: child,
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

  Widget _disabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            enabled: false,
            controller: TextEditingController(text: value),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController fieldController,
    bool enabled = true,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    InputDecoration? decoration,
    Function(String)? onChanged,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: fieldController,
            focusNode: focusNode,
            enabled: enabled,
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                currentLength == max
                                    ? ColorConstants.primary
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            keyboardType: keyboardType,
            inputFormatters: [
              ...?inputFormatters,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            decoration: decoration ?? _inputDecoration(),
            onChanged: onChanged,
          ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: ColorConstants.primary, width: 2),
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

  Widget _applyButton() {
    final isDelayValid = controller.computeIsValid();
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
            controller.manager != null && isDelayValid
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
