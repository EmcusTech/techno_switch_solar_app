import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_manager.dart';
import 'package:Technoswitch/config/ble/sndr_relay_pattern.dart';
import 'package:Technoswitch/config/ui/relay_config_options.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

/// Disabled view of the shared pattern for one relay.
///
/// Shown when the relay's group and function own a pattern slot. Editing
/// stays on the Sounder Advanced tile.
class RelayPatternFields extends StatelessWidget {
  const RelayPatternFields({
    super.key,
    required this.group,
    required this.function,
    required this.zoneText,
    required this.manager,
  });

  final String group;
  final String function;
  final String zoneText;
  final BleManager? manager;

  static const List<String> _actionOptions = [
    SounderDefaults.actionContinuousLabel,
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
  ];

  static const List<String> _extOutActionOptions = [
    SounderDefaults.actionContinuousLabel,
    StringConstants.pulsing1sOn1sOff,
    StringConstants.pulsing1sOn4sOff,
    StringConstants.pulsing2sOn500msOff,
    StringConstants.off,
  ];

  @override
  Widget build(BuildContext context) {
    final kind = SndrRelayPattern.kindFor(
      RelayConfigOptions.groupIndex(group),
      function,
    );
    if (kind == SndrRelayPatternKind.none) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(thickness: 1.2),
        Text(
          StringConstants.advancedConfiguration,
          style: StyleConstants.textDark14w700Style,
        ),
        const SizedBox(height: 12),
        _fields(kind),
      ],
    );
  }

  Widget _fields(SndrRelayPatternKind kind) {
    switch (kind) {
      case SndrRelayPatternKind.general:
        return _actionDropdown(_generalAction());
      case SndrRelayPatternKind.zone:
        return _zoneFields();
      case SndrRelayPatternKind.extOut:
        return _extFields();
      case SndrRelayPatternKind.none:
        return const SizedBox.shrink();
    }
  }

  Widget _zoneFields() {
    final number = int.tryParse(zoneText.trim());
    if (number == null || number < 1 || number > 3) {
      return Text(
        zoneText.trim().isEmpty
            ? StringConstants.noZoneSelected
            : StringConstants.enterZoneNumberFrom1To3,
        style: StyleConstants.textGray14w400Style,
      );
    }
    return _actionDropdown(_zoneAction(number));
  }

  Widget _extFields() {
    final index = SndrRelayPattern.extIndex(function) ?? 0;
    final values = _extActions(index);
    return peripheralSheetFieldGrid([
      _choice(
        label: 'Countdown',
        value: _label(_extOutActionOptions, values.$1),
        items: _extOutActionOptions,
      ),
      _choice(
        label: 'Hold',
        value: _label(_extOutActionOptions, values.$2),
        items: _extOutActionOptions,
      ),
      _choice(
        label: 'Release',
        value: _label(_extOutActionOptions, values.$3),
        items: _extOutActionOptions,
      ),
    ]);
  }

  Widget _actionDropdown(int action) {
    return peripheralSheetFieldGrid([
      _choice(
        label: StringConstants.action,
        value: _label(_actionOptions, action),
        items: _actionOptions,
      ),
    ]);
  }

  Widget _choice({
    required String label,
    required String value,
    required List<String> items,
  }) {
    return DropdownWidget(
      label: label,
      value: value,
      items: items,
      enabled: false,
      onChanged: (_) {},
    );
  }

  int _generalAction() {
    return manager?.sounderGeneralAction.value ??
        SounderDefaults.generalActionBle;
  }

  int _zoneAction(int zone) {
    final process = manager?.bleProcess;
    if (process == null) return SounderDefaults.generalActionBle;
    return switch (zone) {
      1 => process.zoneOneAction.value,
      2 => process.zoneTwoAction.value,
      3 => process.zoneThreeAction.value,
      _ => 0,
    };
  }

  (int, int, int) _extActions(int index) {
    final process = manager?.bleProcess;
    if (process == null) {
      return (
        SounderDefaults.countdownActionBle,
        SounderDefaults.holdActionBle,
        SounderDefaults.releaseActionBle,
      );
    }
    return switch (index) {
      0 => (
        process.extoutOneCountdownAction.value,
        process.extoutOneHoldAction.value,
        process.extoutOneReleaseAction.value,
      ),
      1 => (
        process.extoutTwoCountdownAction.value,
        process.extoutTwoHoldAction.value,
        process.extoutTwoReleaseAction.value,
      ),
      _ => (
        process.extoutThreeCountdownAction.value,
        process.extoutThreeHoldAction.value,
        process.extoutThreeReleaseAction.value,
      ),
    };
  }

  String _label(List<String> options, int index) {
    if (options.isEmpty) return '';
    return options[index.clamp(0, options.length - 1)];
  }
}
