import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';

class LogBinding extends Bindings {
  LogBinding({required this.args});

  /// Embedded log-history tab inside [ProjectDashboardScreen].
  static const String historyTag = 'logHistory';

  /// Read-only event-log viewer opened from log history (does not replace history).
  static const String historySessionTag = 'logHistorySession';

  final LogFlowArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    Get.lazyPut<LogController>(() => LogController(args: args));
  }

  static void installHistory(LogFlowArgs args) {
    if (Get.isRegistered<LogController>(tag: historyTag)) {
      Get.delete<LogController>(tag: historyTag);
    }
    Get.put(LogController(args: args), tag: historyTag);
  }

  static LogController? findHistory() {
    if (!Get.isRegistered<LogController>(tag: historyTag)) return null;
    return Get.find<LogController>(tag: historyTag);
  }

  static void installHistorySession(LogFlowArgs args) {
    if (Get.isRegistered<LogController>(tag: historySessionTag)) {
      Get.delete<LogController>(tag: historySessionTag);
    }
    Get.put(LogController(args: args), tag: historySessionTag);
  }

  static LogController findHistorySession() {
    return Get.find<LogController>(tag: historySessionTag);
  }

  static void removeHistorySession() {
    if (Get.isRegistered<LogController>(tag: historySessionTag)) {
      Get.delete<LogController>(tag: historySessionTag);
    }
  }

  static void removeHistory() {
    if (Get.isRegistered<LogController>(tag: historyTag)) {
      Get.delete<LogController>(tag: historyTag);
    }
  }
}
