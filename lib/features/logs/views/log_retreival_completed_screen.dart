import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_completed_content.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_shell.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogRetrievalCompletedScreen extends StatefulWidget {
  const LogRetrievalCompletedScreen({super.key});

  @override
  State<LogRetrievalCompletedScreen> createState() =>
      _LogRetrievalCompletedScreenState();
}

class _LogRetrievalCompletedScreenState extends State<LogRetrievalCompletedScreen>
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

  Future<void> _handleBack() async {
    await _controller.handleCompletedBackNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return LogRetrievalShell(
      title: StringConstants.eventLog,
      onBack: _handleBack,
      canPop: false,
      onPopInvoked: (_, __) async {
        await _handleBack();
      },
      child: LogRetrievalCompletedContent(
        onBack: _handleBack,
        onNext: _controller.openEventLogFromCompleted,
      ),
    );
  }
}
