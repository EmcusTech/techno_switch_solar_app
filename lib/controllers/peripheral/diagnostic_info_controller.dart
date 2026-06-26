import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Controller for the read-only Diagnostic (live ADC) bottom sheet.
///
/// Only loads the cached ADC snapshot into the live `BleProcess` notifiers; the
/// View streams everything reactively via `ValueListenableBuilder`. No edit /
/// validate / push / save path, so those hooks are no-ops.
class DiagnosticInfoController extends PeripheralModeController {
  DiagnosticInfoController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  @override
  void initModel() {}

  @override
  void disposeModel() {}

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadDiagnosticSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    final process = manager!.bleProcess;
    process.sounderOneAdcValue.value =
        (data[StringConstants.sounder1] as num?)?.toDouble() ?? 0;
    process.sounderTwoAdcValue.value =
        (data[StringConstants.sounder2] as num?)?.toDouble() ?? 0;
    process.sounderThreeAdcValue.value =
        (data[StringConstants.sounder3] as num?)?.toDouble() ?? 0;
    process.dischargeAdcValue.value =
        (data['discharge'] as num?)?.toDouble() ?? 0;
    process.vauxAdcValue.value = (data['vaux'] as num?)?.toDouble() ?? 0;
    process.vinAdcValue.value = (data['vin'] as num?)?.toDouble() ?? 0;
    process.progInputAdcValue.value =
        (data[StringConstants.proginput] as num?)?.toDouble() ?? 0;
    process.holdInputAdcValue.value =
        (data['holdInput'] as num?)?.toDouble() ?? 0;
    process.zone1AdcValue.value =
        (data[StringConstants.zone12] as num?)?.toDouble() ?? 0;
    process.zone2AdcValue.value = (data['zone2'] as num?)?.toDouble() ?? 0;
    process.zone3AdcValue.value = (data['zone3'] as num?)?.toDouble() ?? 0;
    process.earthAdcValue.value = (data['earth'] as num?)?.toDouble() ?? 0;
  }

  @override
  void loadFromManager() {}

  @override
  void pushToManager() {}

  @override
  Future<void> save() async {}

  @override
  bool computeIsValid() => true;

  @override
  void updateValidationErrors() {}
}
