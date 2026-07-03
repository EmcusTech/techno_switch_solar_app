import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Controller for the read-only Module Info bottom sheet.
///
/// The sheet only loads the cached module snapshot into the live manager
/// notifiers and displays them via `ValueListenableBuilder`. There is no edit,
/// validate, push or save path, so those hooks are no-ops.
class ModuleInfoController extends PeripheralModeController {
  ModuleInfoController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  @override
  void initModel() {}

  @override
  void disposeModel() {}

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadModuleSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    manager!.moduleNo.value =
        (data[StringConstants.moduleno] as num?)?.toInt() ?? 0;
    manager!.moduleEnabled.value = (data['enabled'] as bool?) ?? false;
    manager!.moduleProduct.value = (data['product'] as String?) ?? '';
    manager!.moduleId.value = (data['id'] as num?)?.toInt() ?? 0;
    manager!.moduleRevision.value = (data['revision'] as num?)?.toInt() ?? 0;
    manager!.moduleHardware.value = (data['hardware'] as String?) ?? '';
    manager!.moduleFirmware.value = (data['firmware'] as String?) ?? '';
    manager!.moduleDate.value = (data['date'] as String?) ?? '';
    manager!.moduleProtocol.value = (data['protocol'] as num?)?.toInt() ?? 0;
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
