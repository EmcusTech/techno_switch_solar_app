import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/panel_info_defaults.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelInfoConfig {
  final TextEditingController panelIdController = TextEditingController();
  final TextEditingController panelNameController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController secondController = TextEditingController();
  final TextEditingController delayController = TextEditingController();

  void dispose() {
    panelIdController.dispose();
    panelNameController.dispose();
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();
    delayController.dispose();
  }
}

/// Controller for the Panel Info bottom sheet.
class PanelInfoController extends PeripheralModeController {
  PanelInfoController({
    required super.deviceId,
    required super.refreshTrigger,
    this.projectPanelName,
    this.preferFactoryDefaults = false,
  });

  final String? projectPanelName;
  final bool preferFactoryDefaults;

  final PanelInfoConfig config = PanelInfoConfig();

  bool useMobileTime = PanelInfoDefaults.useMobileTime;
  Timer? _timer;

  @override
  void initModel() {
    applyFactoryDefaults();
  }

  @override
  void disposeModel() {
    _timer?.cancel();
    config.dispose();
  }

  @override
  void onRefreshTriggered() {
    if (preferFactoryDefaults) {
      applyFactoryDefaults();
      pushToManager();
      refreshUi();
      return;
    }
    loadFromManager();
  }

  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await loadCache();
    if (cached != null) {
      applyCachedData(cached);
      refreshUi();
      return;
    }
    if (preferFactoryDefaults) {
      applyFactoryDefaults();
      pushToManager();
      refreshUi();
      return;
    }
    loadFromManager();
    refreshUi();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadPanelInfoSetup(deviceId);

  void applyFactoryDefaults() {
    config.panelIdController.text = PanelInfoDefaults.panelNo.toString();
    config.panelNameController.text = PanelInfoDefaults.resolvePanelName(
      projectPanelName: projectPanelName,
    );
    config.delayController.text =
        PanelInfoDefaults.eventReminderDelay.toString();
    useMobileTime = PanelInfoDefaults.useMobileTime;
    if (useMobileTime) {
      startLiveTime();
    } else {
      _applyDateTimeToControllers(DateTime.now());
    }
  }

  void _applyDateTimeToControllers(DateTime dateTime) {
    config.yearController.text = dateTime.year.toString();
    config.monthController.text = dateTime.month.toString().padLeft(2, '0');
    config.dayController.text = dateTime.day.toString().padLeft(2, '0');
    config.hourController.text = dateTime.hour.toString().padLeft(2, '0');
    config.minuteController.text = dateTime.minute.toString().padLeft(2, '0');
    config.secondController.text = dateTime.second.toString().padLeft(2, '0');
  }

  int? _readPanelIdFromCache(Map<String, dynamic> data) {
    return (data['panelId'] as num?)?.toInt() ??
        (data[StringConstants.offlineprovisioned] as num?)?.toInt();
  }

  String? _readPanelNameFromCache(Map<String, dynamic> data) {
    return (data['panelName'] as String?) ??
        (data[StringConstants.panelname] as String?);
  }

  @override
  void applyCachedData(Map<String, dynamic> data) {
    config.panelIdController.text =
        _readPanelIdFromCache(data)?.toString() ??
        PanelInfoDefaults.panelNo.toString();
    config.panelNameController.text =
        _readPanelNameFromCache(data) ??
        PanelInfoDefaults.resolvePanelName(projectPanelName: projectPanelName);
    config.yearController.text = (data['year'] as num?)?.toString() ?? '0';
    config.monthController.text = (data['month'] as num?)?.toString() ?? '0';
    config.dayController.text = (data['day'] as num?)?.toString() ?? '0';
    config.hourController.text = (data['hour'] as num?)?.toString() ?? '0';
    config.minuteController.text = (data['minute'] as num?)?.toString() ?? '0';
    config.secondController.text = (data['second'] as num?)?.toString() ?? '0';
    config.delayController.text =
        (data['delay'] as num?)?.toString() ??
        PanelInfoDefaults.eventReminderDelay.toString();
    useMobileTime =
        (data[StringConstants.usemobiletime] as bool?) ??
        PanelInfoDefaults.useMobileTime;
    if (useMobileTime) {
      startLiveTime();
    }
  }

  @override
  void loadFromManager() {
    if (manager == null) return;
    config.panelIdController.text = manager!.panelInfoPanelNo.value.toString();
    config.panelNameController.text = manager!.panelInfoPanelName.value;
    config.yearController.text = manager!.panelInfoYear.value.toString();
    config.monthController.text = manager!.panelInfoMonth.value
        .toString()
        .padLeft(2, '0');
    config.dayController.text = manager!.panelInfoDay.value.toString().padLeft(
      2,
      '0',
    );
    config.hourController.text = manager!.panelInfoHour.value
        .toString()
        .padLeft(2, '0');
    config.minuteController.text = manager!.panelInfoMinute.value
        .toString()
        .padLeft(2, '0');
    config.secondController.text = manager!.panelInfoSecond.value
        .toString()
        .padLeft(2, '0');
    config.delayController.text =
        manager!.panelInfoEventReminderDelay.value.toString();
    refreshUi();
  }

  // ───────── TIME LOGIC ─────────

  void startLiveTime() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _applyDateTimeToControllers(DateTime.now());
      refreshUi();
    });
  }

  void stopLiveTime() {
    _timer?.cancel();
  }

  void toggleMobileTime(bool value) {
    useMobileTime = value;
    if (value) {
      startLiveTime();
    } else {
      stopLiveTime();
      loadFromManager();
    }
    refreshUi();
  }

  @override
  void pushToManager() {
    if (manager == null) return;
    manager!.panelInfoPanelNo.value =
        int.tryParse(config.panelIdController.text) ??
        PanelInfoDefaults.panelNoBle;
    manager!.panelInfoPanelName.value = config.panelNameController.text;
    manager!.panelInfoYear.value =
        int.tryParse(config.yearController.text) ?? DateTime.now().year;
    manager!.panelInfoMonth.value =
        int.tryParse(config.monthController.text) ?? DateTime.now().month;
    manager!.panelInfoDay.value =
        int.tryParse(config.dayController.text) ?? DateTime.now().day;
    manager!.panelInfoHour.value =
        int.tryParse(config.hourController.text) ?? DateTime.now().hour;
    manager!.panelInfoMinute.value =
        int.tryParse(config.minuteController.text) ?? DateTime.now().minute;
    manager!.panelInfoSecond.value =
        int.tryParse(config.secondController.text) ?? DateTime.now().second;
    manager!.panelInfoEventReminderDelay.value =
        int.tryParse(config.delayController.text) ??
        PanelInfoDefaults.delayBle;
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.savePanelInfo(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() {
    // Panel No: 1–31
    final panelNo = int.tryParse(config.panelIdController.text);
    if (panelNo == null || panelNo < 1 || panelNo > 31) return false;

    // Panel Name: max 21 chars, non-empty
    final panelName = config.panelNameController.text.trim();
    if (panelName.isEmpty) return false;
    if (panelName.length > 21) return false;

    if (config.yearController.text.isEmpty ||
        config.monthController.text.isEmpty ||
        config.dayController.text.isEmpty ||
        config.hourController.text.isEmpty ||
        config.minuteController.text.isEmpty ||
        config.secondController.text.isEmpty) {
      return false;
    }

    final year = int.tryParse(config.yearController.text) ?? 0;
    final month = int.tryParse(config.monthController.text) ?? 0;
    final day = int.tryParse(config.dayController.text) ?? 0;
    final hour = int.tryParse(config.hourController.text) ?? 0;
    final minute = int.tryParse(config.minuteController.text) ?? 0;
    final second = int.tryParse(config.secondController.text) ?? 0;

    if (year < 1970 || year > 9999) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (second < 0 || second > 59) return false;

    try {
      final dt = DateTime(year, month, day, hour, minute, second);
      if (dt.year != year || dt.month != month || dt.day != day) return false;
    } catch (_) {
      return false;
    }

    // Event Reminder Delay: 10–600
    final delay = int.tryParse(config.delayController.text);
    if (delay == null || delay < 10 || delay > 600) return false;

    return true;
  }

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void onFieldChanged() => refreshUi();
}
