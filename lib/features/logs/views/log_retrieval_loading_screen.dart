import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalLoadingScreen extends GetView<LogController> {
  const LogRetrievalLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LogRetrievalLoadingPageHost(controller: controller);
  }
}

class _LogRetrievalLoadingPageHost extends StatefulWidget {
  const _LogRetrievalLoadingPageHost({required this.controller});

  final LogController controller;

  @override
  State<_LogRetrievalLoadingPageHost> createState() =>
      _LogRetrievalLoadingPageHostState();
}

class _LogRetrievalLoadingPageHostState extends State<_LogRetrievalLoadingPageHost>
    with LogUiDelegateMixin {
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
  Future<bool?> showStopLogRetrievalDialog() {
    return showDialog<bool>(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: ColorConstants.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  UiStrings.stopLogRetrievalDialogTitle,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  UiStrings.stopLogRetrievalConfirmMessage,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.cancel,
                              style: StyleConstants.textGray16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.yesStop,
                              style: StyleConstants.white16w600Style,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = _controller.ble;
    return GetBuilder<LogController>(
      builder: (controller) {
        return PopScope(
          canPop: controller.allowExit,
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
                                onTap: controller.showStopConfirmationAndCancel,
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
                        Expanded(child: _buildRetrievingLogsContainer(ble)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetrievingLogsContainer(BleManager ble) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AssetConstants.background2),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Text(
                StringConstants.retrievingLogs,
                style: StyleConstants.textMuted24w600Style,
              ),
            ),
          ),
          Lottie.asset(
            AssetConstants.fetchingLogJson,
            height: 320,
            width: 320,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: ValueListenableBuilder<String>(
              valueListenable: ble.processDesc,
              builder: (context, value, _) {
                return Text(
                  value,
                  style: StyleConstants.textMuted12w400Style,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: ble.bleProcess.read1000LogsCount,
                    builder: (context, readCount, _) {
                      final percent =
                          (readCount / 1000.0).clamp(0.0, 1.0).toDouble();
                      return Column(
                        children: [
                          Text(
                            '${(percent * 100).toStringAsFixed(1)}%',
                            style: StyleConstants.black32w700Style,
                            maxLines: 1,
                          ),
                          SizedBox(height: 23),
                          LinearPercentIndicator(
                            lineHeight: 11.0,
                            percent: percent,
                            backgroundColor: ColorConstants.progressTrack,
                            progressColor: ColorConstants.primary,
                            barRadius: Radius.circular(20),
                          ),
                          SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: _buildCancelLogRetrievalButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelLogRetrievalButton() {
    return GestureDetector(
      onTap: _controller.showStopConfirmationAndCancel,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ColorConstants.primary,
          borderRadius: BorderRadius.circular(28.5),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            StringConstants.cancel,
            style: StyleConstants.white16w600Style,
          ),
        ),
      ),
    );
  }
}
