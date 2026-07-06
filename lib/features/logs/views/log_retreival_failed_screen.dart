import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_failed_content.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_shell.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogRetrievalFailedScreen extends StatefulWidget {
  const LogRetrievalFailedScreen({super.key});

  @override
  State<LogRetrievalFailedScreen> createState() =>
      _LogRetrievalFailedScreenState();
}

class _LogRetrievalFailedScreenState extends State<LogRetrievalFailedScreen>
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
    return LogRetrievalShell(
      title: StringConstants.logRetrievalFailed,
      onBack: popScreen,
      child: const LogRetrievalFailedContent(),
    );
  }
}
