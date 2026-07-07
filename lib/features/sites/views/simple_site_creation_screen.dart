import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:techno_switch_solar_app/features/sites/views/simple_site_creation_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/simple_site_creation_content.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_shell.dart';

class SimpleSiteCreationScreen extends StatefulWidget {
  const SimpleSiteCreationScreen({super.key});

  @override
  State<SimpleSiteCreationScreen> createState() =>
      _SimpleSiteCreationScreenState();
}

class _SimpleSiteCreationScreenState extends State<SimpleSiteCreationScreen>
    with SimpleSiteCreationUiDelegateMixin {
  late final SimpleSiteCreationController _controller;

  @override
  SimpleSiteCreationController get simpleSiteCreationController => _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SimpleSiteCreationController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SimpleSiteCreationController>()) {
      Get.delete<SimpleSiteCreationController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SimpleSiteCreationController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          body: SiteShell(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SimpleSiteCreationAppBar(
                      onBack: controller.handleBackNavigation,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SimpleSiteCreationContent(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
