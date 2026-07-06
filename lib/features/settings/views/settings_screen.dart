import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/views/settings_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/settings/widgets/settings_app_bar.dart';
import 'package:techno_switch_solar_app/features/settings/widgets/settings_content_panel.dart';
import 'package:techno_switch_solar_app/features/settings/widgets/settings_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SettingsUiDelegateMixin {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SettingsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsAppBar(controller: _controller),
          const SizedBox(height: 19),
          Expanded(child: SettingsContentPanel(controller: _controller)),
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
