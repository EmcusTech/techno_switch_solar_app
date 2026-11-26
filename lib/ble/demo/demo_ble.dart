import 'package:flutter/foundation.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

/// Demo stand-in for the radio. Set [enabled] to false to use a real panel.
abstract final class DemoBle {
  static const bool enabled = true;

  /// When true, the event log table shows the hex event id instead of the read order.
  static const bool devMode = false;

  /// When true, relay, input, and zone dropdowns keep only the demo choices selectable.
  static const bool restrictPeripheralOptions = false;

  /// Access code accepted by the demo validator.
  static const String accessCode = '1974';

  /// Firmware version reported by a demo panel that has not been upgraded yet.
  static const String firmwareVersion = '1.0.0';

  /// Steps in a demo firmware transfer. At [fastStepDelay] this finishes in about three seconds.
  static const int firmwareUpgradeSteps = 20;

  static const Duration stepDelay = Duration(milliseconds: 200);

  /// Short enough that a 31-step count still finishes in about two seconds.
  static const Duration fastStepDelay = Duration(milliseconds: 150);

  static Future<void> runSteppedCommand({
    required BleProcess process,
    required List<String> steps,
    required ValueNotifier<bool> done,
    Duration? stepDelay,
  }) async {
    final delay = stepDelay ?? DemoBle.stepDelay;
    for (final step in steps) {
      process.processDesc.value = step;
      await Future.delayed(delay);
    }
    done.value = true;
  }

  /// Steps the progress text, then marks the password-popup command finished.
  static Future<void> runPasswordCommand({
    required BleProcess process,
    required List<String> steps,
    required void Function() finish,
    Duration? stepDelay,
  }) async {
    final delay = stepDelay ?? DemoBle.stepDelay;
    for (final step in steps) {
      process.processDesc.value = step;
      await Future.delayed(delay);
    }
    finish();
  }

  /// Walks a firmware transfer without sending packets to the panel.
  static Future<void> runFirmwareUpgrade({
    required BleProcess process,
    required void Function(int sent, int total) onProgress,
  }) async {
    const int steps = firmwareUpgradeSteps;
    process.processDesc.value = StringConstants.preparingFirmwareUpgrade;
    onProgress(0, steps);
    for (var sent = 1; sent <= steps; sent++) {
      await Future.delayed(fastStepDelay);
      process.processDesc.value =
          '${StringConstants.pleaseWaitWhileFirmwareUpgraded} $sent/$steps';
      onProgress(sent, steps);
    }
  }
}
