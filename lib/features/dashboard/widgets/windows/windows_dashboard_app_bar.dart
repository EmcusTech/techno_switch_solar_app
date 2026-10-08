import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/site_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/windows/windows_app_frame.dart';
import 'package:window_manager/window_manager.dart';

class WindowsDashboardAppBar extends StatefulWidget {
  const WindowsDashboardAppBar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onExport,
  });

  final ProjectDashboardController controller;
  final VoidCallback onBack;
  final VoidCallback onExport;

  @override
  State<WindowsDashboardAppBar> createState() => _WindowsDashboardAppBarState();
}

class _WindowsDashboardAppBarState extends State<WindowsDashboardAppBar>
    with WindowListener {
  String _siteName = '';
  bool _fullScreen = false;

  @override
  void initState() {
    super.initState();
    _siteName = widget.controller.siteName?.trim() ?? '';
    windowManager.addListener(this);
    _loadSiteName();
    _syncFullScreen();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _applyFullScreen(bool full) {
    windowsFullScreen.value = full;
    if (!mounted || full == _fullScreen) return;
    setState(() => _fullScreen = full);
  }

  Future<void> _syncFullScreen() async {
    final full = await windowManager.isFullScreen();
    _applyFullScreen(full);
  }

  @override
  void onWindowEnterFullScreen() {
    _applyFullScreen(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    _applyFullScreen(false);
  }

  Future<void> _toggleFullScreen() async {
    final next = !_fullScreen;
    await windowManager.setFullScreen(next);
    _applyFullScreen(next);
  }

  Future<void> _loadSiteName() async {
    final siteId = widget.controller.siteId;
    if (siteId == null) return;
    final site = await SiteService().getSiteById(siteId);
    if (!mounted || site == null) return;
    final name = site.siteName.trim();
    if (name.isEmpty || name == _siteName) return;
    setState(() => _siteName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                child: SvgPicture.asset(AssetConstants.winHomeicon),
              ),
              const SizedBox(width: 7),
              SvgPicture.asset(AssetConstants.winRightArrowIcon),
              const SizedBox(width: 7),
              Text(
                _siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleConstants.black14w400Style,
              ),
              Spacer(),
              // GestureDetector(
              //   onTap: widget.onExport,
              //   child: Padding(
              //     padding: const EdgeInsets.only(right: 12),
              //     child: SvgPicture.asset(AssetConstants.shareIcon),
              //   ),
              // ),
              Text(StringConstants.upload),
              SizedBox(width: 12),
              SvgPicture.asset(AssetConstants.winUploadIcon),
              SizedBox(width: 40),
              Text(StringConstants.download),
              SizedBox(width: 12),
              SvgPicture.asset(AssetConstants.winDownloadIcon),
              const SizedBox(width: 40),
              InkWell(
                onTap: _toggleFullScreen,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fullScreen
                          ? StringConstants.exitFullScreen
                          : StringConstants.fullScreen,
                    ),
                    const SizedBox(width: 12),
                    SvgPicture.asset(AssetConstants.winFullScreenIcon),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
