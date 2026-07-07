import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_loading_content.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_shell.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogRetrievalLoadingScreen extends StatefulWidget {
  const LogRetrievalLoadingScreen({super.key});

  @override
  State<LogRetrievalLoadingScreen> createState() =>
      _LogRetrievalLoadingScreenState();
}

class _LogRetrievalLoadingScreenState extends State<LogRetrievalLoadingScreen>
    with LogUiDelegateMixin {
  late final LogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LogController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LogController>(
      builder: (controller) {
        return LogRetrievalShell(
          title: StringConstants.eventLog,
          onBack: controller.showStopConfirmationAndCancel,
          canPop: controller.allowExit,
          child: LogRetrievalLoadingContent(
            ble: controller.ble,
            onCancel: controller.showStopConfirmationAndCancel,
          ),
        );
      },
    );
  }
}
