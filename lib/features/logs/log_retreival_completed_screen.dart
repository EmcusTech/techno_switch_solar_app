import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/features/logs/event_log_screen.dart';
import 'package:techno_switch_solar_app/features/sites/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/site_creation_dialog.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalCompletedScreen extends StatefulWidget {
  final List<LogModel> logs;
  final String panelId;
  final String panelName;
  final DiscoveredDevice? connectedDevice;
  final bool? isDirectLogRet;
  const LogRetrievalCompletedScreen({
    super.key,
    required this.logs,
    required this.panelId,
    required this.panelName,
    this.connectedDevice,
    this.isDirectLogRet = false,
  });

  @override
  State<LogRetrievalCompletedScreen> createState() =>
      _LogRetrievalCompletedScreenState();
}

class _LogRetrievalCompletedScreenState
    extends State<LogRetrievalCompletedScreen> {
  final BleManager ble = Get.find<BleManager>();
  bool _isHandlingBack = false;
  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        await _handleBackNavigation();
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
                              await _handleBackNavigation();
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

  String _resolvedPanelName() {
    return widget.panelName.trim();
  }

  String _panelDisplayName(String name) {
    return BleNameUtils.getDisplayPrefixFromBleName(name);
  }

  String _resolvedPanelId() {
    if (widget.panelId.isNotEmpty) return widget.panelId;
    return widget.panelName;
  }

  Future<void> _handleBackNavigation() async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      final bleManager = ble;
      final logs = bleManager.bleProcess.validEventLogs.value;
      final panelIdToUse = _resolvedPanelId();
      if (logs.isEmpty) {
        await NavigationService.navigateBackToScanning(context);
        return;
      }

      if (logs.isNotEmpty) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToUse,
        );
        if (existingPanel != null && existingPanel.siteId != null) {
          final existingSite = await _siteService.getSiteById(
            existingPanel.siteId!,
          );
          if (existingSite != null) {
            await _siteService.storeLogs(logs, siteId: existingSite.id!);

            if (mounted) {
              await NavigationService.navigateBackToScanning(context);
            }

            return;
          }
        }

        bool? shouldCreateSite = false;

        if (mounted) {
          shouldCreateSite = await showSiteCreationDialog(
            context,
            logCount: logs.length,
          );
        }
        final resolvedName = _resolvedPanelName();
        final displayName = _panelDisplayName(resolvedName);
        final resolvedPanelId = _resolvedPanelId();

        if (shouldCreateSite == true) {
          if (widget.connectedDevice != null) {
            await widget.connectedDevice!.device!.disconnect();
          }
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => SimpleSiteCreationScreen(
                      retrievedLogs: logs,
                      panelName: displayName,
                      panelVersionNo: '',
                      panelId: resolvedPanelId,
                    ),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        await NavigationService.navigateBackToScanning(context);
      }
    } finally {
      _isHandlingBack = false;
    }
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
                        await _handleBackNavigation();
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
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => EventLogScreen(
                                  logDataList: widget.logs,
                                  panelName: widget.panelName,
                                  panelVersionNo: StringConstants.s098,
                                  isStandalone: true,
                                  panelId: widget.panelId,
                                  connectedDevice: widget.connectedDevice,
                                  isDirectLogRet: widget.isDirectLogRet,
                                ),
                          ),
                        );
                      },
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
