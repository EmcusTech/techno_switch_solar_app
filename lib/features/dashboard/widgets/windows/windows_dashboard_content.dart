import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_side_bar.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_access_code_pane.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_panel_header.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_tile_registry.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_peripheral_tile.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class WindowsDashboardContent extends StatelessWidget {
  const WindowsDashboardContent({super.key, required this.controller});

  final ProjectDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dividerWidth = 1.0;
              final tileWidth =
                  (constraints.maxWidth -
                      WindowsDashboardSideBar.collapsedWidth -
                      dividerWidth * 2) /
                  3;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WindowsDashboardSideBar(controller: controller),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: VerticalDivider(
                      width: dividerWidth,
                      thickness: 1,
                      color: ColorConstants.borderLight,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel Details',
                                style: StyleConstants.black16w700Style,
                              ),
                              const SizedBox(height: 8),
                              WindowsDashboardPanelHeader(
                                controller: controller,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StringConstants.peripheralOverview,
                                  style: StyleConstants.black16w700Style,
                                ),
                                const SizedBox(height: 8),
                                WindowsDashboardTileGrid(
                                  controller: controller,
                                  tiles:
                                      WindowsDashboardTileRegistry.overviewTiles(
                                        controller,
                                      ),
                                  heightFactor: 0.1,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  StringConstants.panelActions,
                                  style: StyleConstants.black16w700Style,
                                ),
                                const SizedBox(height: 8),
                                WindowsDashboardTileGrid(
                                  controller: controller,
                                  tiles:
                                      WindowsDashboardTileRegistry.panelActionTiles(
                                        controller,
                                      ),
                                  heightFactor: 0.15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: VerticalDivider(
                      width: dividerWidth,
                      thickness: 1,
                      color: ColorConstants.borderLight,
                    ),
                  ),
                  Expanded(
                    child: WindowsDashboardDetailPane(controller: controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class WindowsDashboardDetailPane extends StatefulWidget {
  const WindowsDashboardDetailPane({super.key, required this.controller});

  final ProjectDashboardController controller;

  @override
  State<WindowsDashboardDetailPane> createState() =>
      _WindowsDashboardDetailPaneState();
}

class _WindowsDashboardDetailPaneState
    extends State<WindowsDashboardDetailPane> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.controller.windowsDetail.addListener(_onDetailChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onDetailChanged();
    });
  }

  @override
  void dispose() {
    widget.controller.windowsDetail.removeListener(_onDetailChanged);
    super.dispose();
  }

  void _onDetailChanged() {
    final navigator = _navigatorKey.currentState;
    if (!mounted || navigator == null) return;

    final detail = widget.controller.windowsDetail.value;
    navigator.popUntil((route) => route.isFirst);
    if (detail == null) return;

    navigator
        .push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => ColoredBox(
                  color: ColorConstants.white,
                  child: detail.child,
                ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          if (widget.controller.windowsDetail.value == detail) {
            widget.controller.clearWindowsDetail();
          }
        });
  }

  bool _awaitingAccessCode(bool sessionReady) {
    return !sessionReady;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.ble.isConnectedNotifier,
      builder: (context, isConnected, _) {
        if (!isConnected) {
          return _paneMessage('Please connect with the panel to proceed');
        }
        return ValueListenableBuilder<bool>(
          valueListenable:
              widget.controller.bleController.bleProcess.sessionAccessCodeReady,
          builder: (context, sessionReady, _) {
            if (_awaitingAccessCode(sessionReady)) {
              return WindowsDashboardAccessCodePane(
                controller: widget.controller,
              );
            }
            return _detailNavigator();
          },
        );
      },
    );
  }

  Widget _paneMessage(String message) {
    return ColoredBox(
      color: ColorConstants.white,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: StyleConstants.textMuted14w400Style,
        ),
      ),
    );
  }

  Widget _detailNavigator() {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute:
          (_) => MaterialPageRoute<void>(
            builder: (_) => _paneMessage('Please select a module to view'),
          ),
    );
  }
}
