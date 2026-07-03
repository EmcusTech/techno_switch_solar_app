import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalCompletedScreen extends GetView<LogController> {
  const LogRetrievalCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LogRetrievalCompletedPageHost(controller: controller);
  }
}

class _LogRetrievalCompletedPageHost extends StatefulWidget {
  const _LogRetrievalCompletedPageHost({required this.controller});

  final LogController controller;

  @override
  State<_LogRetrievalCompletedPageHost> createState() =>
      _LogRetrievalCompletedPageHostState();
}

class _LogRetrievalCompletedPageHostState
    extends State<_LogRetrievalCompletedPageHost> with LogUiDelegateMixin {
  LogController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        await _controller.handleCompletedBackNavigation();
      },
      child: Scaffold(
        body: Container(
          height: MediaQuery.sizeOf(context).height,
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
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await _controller.handleCompletedBackNavigation();
                            },
                            child: SvgPicture.asset(
                              AssetConstants.arrowBackIcon,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            StringConstants.eventLog,
                            style: StyleConstants.black20w700Style,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 19),
                    _buildCompletedLogsContainer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedLogsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SvgPicture.asset(AssetConstants.background3),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  'Retrieval\nCompleted!',
                  style: StyleConstants.success24w600Style,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Lottie.asset(
              AssetConstants.firmwareUpgradeSuccessJson,
              height: 180,
              width: 180,
              repeat: false,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _controller.handleCompletedBackNavigation();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.buttonSecondaryBackground,
                          borderRadius: BorderRadius.circular(28.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 30,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_back,
                                color: ColorConstants.labelText,
                              ),
                              SizedBox(width: 6),
                              Text(
                                StringConstants.back,
                                style: StyleConstants.labelText14boldStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _controller.openEventLogFromCompleted,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(28.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 30,
                            right: 16,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Row(
                            children: [
                              Text(
                                UiStrings.nextButton,
                                style: StyleConstants.white14boldStyle,
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                color: ColorConstants.white,
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
  }
}
