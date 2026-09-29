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
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: WindowsDashboardPanelHeader(controller: controller),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Padding(
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
                              tiles: WindowsDashboardTileRegistry.overviewTiles(
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
                  ),
                  Expanded(
                    flex: 2,
                    child: WindowsDashboardDetailPane(controller: controller),
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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: ColorConstants.borderLight)),
      ),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute:
            (_) => MaterialPageRoute<void>(
              builder:
                  (_) => ColoredBox(
                    color: ColorConstants.white,
                    child: Center(
                      child: Text(
                        'Please select a module to view',
                        textAlign: TextAlign.center,
                        style: StyleConstants.textMuted14w400Style,
                      ),
                    ),
                  ),
            ),
      ),
    );
  }
}
