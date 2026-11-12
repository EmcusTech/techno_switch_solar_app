import 'dart:async';

import 'package:get/get.dart';
import 'package:Technoswitch/ble/controller/ble_log_controller.dart';
import 'package:Technoswitch/features/peripherals/shared/controllers/peripheral_mode_controller.dart';

/// Clock fields for the Date & Time panel action.
class PanelDateTimeController extends PeripheralModeController {
  PanelDateTimeController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  static const int firstYear = 2010;

  int hour = 0;
  int minute = 0;
  int second = 0;
  int day = 1;
  int month = 1;
  int year = firstYear;
  bool useSystemTime = true;

  Timer? _timer;

  @override
  void initModel() {
    _applyClock(DateTime.now());
    useSystemTime = true;
  }

  @override
  void disposeModel() {
    _timer?.cancel();
  }

  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    if (loadAbandoned) return;
    if (useSystemTime) {
      startLiveTime();
    } else {
      loadFromManager();
    }
    refreshUi();
    markReadyToPersist();
  }

  @override
  void onRefreshTriggered() {
    useSystemTime = false;
    stopLiveTime();
    loadFromManager();
    refreshUi();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() async => null;

  @override
  void applyCachedData(Map<String, dynamic> data) {}

  @override
  void loadFromManager() {
    if (manager == null) return;
    hour = manager!.panelDateTimeHour.value;
    minute = manager!.panelDateTimeMinute.value;
    second = manager!.panelDateTimeSecond.value;
    day = manager!.panelDateTimeDay.value;
    month = manager!.panelDateTimeMonth.value;
    year = manager!.panelDateTimeYear.value;
    _clampFields();
  }

  @override
  void pushToManager() {
    if (manager == null) return;
    if (useSystemTime) {
      _applyClock(DateTime.now());
    }
    manager!.panelDateTimeHour.value = hour;
    manager!.panelDateTimeMinute.value = minute;
    manager!.panelDateTimeSecond.value = second;
    manager!.panelDateTimeDay.value = day;
    manager!.panelDateTimeMonth.value = month;
    manager!.panelDateTimeYear.value = year;
  }

  @override
  Future<void> save() async {}

  @override
  bool computeIsValid() {
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (second < 0 || second > 59) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > daysInMonth) return false;
    if (year < firstYear) return false;
    return true;
  }

  @override
  void updateValidationErrors() {}

  int get daysInMonth {
    final safeMonth = month.clamp(1, 12);
    return DateTime(year, safeMonth + 1, 0).day;
  }

  List<int> get yearChoices {
    final current = DateTime.now().year;
    final start = year < firstYear ? year : firstYear;
    final end = year > current ? year : current;
    return <int>[for (var value = start; value <= end; value++) value];
  }

  void startLiveTime() {
    _timer?.cancel();
    _applyClock(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _applyClock(DateTime.now());
      refreshUi();
    });
  }

  void stopLiveTime() {
    _timer?.cancel();
    _timer = null;
  }

  void toggleSystemTime(bool value) {
    useSystemTime = value;
    if (value) {
      startLiveTime();
    } else {
      stopLiveTime();
    }
    refreshUi();
  }

  void setHour(int value) {
    hour = value;
    refreshUi();
  }

  void setMinute(int value) {
    minute = value;
    refreshUi();
  }

  void setSecond(int value) {
    second = value;
    refreshUi();
  }

  void setDay(int value) {
    day = value;
    refreshUi();
  }

  void setMonth(int value) {
    month = value;
    if (day > daysInMonth) day = daysInMonth;
    refreshUi();
  }

  void setYear(int value) {
    year = value;
    if (day > daysInMonth) day = daysInMonth;
    refreshUi();
  }

  void _applyClock(DateTime clock) {
    hour = clock.hour;
    minute = clock.minute;
    second = clock.second;
    day = clock.day;
    month = clock.month;
    year = clock.year;
  }

  void _clampFields() {
    if (month < 1) month = 1;
    if (month > 12) month = 12;
    if (year < firstYear) year = firstYear;
    final lastDay = daysInMonth;
    if (day < 1) day = 1;
    if (day > lastDay) day = lastDay;
    if (hour < 0) hour = 0;
    if (hour > 23) hour = 23;
    if (minute < 0) minute = 0;
    if (minute > 59) minute = 59;
    if (second < 0) second = 0;
    if (second > 59) second = 59;
  }
}
