import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/event_log_content_section.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/event_log_filter_bottom_sheet.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

class EventLogScreen extends StatelessWidget {
  const EventLogScreen({super.key, this.fromLogHistory = false});

  final bool fromLogHistory;

  LogController get _controller {
    if (fromLogHistory) {
      return LogBinding.findHistorySession();
    }
    return Get.find<LogController>();
  }

  @override
  Widget build(BuildContext context) {
    return _EventLogPageHost(
      controller: _controller,
      fromLogHistory: fromLogHistory,
    );
  }
}

class _EventLogPageHost extends StatefulWidget {
  const _EventLogPageHost({
    required this.controller,
    this.fromLogHistory = false,
  });

  final LogController controller;
  final bool fromLogHistory;

  @override
  State<_EventLogPageHost> createState() => _EventLogPageHostState();
}

class _EventLogPageHostState extends State<_EventLogPageHost>
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
    if (widget.fromLogHistory) {
      LogBinding.removeHistorySession();
    } else if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    super.dispose();
  }

  void _showFilterBottomSheet() {
    void apply() {
      _controller.applyFilters();
      Navigator.pop(uiContext);
    }

    void reset() {
      _controller.resetFilters();
      Navigator.pop(uiContext);
    }

    showFilterBottomSheet(
      onApply: apply,
      onReset: reset,
      builder:
          (sheetSetState) => EventLogFilterBottomSheet(
            controller: _controller,
            onSheetStateChange: () => sheetSetState(() {}),
            onApply: apply,
            onReset: reset,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LogController>(
      tag: widget.fromLogHistory ? LogBinding.historySessionTag : null,
      init: widget.fromLogHistory ? widget.controller : null,
      builder: (controller) {
        final Widget logsSection =
            controller.useProvidedLogs
                ? EventLogContentSection(
                  controller: controller,
                  logsToDisplay: controller.getDisplayLogs(),
                )
                : ValueListenableBuilder<List<LogModel>>(
                  valueListenable: controller.ble.bleProcess.validEventLogs,
                  builder: (context, _, __) {
                    return EventLogContentSection(
                      controller: controller,
                      logsToDisplay: controller.getDisplayLogs(),
                    );
                  },
                );

        return Scaffold(
          extendBody: true,
          body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              await controller.handleEventLogBackNavigation();
            },
            child: Container(
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
                                onTap:
                                    () async =>
                                        await controller
                                            .handleEventLogBackNavigation(),
                                child: SvgPicture.asset(
                                  AssetConstants.arrowBackIcon,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                StringConstants.eventLog,
                                style: StyleConstants.black20w700Style,
                              ),
                              const Spacer(),
                              if (controller.eventLogArgs?.isLiveEventLogs ==
                                  true)
                                Padding(
                                  padding: const EdgeInsets.only(right: 18.0),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        controller.canClearLogs
                                            ? () =>
                                                controller.confirmAndClearLogs()
                                            : null,
                                    child: Opacity(
                                      opacity:
                                          controller.canClearLogs ? 1.0 : 0,
                                      child: SvgPicture.asset(
                                        AssetConstants.clearIcon,
                                        height: 28,
                                        width: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap:
                                    () => showExportBottomSheet(
                                      onExportPdf: controller.exportEventLogPdf,
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: SvgPicture.asset(
                                    AssetConstants.shareIcon,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showFilterBottomSheet,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: SvgPicture.asset(
                                    AssetConstants.filterIcon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 19),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: logsSection,
                          ),
                        ),
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
}
