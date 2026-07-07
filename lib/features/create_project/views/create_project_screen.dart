import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/views/create_project_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_app_bar.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_navigation.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_shell.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_wizard_page_view.dart';

class CreateSiteScreen extends StatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen>
    with CreateProjectUiDelegateMixin {
  late final CreateProjectController _controller;
  late final PageController _pageController;
  final BleLogController _bleController = Get.find<BleLogController>();
  final GlobalKey<CreateProjectWizardPageViewState> _wizardKey =
      GlobalKey<CreateProjectWizardPageViewState>();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CreateProjectController>();
    _pageController = PageController();
    _controller.attachUi(this);
    _controller.setupPageNavigation(
      animateNext: () => _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      animatePrevious: () => _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
    _controller.commitCurrentStepHandler = () async {
      final wizard = _wizardKey.currentState;
      if (wizard == null) return true;
      return wizard.commitCurrentStep(_controller.currentStep);
    };
    _controller.commitPanelInfoHandler = () async {
      final wizard = _wizardKey.currentState;
      if (wizard == null) return false;
      return wizard.commitPanelInfo();
    };
  }

  @override
  void dispose() {
    _controller.detachUi();
    _pageController.dispose();
    if (Get.isRegistered<CreateProjectController>()) {
      Get.delete<CreateProjectController>();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    _controller.setCurrentStep(page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateProjectController>(
      init: _controller,
      builder: (controller) => PopScope(
        canPop: !_bleController.isConnected,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final disconnect = await controller.confirmAndDisconnect();
          if (disconnect && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: CreateProjectShell(
            appBar: CreateProjectAppBar(
              controller: controller,
              onBack: controller.onLeadingBackPressed,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CreateProjectWizardPageView(
                    key: _wizardKey,
                    controller: controller,
                    pageController: _pageController,
                    onPageChanged: _onPageChanged,
                  ),
                ),
                const SizedBox(height: 20),
                CreateProjectNavigation(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
