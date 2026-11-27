import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/peripherals/defaults/sounder_defaults.dart';

/// Which shared slot a group and function own.
enum SndrRelayPatternKind { none, general, zone, extOut }

/// The four bytes of firmware `st_sndr_relay_pattern_cfg_def`.
class SndrRelayPatternBytes {
  const SndrRelayPatternBytes({
    this.action = 0,
    this.countdown = 0,
    this.hold = 0,
    this.release = 0,
  });

  final int action;
  final int countdown;
  final int hold;
  final int release;
}

/// Shared pattern for sounders and relays.
///
/// General + Fire Snd copies the general action. Zone + Fire Snd copies the
/// one zone action. Ext Out copies countdown, hold, and release for Ext. Snd 1,
/// Ext. Snd 2, or Man. Release Snd. Every other group and function is empty
/// and does not change the stored pattern.
abstract final class SndrRelayPattern {
  static const int groupGeneral = 1;
  static const int groupZone = 2;
  static const int groupExtOut = 3;

  static String functionLabel({
    required int group,
    required int function,
    required List<String> groups,
    required Map<String, List<String>> functionsByGroup,
  }) {
    if (group < 0 || group >= groups.length) return '';
    final options = functionsByGroup[groups[group]];
    if (options == null || function < 0 || function >= options.length) {
      return '';
    }
    return options[function];
  }

  static SndrRelayPatternKind kindFor(int group, String function) {
    if (_isGeneralFire(group, function)) return SndrRelayPatternKind.general;
    if (_isZoneFire(group, function)) return SndrRelayPatternKind.zone;
    if (group == groupExtOut && _extIndex(function) != null) {
      return SndrRelayPatternKind.extOut;
    }
    return SndrRelayPatternKind.none;
  }

  /// Ext. Snd 1, Ext. Snd 2, and Man. Release Snd are 0, 1, and 2.
  static int? extIndex(String function) => _extIndex(function);

  static SndrRelayPatternBytes fromProcess({
    required BleProcess process,
    required int group,
    required String function,
  }) {
    if (_isGeneralFire(group, function)) {
      return SndrRelayPatternBytes(action: process.sounderGeneralAction.value);
    }
    if (_isZoneFire(group, function)) {
      return SndrRelayPatternBytes(action: _zoneAction(process));
    }
    final ext = _extIndex(function);
    if (group == groupExtOut && ext != null) {
      final actions = _extActions(process, ext);
      return SndrRelayPatternBytes(
        countdown: actions.$1,
        hold: actions.$2,
        release: actions.$3,
      );
    }
    return const SndrRelayPatternBytes();
  }

  /// Writes [action], [countdown], [hold], and [release] into the slot owned
  /// by [group] and [function]. Other functions leave the stored pattern as it is.
  static void applyToProcess(
    BleProcess process, {
    required int group,
    required String function,
    required int action,
    required int countdown,
    required int hold,
    required int release,
  }) {
    if (_isGeneralFire(group, function)) {
      process.sounderGeneralAction.value = action;
      return;
    }
    if (_isZoneFire(group, function)) {
      _setZone(process, action);
      return;
    }
    final ext = _extIndex(function);
    if (group == groupExtOut && ext != null) {
      _setExt(process, ext, countdown: countdown, hold: hold, release: release);
    }
  }

  static bool _isGeneralFire(int group, String function) {
    return group == groupGeneral && function == StringConstants.fireSnd;
  }

  static bool _isZoneFire(int group, String function) {
    return group == groupZone && function == StringConstants.fireSnd;
  }

  static int? _extIndex(String function) {
    if (function == StringConstants.extSnd1) return 0;
    if (function == SounderDefaults.functionExtSnd2Label) return 1;
    if (function == StringConstants.manReleaseSnd) return 2;
    return null;
  }

  static (int, int, int) _extActions(BleProcess process, int function) {
    return switch (function) {
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
      2 => (
        process.extoutThreeCountdownAction.value,
        process.extoutThreeHoldAction.value,
        process.extoutThreeReleaseAction.value,
      ),
      _ => (0, 0, 0),
    };
  }

  static void _setExt(
    BleProcess process,
    int function, {
    required int countdown,
    required int hold,
    required int release,
  }) {
    switch (function) {
      case 0:
        process.extoutOneCountdownAction.value = countdown;
        process.extoutOneHoldAction.value = hold;
        process.extoutOneReleaseAction.value = release;
      case 1:
        process.extoutTwoCountdownAction.value = countdown;
        process.extoutTwoHoldAction.value = hold;
        process.extoutTwoReleaseAction.value = release;
      case 2:
        process.extoutThreeCountdownAction.value = countdown;
        process.extoutThreeHoldAction.value = hold;
        process.extoutThreeReleaseAction.value = release;
    }
  }

  static int _zoneAction(BleProcess process) => process.zoneOneAction.value;

  static void _setZone(BleProcess process, int action) {
    process.zoneOneAction.value = action;
    process.zoneTwoAction.value = action;
    process.zoneThreeAction.value = action;
  }
}
