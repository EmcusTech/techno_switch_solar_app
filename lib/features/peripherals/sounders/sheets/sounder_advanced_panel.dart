import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:Technoswitch/features/peripherals/sounders/controllers/sounder_mode_controller.dart';
import 'package:Technoswitch/features/peripherals/sounders/sheets/sounder_tab_slot.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';
import 'package:Technoswitch/widgets/common/peripheral_tab_bar.dart';

/// Shared General / Zone / Ext Out / Delay fields.
///
/// [readOnly] is the sounder sheet's view of the pick. [extFunctionTabs]
/// is the editor: Ext Out has one tab per function, each with its own
/// countdown, hold, and release.
class SounderAdvancedPanel extends StatefulWidget {
  const SounderAdvancedPanel({
    super.key,
    required this.controller,
    required this.tabController,
    required this.delayFocusNode,
    required this.delayError,
    this.readOnly = false,
    this.extFunctionTabs = false,
    this.underlineTabs = false,
    this.showHeader = true,
    this.onTabTapped,
  });

  final SounderModeController controller;
  final TabController tabController;
  final FocusNode delayFocusNode;
  final String delayError;
  final bool readOnly;
  final bool extFunctionTabs;

  /// Underline bar for General / Zone / Ext Out / Delay. Ext Out function
  /// tabs stay on the card style.
  final bool underlineTabs;

  final bool showHeader;
  final ValueChanged<int>? onTabTapped;

  @override
  State<SounderAdvancedPanel> createState() => _SounderAdvancedPanelState();
}

class _SounderAdvancedPanelState extends State<SounderAdvancedPanel>
    with SingleTickerProviderStateMixin {
  TabController? _extTabs;
  int _extIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.delayFocusNode.addListener(_onDelayFocus);
    if (widget.extFunctionTabs) {
      _extTabs = TabController(
        length: widget.controller.functions.length,
        vsync: this,
      );
      _extTabs!.addListener(_onExtTab);
    }
  }

  @override
  void dispose() {
    widget.delayFocusNode.removeListener(_onDelayFocus);
    _extTabs?.removeListener(_onExtTab);
    _extTabs?.dispose();
    super.dispose();
  }

  void _onDelayFocus() {
    if (mounted) setState(() {});
  }

  void _onExtTab() {
    final tabs = _extTabs;
    if (tabs == null || tabs.index == _extIndex) return;
    setState(() => _extIndex = tabs.index);
  }

  bool get _enabled => !widget.readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [if (widget.showHeader) _header(), _tabs()],
    );
  }

  Widget _header() {
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

  Widget _tabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PeripheralTabBar(
          controller: widget.tabController,
          onTap: widget.onTabTapped,
          underline: widget.underlineTabs,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: StringConstants.zone),
            Tab(text: StringConstants.extOut2),
            Tab(text: 'Delay'),
          ],
        ),
        const SizedBox(height: 20),
        _tabBody(),
      ],
    );
  }

  Widget _page(int index, {required bool attachDelayFocus}) {
    switch (index) {
      case 1:
        return _zoneFields();
      case 2:
        return _extOutFields();
      case 3:
        return _delayFields(attachFocus: attachDelayFocus);
      default:
        return _generalFields();
    }
  }

  Widget _tabBody() {
    if (!PeripheralSheetChrome.flat) {
      return _page(widget.tabController.index, attachDelayFocus: true);
    }
    return SounderTabSlot(
      controller: widget.tabController,
      count: 4,
      fitCurrentPage: true,
      pageBuilder:
          (index, forMeasure) => _page(index, attachDelayFocus: !forMeasure),
    );
  }

  Widget _generalFields() {
    final actionIndex =
        widget.controller.manager?.sounderGeneralAction.value ??
        SounderDefaults.generalActionBle;
    final safeIndex = actionIndex.clamp(
      0,
      widget.controller.actionOptions.length - 1,
    );
    return peripheralSheetFieldGrid([
      DropdownWidget(
        label: StringConstants.action,
        value: widget.controller.actionOptions[safeIndex],
        items: widget.controller.actionOptions,
        enabled: _enabled,
        dropdownListHeight: 80.h,
        onChanged: widget.controller.setGeneralAction,
      ),
    ]);
  }

  Widget _zoneFields() {
    return peripheralSheetFieldGrid([
      DropdownWidget(
        label: StringConstants.action,
        value: widget.controller.zones.first.action,
        items: widget.controller.actionOptions,
        enabled: _enabled,
        dropdownListHeight: 80.h,
        onChanged: widget.controller.setZoneAction,
      ),
    ]);
  }

  Widget _extOutFields() {
    final tabs = _extTabs;
    if (widget.extFunctionTabs && tabs != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PeripheralTabBar(
            controller: tabs,
            tabs: [
              for (final name in widget.controller.functions) Tab(text: name),
            ],
          ),
          const SizedBox(height: 16),
          _extFunctionFields(_extIndex),
        ],
      );
    }

    final indexes = <int>[];
    for (final sounder in widget.controller.sounders) {
      if (sounder.group != StringConstants.extOut) continue;
      final index = widget.controller.functions.indexOf(sounder.function);
      if (index < 0 || indexes.contains(index)) continue;
      indexes.add(index);
    }
    if (indexes.isEmpty) {
      return Text(
        StringConstants.noExtOutSelected,
        style: StyleConstants.textGray14w400Style,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < indexes.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Text(
            widget.controller.functions[indexes[i]],
            style: StyleConstants.textDark14w700Style,
          ),
          const SizedBox(height: 12),
          _extFunctionFields(indexes[i]),
        ],
      ],
    );
  }

  Widget _extFunctionFields(int index) {
    final extOut = widget.controller.extOuts[index];
    return peripheralSheetFieldGrid([
      DropdownWidget(
        label: 'Countdown',
        value: extOut.countdownAction,
        items: widget.controller.extOutActionOptions,
        enabled: _enabled,
        dropdownListHeight: 130.h,
        onChanged: (v) => widget.controller.setExtCountdown(index, v),
      ),
      DropdownWidget(
        label: 'Hold',
        value: extOut.holdAction,
        items: widget.controller.extOutActionOptions,
        enabled: _enabled,
        dropdownListHeight: 130.h,
        onChanged: (v) => widget.controller.setExtHold(index, v),
      ),
      DropdownWidget(
        label: 'Release',
        value: extOut.releaseAction,
        items: widget.controller.extOutActionOptions,
        enabled: _enabled,
        dropdownListHeight: 80.h,
        onChanged: (v) => widget.controller.setExtRelease(index, v),
      ),
    ]);
  }

  Widget _delayFields({required bool attachFocus}) {
    final delayedOn =
        widget.controller.manager?.isSounderGeneralDelay.value ??
        widget.controller.delayed == SounderDefaults.delayedLabel;
    return peripheralSheetFieldGrid([
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _delayTextField(attachFocus: attachFocus && _enabled),
          if (_enabled && widget.delayFocusNode.hasFocus)
            Text(
              widget.delayError,
              style: StyleConstants.black12w400Style.copyWith(
                color: Colors.orange,
              ),
            ),
        ],
      ),
      DropdownWidget(
        label: StringConstants.delayed,
        value: widget.controller.yesNoOptions[delayedOn ? 1 : 0],
        items: widget.controller.yesNoOptions,
        enabled: _enabled,
        dropdownListHeight: 80.h,
        onChanged: (_) {},
      ),
    ]);
  }

  Widget _delayTextField({required bool attachFocus}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.delayS,
            style: StyleConstants.textDark13w600Style,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller.delayController,
            focusNode: attachFocus ? widget.delayFocusNode : null,
            enabled: _enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      isDense: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }
}
