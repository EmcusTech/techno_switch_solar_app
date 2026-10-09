import 'package:flutter/foundation.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/ble/blue_plus_adapter.dart';

/// Demo stand-in for the radio. Set [enabled] to false to use a real panel.
abstract final class DemoBle {
  static const bool enabled = false;

  /// When true, relay, input, and zone dropdowns keep only the demo choices selectable.
  static const bool restrictPeripheralOptions = false;

  /// Access code accepted by the demo validator.
  static const String accessCode = '1974';

  static const Duration stepDelay = Duration(milliseconds: 200);

  /// Short enough that a 31-step count still finishes in about two seconds.
  static const Duration fastStepDelay = Duration(milliseconds: 150);

  static List<DiscoveredDevice> scanDevices() {
    return [
      DiscoveredDevice(
        id: 'demo-panel-1',
        name: 'TECHNOSWITCH_11873122',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -46,
        serviceUuids: const <Uuid>[],
      ),
      DiscoveredDevice(
        id: 'demo-panel-2',
        name: 'TECHNOSWITCH_73823341',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -68,
        serviceUuids: const <Uuid>[],
      ),
    ];
  }

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
}
