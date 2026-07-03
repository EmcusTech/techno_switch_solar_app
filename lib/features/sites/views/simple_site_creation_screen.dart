import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/create_project/views/site_creation_page.dart';
import 'package:techno_switch_solar_app/features/home/bindings/home_screen_binding.dart';
import 'package:techno_switch_solar_app/features/home/views/home_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/models/create_project/site_creation_page_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SimpleSiteCreationScreen extends GetView<SimpleSiteCreationController> {
  const SimpleSiteCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSiteCreationPageHost(controller: controller);
  }
}

class _SimpleSiteCreationPageHost extends StatefulWidget {
  const _SimpleSiteCreationPageHost({required this.controller});

  final SimpleSiteCreationController controller;

  @override
  State<_SimpleSiteCreationPageHost> createState() =>
      _SimpleSiteCreationPageHostState();
}

class _SimpleSiteCreationPageHostState extends State<_SimpleSiteCreationPageHost>
    implements SimpleSiteCreationUiDelegate {
  SimpleSiteCreationController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  void popScreen([int? siteId]) {
    if (!mounted) return;
    Navigator.of(context).pop(siteId);
  }

  @override
  void popBack() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.success,
      ),
    );
  }

  @override
  void openHomeAndClearStack() {
    if (!mounted) return;
    HomeScreenBinding().dependencies();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Future<void> openExistingSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) async {
    if (!mounted) return;
    SiteBinding(
      args: SiteArgs(site: site, siteWithLogCount: siteWithLogCount),
    ).dependencies();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SiteScreen()),
      (route) => false,
    );
  }

  @override
  Future<void> disconnectBle() async {
    await _controller.disconnectBleDevice();
  }

  @override
  void initState() {
    super.initState();
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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstants.scaffoldGradientTop,
                  ColorConstants.white,
                ],
              ),
            ),
            child: Stack(
              children: [
                SvgPicture.asset(AssetConstants.background1),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: controller.handleBackNavigation,
                              child: SvgPicture.asset(
                                AssetConstants.arrowBackIcon,
                              ),
                            ),
                            const SizedBox(width: 17),
                            Expanded(
                              child: Text(
                                StringConstants.createSite,
                                style: StyleConstants.textBodyDark20w700Style,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: SiteCreationForm(
                                      model: SiteCreationPageModel(
                                        siteNameController:
                                            controller.siteNameController,
                                        installerNameController:
                                            controller.installerNameController,
                                        companyNameController:
                                            controller.companyNameController,
                                        saqccRegNumberController:
                                            controller.saqccRegNumberController,
                                        buildingNameController:
                                            controller.buildingNameController,
                                        installerContactNumberController:
                                            controller
                                                .installerContactNumberController,
                                        installerEmailController:
                                            controller.installerEmailController,
                                        siteDescriptionController:
                                            controller.siteDescriptionController,
                                        validationErrors:
                                            controller.validationErrors,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap:
                                              controller.isLoading
                                                  ? null
                                                  : controller.cancel,
                                          child: Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color:
                                                  controller.isLoading
                                                      ? ColorConstants
                                                          .buttonSecondaryBackground
                                                          .withValues(
                                                            alpha: 0.5,
                                                          )
                                                      : ColorConstants
                                                          .buttonSecondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: Center(
                                              child: Text(
                                                StringConstants.cancel,
                                                style: StyleConstants
                                                    .labelText14w700Style
                                                    .copyWith(
                                                      color:
                                                          controller.isLoading
                                                              ? ColorConstants
                                                                  .labelText
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                              : ColorConstants
                                                                  .labelText,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap:
                                              controller.isLoading
                                                  ? null
                                                  : controller.submit,
                                          child: Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color:
                                                  controller.isLoading
                                                      ? ColorConstants.primary
                                                          .withValues(
                                                            alpha: 0.5,
                                                          )
                                                      : ColorConstants.primary,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: Center(
                                              child:
                                                  controller.isLoading
                                                      ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    ColorConstants
                                                                        .white,
                                                                  ),
                                                            ),
                                                      )
                                                      : Text(
                                                        StringConstants
                                                            .createSite,
                                                        style:
                                                            StyleConstants
                                                                .white14w700Style,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
