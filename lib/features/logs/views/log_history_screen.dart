import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogHistoryScreen extends StatelessWidget {
  final String panelName;
  final String panelVersionNo;
  final int? siteId;
  final ValueNotifier<int>? refreshTrigger;

  const LogHistoryScreen({
    super.key,
    required this.panelName,
    required this.panelVersionNo,
    required this.siteId,
    this.refreshTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return _LogHistoryBootstrap(
      args: LogFlowArgs.history(
        panelName: panelName,
        panelVersionNo: panelVersionNo,
        siteId: siteId,
      ),
      refreshTrigger: refreshTrigger,
    );
  }
}

class _LogHistoryBootstrap extends StatefulWidget {
  const _LogHistoryBootstrap({
    required this.args,
    this.refreshTrigger,
  });

  final LogFlowArgs args;
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<_LogHistoryBootstrap> createState() => _LogHistoryBootstrapState();
}

class _LogHistoryBootstrapState extends State<_LogHistoryBootstrap> {
  @override
  void initState() {
    super.initState();
    LogBinding(args: widget.args).dependencies();
  }

  @override
  void dispose() {
    if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LogHistoryView(refreshTrigger: widget.refreshTrigger);
  }
}

class _LogHistoryView extends GetView<LogController> {
  const _LogHistoryView({this.refreshTrigger});

  final ValueNotifier<int>? refreshTrigger;

  @override
  Widget build(BuildContext context) {
    return _LogHistoryPageHost(
      args: controller.args,
      refreshTrigger: refreshTrigger,
    );
  }
}

class _LogHistoryPageHost extends StatefulWidget {
  const _LogHistoryPageHost({
    required this.args,
    this.refreshTrigger,
  });

  final LogFlowArgs args;
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<_LogHistoryPageHost> createState() => _LogHistoryPageHostState();
}

class _LogHistoryPageHostState extends State<_LogHistoryPageHost>
    with LogUiDelegateMixin, RouteAware {
  LogController get _controller => Get.find<LogController>();

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
    widget.refreshTrigger?.addListener(_onExternalRefresh);
  }

  bool _routeSubscriptionRegistered = false;

  void _onExternalRefresh() {
    if (!mounted) return;
    LogBinding(args: widget.args).dependencies();
    final controller = Get.find<LogController>();
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
    _controller.detachUi();
    super.dispose();
  }

  @override
  void didPopNext() {
    LogBinding(args: widget.args).dependencies();
    final controller = Get.find<LogController>();
    controller.attachUi(this);
    controller.reinitializeForHistoryTab();
  }

  @override
  Widget build(BuildContext context) {
    final history = _controller.historyArgs!;
    return GetBuilder<LogController>(
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
                      Expanded(child: _buildDashboardContainer(history, controller)),
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

  Widget _buildDashboardContainer(
    LogHistoryArgs history,
    LogController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: SingleChildScrollView(
        child: _buildDashboard(history, controller),
      ),
    );
  }

  Widget _buildDashboard(LogHistoryArgs history, LogController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
              SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BleNameUtils.getDisplayPrefixFromBleName(history.panelName),
                    style: StyleConstants.black16w700Style,
                  ),
                  Text(
                    BleNameUtils.getDisplayIdFromBleName(history.panelName),
                    style: StyleConstants.textDisabled14w500Style,
                  ),
                  ValueListenableBuilder(
                    valueListenable:
                        controller.bleManager.isConnectedNotifier,
                    builder: (context, isConnected, child) {
                      return Text(
                        isConnected
                            ? StringConstants.connected
                            : StringConstants.disconnected,
                        style: StyleConstants.primary14w500Style.copyWith(
                          color:
                              isConnected
                                  ? ColorConstants.success
                                  : ColorConstants.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
            thickness: 1,
          ),
          SizedBox(height: 10),
          _buildLogHistorySection(controller),
        ],
      ),
    );
  }

  Widget _buildLogHistorySection(LogController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.logRetrievalHistory,
          style: StyleConstants.textDark16w700Style,
        ),
        SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height - 350,
          child:
              controller.isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primary,
                    ),
                  )
                  : controller.logRetrievals.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: ColorConstants.borderGray,
                        ),
                        SizedBox(height: 16),
                        Text(
                          StringConstants.noLogHistory,
                          style: StyleConstants.textGray18w600Style,
                        ),
                        SizedBox(height: 8),
                        Text(
                          UiStrings.logRetrievalsEmptyHintMessage,
                          textAlign: TextAlign.center,
                          style: StyleConstants.textPlaceholder14w400Style,
                        ),
                      ],
                    ),
                  )
                  : ListView.separated(
                    itemCount: controller.logRetrievals.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final logRetrieval = controller.logRetrievals[index];
                      return _buildLogRetrievalItem(
                        logRetrieval,
                        controller,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildLogRetrievalItem(
    LogRetrievalModel logRetrieval,
    LogController controller,
  ) {
    final DateTime dateRetrieved = logRetrieval.retrievalDate;
    final String formattedDate =
        "${dateRetrieved.day.toString().padLeft(2, '0')}/${dateRetrieved.month.toString().padLeft(2, '0')}/${dateRetrieved.year} - ${dateRetrieved.hour.toString().padLeft(2, '0')}:${dateRetrieved.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () => controller.openLogSession(logRetrieval),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.surfaceCard),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorConstants.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                color: ColorConstants.danger,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logRetrieval.sessionName,
                    style: StyleConstants.blackMaterial14w700Style,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log Records : ${logRetrieval.logCount}',
                    style: StyleConstants.textSecondary12w400Style,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Date Retrieved : $formattedDate',
                    style: StyleConstants.textMediumGray12w400Style,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
