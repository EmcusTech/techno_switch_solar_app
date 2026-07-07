import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_history_dashboard.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogHistoryScreen extends StatefulWidget {
  const LogHistoryScreen({
    super.key,
    required this.panelName,
    required this.panelVersionNo,
    required this.siteId,
    this.refreshTrigger,
  });

  final String panelName;
  final String panelVersionNo;
  final int? siteId;
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen>
    with LogUiDelegateMixin, RouteAware {
  LogController? _controller;
  bool _routeSubscriptionRegistered = false;

  @override
  void initState() {
    super.initState();
    LogBinding.installHistory(
      LogFlowArgs.history(
        panelName: widget.panelName,
        panelVersionNo: widget.panelVersionNo,
        siteId: widget.siteId,
      ),
    );
    _controller = LogBinding.findHistory();
    _controller?.attachUi(this);
    widget.refreshTrigger?.addListener(_onExternalRefresh);
  }

  void _onExternalRefresh() {
    if (!mounted) return;
    final controller = LogBinding.findHistory();
    if (controller == null) return;
    _controller = controller;
    controller.attachUi(this);
    controller.reinitializeForHistoryTab();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscriptionRegistered) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        appRouteObserver.subscribe(this, route);
        _routeSubscriptionRegistered = true;
      }
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onExternalRefresh);
    if (_routeSubscriptionRegistered) {
      appRouteObserver.unsubscribe(this);
      _routeSubscriptionRegistered = false;
    }
    _controller?.detachUi();
    LogBinding.removeHistorySession();
    LogBinding.removeHistory();
    super.dispose();
  }

  @override
  void didPopNext() {
    final controller = LogBinding.findHistory();
    if (controller == null) return;
    _controller = controller;
    controller.attachUi(this);
    controller.reinitializeForHistoryTab();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final history = controller?.args.history;
    if (controller == null || history == null) {
      return const SizedBox.shrink();
    }

    return GetBuilder<LogController>(
      tag: LogBinding.historyTag,
      init: controller,
      builder: (controller) {
        return WillPopScope(
          onWillPop: () async => false,
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
                            Text(
                              StringConstants.logHistory,
                              style: StyleConstants.black20w700Style,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 23),
                      Expanded(
                        child: LogHistoryDashboard(
                          history: history,
                          controller: controller,
                        ),
                      ),
                    ],
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
