import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/peripherals/sounders/controllers/sounder_mode_controller.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
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
      _sounderTabIndex = tabs.index;
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
            _advancedHeader(),
            _advancedTabs(),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 420,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.surfaceLight,
            ),
            child: TabBar(
              controller: _sounderTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5,
                  color: ColorConstants.primary,
                ),
              ),
              labelColor: ColorConstants.primary,
              unselectedLabelColor: ColorConstants.textSubtle,
              labelStyle: StyleConstants.black13w600Style,
              unselectedLabelStyle: StyleConstants.black13w500Style,
              tabs: const [
                Tab(text: 'Sounder 1'),
                Tab(text: 'Sounder 2'),
                Tab(text: 'Sounder 3'),
              ],
            ),
          ),
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
                  _SounderTabSlot(
                    controller: _sounderTabController!,
                    count: 3,
                    fitCurrentPage: true,
                    pageBuilder: (index, _) => _sounderFields(index),
                  ),
                  const SizedBox(height: 8),
                  _advancedHeader(),
                  _advancedTabs(),
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
              value:
                  const [
                        '1',
                        '2',
                        '3',
                      ].contains(sounder.dynamicController.text.trim())
                      ? sounder.dynamicController.text.trim()
                      : '1',
              items: const ['1', '2', '3'],
              onChanged: (v) {
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
        onChanged: (v) => controller.setSounderEnabled(index, v),
      ),
      DropdownWidget(
        label: StringConstants.test,
        value: controller.testLabelFor(index),
        items: controller.yesNoOptions,
        onChanged: (v) => controller.setSounderTest(index, v),
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

  Widget _advancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.2),
        Text(
          StringConstants.advancedConfiguration,
          style: StyleConstants.textDark14w700Style,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _advancedTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 480,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.surfaceLight,
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _onAdvancedTabTapped,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5,
                  color: ColorConstants.primary,
                ),
              ),
              labelColor: ColorConstants.primary,
              unselectedLabelColor: ColorConstants.textSubtle,
              labelStyle: StyleConstants.black13w600Style,
              unselectedLabelStyle: StyleConstants.black13w500Style,
              tabs: const [
                Tab(text: 'General'),
                Tab(text: StringConstants.zone),
                Tab(text: StringConstants.extOut2),
                Tab(text: 'Delay'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _advancedTabBody(),
      ],
    );
  }

  Widget _advancedTabBody() {
    if (!PeripheralSheetChrome.flat) {
      final pages = <Widget>[
        _generalAdvancedFields(),
        _zoneAdvancedFields(),
        _extOutAdvancedFields(),
        _delayFields(),
      ];
      return pages[_tabController.index];
    }
    return _SounderTabSlot(
      controller: _tabController,
      count: 4,
      pageBuilder: (index, forMeasure) {
        switch (index) {
          case 1:
            return _zoneAdvancedFields();
          case 2:
            return _extOutAdvancedFields();
          case 3:
            return _delayFields(attachFocus: !forMeasure);
          default:
            return _generalAdvancedFields();
        }
      },
    );
  }

  Widget _generalAdvancedFields() {
    final actionIndex =
        controller.manager?.sounderGeneralAction.value ??
        SounderDefaults.generalActionBle;
    final safeIndex = actionIndex.clamp(0, controller.actionOptions.length - 1);
    return peripheralSheetFieldGrid([
      DropdownWidget(
        label: StringConstants.action,
        value: controller.actionOptions[safeIndex],
        items: controller.actionOptions,
        onChanged: controller.setGeneralAction,
      ),
    ]);
  }

  Widget _zoneAdvancedFields() {
    final numbers = <int>[];
    var invalid = false;
    for (final sounder in controller.sounders) {
      if (sounder.group != StringConstants.zone) continue;
      final number = controller.selectionNumber(sounder);
      if (number == null) {
        invalid = true;
      } else if (!numbers.contains(number)) {
        numbers.add(number);
      }
    }
    if (numbers.isEmpty && !invalid) {
      return Text(
        StringConstants.noZoneSelected,
        style: StyleConstants.textGray14w400Style,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invalid)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              StringConstants.enterZoneNumberFrom1To3,
              style: StyleConstants.textGray14w400Style,
            ),
          ),
        for (final number in numbers)
          peripheralSheetFieldGrid([
            DropdownWidget(
              label: StringConstants.action,
              value: controller.zones[number - 1].action,
              items: controller.actionOptions,
              onChanged: (v) => controller.setZoneAction(number - 1, v),
            ),
          ]),
      ],
    );
  }

  Widget _extOutAdvancedFields() {
    final selected = controller.sounders.any(
      (sounder) => sounder.group == StringConstants.extOut,
    );
    if (!selected) {
      return Text(
        StringConstants.noExtOutSelected,
        style: StyleConstants.textGray14w400Style,
      );
    }
    final extOut = controller.extOuts[0];
    return peripheralSheetFieldGrid([
      DropdownWidget(
        label: 'Countdown',
        value: extOut.countdownAction,
        items: controller.extOutActionOptions,
        dropdownListHeight: 130.h,
        onChanged: (v) => controller.setExtCountdown(0, v),
      ),
      DropdownWidget(
        label: 'Hold',
        value: extOut.holdAction,
        items: controller.extOutActionOptions,
        dropdownListHeight: 130.h,
        onChanged: (v) => controller.setExtHold(0, v),
      ),
      DropdownWidget(
        label: 'Release',
        value: extOut.releaseAction,
        items: controller.extOutActionOptions,
        dropdownListHeight: 80.h,
        onChanged: (v) => controller.setExtRelease(0, v),
      ),
    ]);
  }

  Widget _delayFields({bool attachFocus = true}) {
    final delayedOn =
        controller.manager?.isSounderGeneralDelay.value ??
        controller.delayed == SounderDefaults.delayedLabel;
    return peripheralSheetFieldGrid([
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            focusNode: attachFocus ? delayFocusNode : null,
          ),
          if (delayFocusNode.hasFocus)
            Text(
              _delayError,
              style: StyleConstants.black12w400Style.copyWith(
                color: Colors.orange,
              ),
            ),
        ],
      ),
      DropdownWidget(
        label: StringConstants.delayed,
        value: controller.yesNoOptions[delayedOn ? 1 : 0],
        items: controller.yesNoOptions,
        onChanged: (_) {},
      ),
    ]);
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
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }
}

/// Tab area for a [TabBarView]. By default the area is as tall as the
/// tallest page. With [fitCurrentPage], it follows the open page so the
/// next section starts on the line below.
class _SounderTabSlot extends StatefulWidget {
  const _SounderTabSlot({
    required this.controller,
    required this.count,
    required this.pageBuilder,
    this.fitCurrentPage = false,
  });

  final TabController controller;
  final int count;
  final Widget Function(int index, bool forMeasure) pageBuilder;
  final bool fitCurrentPage;

  @override
  State<_SounderTabSlot> createState() => _SounderTabSlotState();
}

class _SounderTabSlotState extends State<_SounderTabSlot> {
  late List<double> _heights;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _heights = List<double>.filled(widget.count, 0);
    _index = widget.controller.index;
    widget.controller.addListener(_onTab);
  }

  @override
  void didUpdateWidget(covariant _SounderTabSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTab);
      widget.controller.addListener(_onTab);
    }
    if (oldWidget.count != widget.count) {
      _heights = List<double>.filled(widget.count, 0);
    }
    _index = widget.controller.index;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (!widget.fitCurrentPage) return;
    final index = widget.controller.index;
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _report(int index, Size size) {
    if (index < 0 || index >= _heights.length) return;
    if ((size.height - _heights[index]).abs() < 1) return;
    setState(() => _heights[index] = size.height);
  }

  double get _slotHeight {
    if (widget.fitCurrentPage) {
      final index = _index.clamp(0, _heights.length - 1);
      final height = _heights[index];
      return height <= 0 ? 1 : height;
    }
    var maxHeight = 0.0;
    for (final height in _heights) {
      if (height > maxHeight) maxHeight = height;
    }
    return maxHeight <= 0 ? 1 : maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        for (var i = 0; i < widget.count; i++)
          ExcludeFocus(
            child: IgnorePointer(
              child: Offstage(
                child: _TabPageMeasure(
                  onSize: (size) => _report(i, size),
                  child: widget.pageBuilder(i, true),
                ),
              ),
            ),
          ),
        SizedBox(
          height: _slotHeight,
          width: double.infinity,
          child: TabBarView(
            controller: widget.controller,
            children: [
              for (var i = 0; i < widget.count; i++)
                widget.pageBuilder(i, false),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabPageMeasure extends StatefulWidget {
  const _TabPageMeasure({required this.onSize, required this.child});

  final ValueChanged<Size> onSize;
  final Widget child;

  @override
  State<_TabPageMeasure> createState() => _TabPageMeasureState();
}

class _TabPageMeasureState extends State<_TabPageMeasure> {
  final GlobalKey _key = GlobalKey();
  Size? _last;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final size = box.size;
      if (size == _last) return;
      _last = size;
      widget.onSize(size);
    });
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}
