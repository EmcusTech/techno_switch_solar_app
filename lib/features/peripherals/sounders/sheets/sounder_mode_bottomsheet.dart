import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/peripherals/sounders/controllers/sounder_mode_controller.dart';
import 'package:Technoswitch/features/peripherals/sounders/sheets/sounder_advanced_panel.dart';
import 'package:Technoswitch/features/peripherals/sounders/sheets/sounder_tab_slot.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
import 'package:Technoswitch/widgets/common/peripheral_tab_bar.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';

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
    with TickerProviderStateMixin {
  late final SounderModeController controller;

  late TabController _tabController;
  TabController? _sounderTabController;
  final ScrollController sounderBottomSheetController = ScrollController();
  late final List<GlobalKey> _tileKeys;

  final FocusNode delayFocusNode = FocusNode();
  bool _scrollAfterAdvancedTap = false;
  int _sounderTabIndex = 0;
  int? _zoneSounderIndex;

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
    _tabController.addListener(_onAdvancedTabChanged);
    if (PeripheralSheetChrome.flat && !widget.embedInCreateFlow) {
      _sounderTabController = TabController(length: 3, vsync: this);
      _sounderTabController!.addListener(_onSounderTabChanged);
    }

    controller = Get.put(
      SounderModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  void _onAdvancedTabChanged() {
    if (_tabController.indexIsChanging) return;
    final scrollDown = _scrollAfterAdvancedTap;
    _scrollAfterAdvancedTap = false;
    setState(() {});
    if (scrollDown) _scrollSounderSheetToEnd();
  }

  void _onAdvancedTabTapped(int _) {
    if (_tabController.indexIsChanging) {
      _scrollAfterAdvancedTap = true;
      return;
    }
    _scrollSounderSheetToEnd();
  }

  void _scrollSounderSheetToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scroll = sounderBottomSheetController;
      if (!mounted || !scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSounderTabChanged() {
    final tabs = _sounderTabController;
    if (tabs == null) return;
    if (_sounderTabIndex != tabs.index) {
      setState(() => _sounderTabIndex = tabs.index);
      _focusAdvancedForGroup(controller.sounders[tabs.index].group);
    }
    if (tabs.indexIsChanging) return;
    if (sounderBottomSheetController.hasClients) {
      sounderBottomSheetController.jumpTo(0);
    }
  }

  int _advancedTabForGroup(String group) {
    if (group == StringConstants.zone) return 1;
    if (group == StringConstants.extOut) return 2;
    return 0;
  }

  void _focusAdvancedForGroup(String group) {
    _focusAdvancedTab(_advancedTabForGroup(group));
  }

  void _focusAdvancedTab(int index) {
    if (_tabController.index == index) return;
    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _sounderTabController?.removeListener(_onSounderTabChanged);
    _sounderTabController?.dispose();
    _tabController.removeListener(_onAdvancedTabChanged);
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
            _advancedPanel(),
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
                decoration: BoxDecoration(
                  color: PeripheralSheetChrome.lipColor,
                  borderRadius: PeripheralSheetChrome.topRadius(),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: PeripheralSheetChrome.lipPadding,
                  ),
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
                            left: 24.0,
                            right: 24.0,
                            top: 16.0,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              _dragHandle(),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _title('Sounder Mode'),
                              ),
                              Expanded(
                                child:
                                    PeripheralSheetChrome.flat
                                        ? _windowsSounderBody()
                                        : _mainScrollBody(),
                              ),
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

  Widget _windowsSounderBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeripheralTabBar(
          controller: _sounderTabController!,
          tabs: const [
            Tab(text: 'Sounder 1'),
            Tab(text: 'Sounder 2'),
            Tab(text: 'Sounder 3'),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle) {
                FocusScope.of(context).unfocus();
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: sounderBottomSheetController,
              physics: const ClampingScrollPhysics(),
              padding: peripheralSheetScrollPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SounderTabSlot(
                    controller: _sounderTabController!,
                    count: 3,
                    fitCurrentPage: true,
                    pageBuilder: (index, _) => _sounderFields(index),
                  ),
                  const SizedBox(height: 8),
                  _advancedPanel(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sounderFields(int index) {
    final sounder = controller.sounders[index];
    final zoneGroup = sounder.group == StringConstants.zone;
    final outputText = _textField(
      label: StringConstants.outputText,
      fieldController: sounder.outputController,
      maxLength: 21,
    );
    final group = DropdownWidget(
      label: StringConstants.group,
      value: sounder.group,
      items: controller.groupOptions,
      enabled: !sounder.groupLocked,
      onChanged: (v) {
        if (v == StringConstants.zone) _zoneSounderIndex = index;
        _focusAdvancedForGroup(v);
        controller.setSounderGroup(index, v);
      },
    );
    final function = DropdownWidget(
      label: 'Function',
      value: sounder.function,
      items: controller.functionOptionsMap[sounder.group]!,
      enabled: !sounder.functionLocked,
      onChanged: (v) {
        if (sounder.group == StringConstants.extOut) {
          _focusAdvancedTab(2);
        }
        controller.setSounderFunction(index, v);
      },
    );
    final zoneNumber =
        zoneGroup
            ? DropdownWidget(
              label: StringConstants.zone,
              value: sounder.dynamicController.text.trim(),
              items: const ['1', '2', '3'],
              onChanged: (v) {
                _zoneSounderIndex = index;
                _focusAdvancedTab(1);
                sounder.dynamicController.text = v;
              },
            )
            : null;
    final tail = <Widget>[
      DropdownWidget(
        label: StringConstants.enabled,
        value: controller.enabledLabelFor(index),
        items: controller.yesNoOptions,
        enabled: sounder.group != StringConstants.extOut,
        onChanged: (v) => controller.setSounderEnabled(index, v),
      ),
      DropdownWidget(
        label: StringConstants.type,
        value: sounder.type,
        items: controller.typeOptions,
        onChanged: (v) => controller.setSounderType(index, v),
      ),
    ];

    return peripheralSheetFieldGrid([
      outputText,
      group,
      function,
      if (zoneNumber != null) zoneNumber,
      ...tail,
    ]);
  }

  Widget _sounderTile(int index) {
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
              style: StyleConstants.textDark15w600Style,
            ),
            children: [_sounderFields(index), const SizedBox(height: 14)],
          ),
        ),
      ),
    );
  }

  // ───────────────── ADVANCED ─────────────────

  /// View of the shared advanced values for the groups and functions picked
  /// above. Editing happens on the Sounder Advanced tile. The create-project
  /// step still edits here because that flow has no separate tile.
  Widget _advancedPanel() {
    return SounderAdvancedPanel(
      controller: controller,
      tabController: _tabController,
      delayFocusNode: delayFocusNode,
      delayError: _delayError,
      readOnly: !widget.embedInCreateFlow,
      underlineTabs: true,
      zoneSounderIndex:
          _sounderTabController != null ? _sounderTabIndex : _zoneSounderIndex,
      onTabTapped: _onAdvancedTabTapped,
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
        data: Theme.of(
          context,
        ).copyWith(dividerColor: ColorConstants.transparent),
        child: child,
      ),
    );
  }

  Widget _dragHandle() {
    return const PeripheralSheetDragHandle();
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: StyleConstants.textDark14w700Style),
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
                          style: StyleConstants.primary12w400Style.copyWith(
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
    return Text(text, style: StyleConstants.textDark13w600Style);
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;

    return InputDecoration(
      filled: true,
      isDense: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final isDelayValid = controller.computeIsValid();
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }
}
