import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ServiceDueConfig {
  String reminder = StringConstants.off;

  final TextEditingController yearController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
}

/// Controller for the Service Due bottom sheet.
class ServiceDueController extends PeripheralModeController {
  ServiceDueController({required super.deviceId, required super.refreshTrigger});

  final ServiceDueConfig config = ServiceDueConfig();

  final List<String> reminderOptions = [StringConstants.off, StringConstants.on];

  @override
  void initModel() {}

  @override
  void disposeModel() {
    config.yearController.dispose();
    config.monthController.dispose();
    config.dayController.dispose();
    config.hourController.dispose();
    config.minuteController.dispose();
    config.companyController.dispose();
    config.contactController.dispose();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadServiceDueSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    config.yearController.text = (data['year'] as num?)?.toString() ?? '0';
    config.monthController.text = (data['month'] as num?)?.toString() ?? '0';
    config.dayController.text = (data['day'] as num?)?.toString() ?? '0';
    config.hourController.text = (data['hour'] as num?)?.toString() ?? '0';
    config.minuteController.text = (data['minute'] as num?)?.toString() ?? '0';
    config.companyController.text = (data['company'] as String?) ?? '';
    config.contactController.text = (data['contact'] as String?) ?? '';
    config.reminder =
        (data['reminder'] as int?) == 1 ? StringConstants.on : StringConstants.off;
  }

  @override
  void loadFromManager() {
    if (manager == null) return;
    config.yearController.text = manager!.serviceDueYear.value.toString();
    config.monthController.text = manager!.serviceDueMonth.value.toString();
    config.dayController.text = manager!.serviceDueDay.value.toString();
    config.hourController.text = manager!.serviceDueHour.value.toString();
    config.minuteController.text = manager!.serviceDueMinute.value.toString();
    config.companyController.text = manager!.serviceDueCompany.value;
    config.contactController.text = manager!.serviceDueContact.value;
    config.reminder =
        manager!.serviceDueReminder.value == 0 ? StringConstants.off : StringConstants.on;
    refreshUi();
  }

  @override
  void pushToManager() {
    final m = manager!;
    m.serviceDueYear.value = int.parse(config.yearController.text);
    m.serviceDueMonth.value = int.parse(config.monthController.text);
    m.serviceDueDay.value = int.parse(config.dayController.text);
    m.serviceDueHour.value = int.parse(config.hourController.text);
    m.serviceDueMinute.value = int.parse(config.minuteController.text);
    m.serviceDueCompany.value = config.companyController.text;
    m.serviceDueContact.value = config.contactController.text;
    m.serviceDueReminder.value = config.reminder == StringConstants.on ? 1 : 0;
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveServiceDue(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() {
    if (config.yearController.text.isEmpty ||
        config.monthController.text.isEmpty ||
        config.dayController.text.isEmpty ||
        config.hourController.text.isEmpty ||
        config.minuteController.text.isEmpty) {
      return false;
    }

    final year = int.parse(config.yearController.text);
    final month = int.parse(config.monthController.text);
    final day = int.parse(config.dayController.text);
    final hour = int.parse(config.hourController.text);
    final minute = int.parse(config.minuteController.text);

    if (year < 2010 || year > 9999) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;

    try {
      final dt = DateTime(year, month, day, hour, minute);
      if (dt.year != year || dt.month != month || dt.day != day) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void setReminder(String v) {
    config.reminder = v;
    refreshUi();
  }

  void onFieldChanged() => refreshUi();
}
