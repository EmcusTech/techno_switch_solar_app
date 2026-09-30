import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/site_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

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

class _WindowsDashboardAppBarState extends State<WindowsDashboardAppBar> {
  String _siteName = '';

  @override
  void initState() {
    super.initState();
    _siteName = widget.controller.siteName?.trim() ?? '';
    _loadSiteName();
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
              SizedBox(width: 40),
              Text(StringConstants.fullScreen),
              SizedBox(width: 12),
              SvgPicture.asset(AssetConstants.winFullScreenIcon),
            ],
          ),
        ),
      ),
    );
  }
}
