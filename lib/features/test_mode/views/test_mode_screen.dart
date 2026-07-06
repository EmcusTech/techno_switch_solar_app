import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/views/test_mode_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/test_mode/widgets/test_mode_app_bar.dart';
import 'package:techno_switch_solar_app/features/test_mode/widgets/test_mode_content_panel.dart';
import 'package:techno_switch_solar_app/features/test_mode/widgets/test_mode_shell.dart';

class TestModeScreen extends StatefulWidget {
  const TestModeScreen({super.key});

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen>
    with TestModeUiDelegateMixin {
  late final TestModeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TestModeController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = TestModeShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestModeAppBar(controller: _controller),
          const SizedBox(height: 19),
          Expanded(child: TestModeContentPanel(controller: _controller)),
        ],
      ),
    );

    if (_controller.embedded) return body;

    return Scaffold(
      extendBody: true,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _controller.handleWillPop();
          if (!context.mounted) return;
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        },
        child: body,
      ),
    );
  }
}
