import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/site_service.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:flutter_svg/svg.dart';

class WindowsDashboardSideBar extends StatefulWidget {
  const WindowsDashboardSideBar({super.key, required this.controller});

  final ProjectDashboardController controller;

  static const double collapsedWidth = 80;

  @override
  State<WindowsDashboardSideBar> createState() =>
      _WindowsDashboardSideBarState();
}

class _WindowsDashboardSideBarState extends State<WindowsDashboardSideBar> {
  bool _expanded = false;
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

  static const double _expandedWidth = 160;
  static const double _folderSize = 24;
  static const double _cardTop = 20;
  static const double _cardHeight = 40;

  Widget _expandedItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetConstants.winFolderIcon),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _siteName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _expanded = false),
                child: SvgPicture.asset(AssetConstants.winSidePanelCloseIcon),
              ),
            ],
          ),

          SizedBox(
            height: _cardTop + _cardHeight,
            child: Stack(
              children: [
                const CustomPaint(
                  size: Size.infinite,
                  painter: _FolderElbowPainter(
                    folderCenterX: _folderSize / 2,
                    elbowY: _cardTop + _cardHeight / 2,
                    cardLeft: (_expandedWidth - 24) - (_expandedWidth - 50),
                  ),
                ),
                Positioned(
                  top: _cardTop,
                  right: 0,
                  child: Container(
                    width: _expandedWidth - 50,
                    decoration: BoxDecoration(
                      color: ColorConstants.blueTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AssetConstants.panelIcon,
                            height: 24,
                            width: 24,
                          ),
                          Spacer(),
                          Text(
                            "Panel 1",
                            style: StyleConstants.black12w400Style,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: ColorConstants.white, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      StringConstants.addPanel,
                      style: StyleConstants.white12w400Style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collapsedItems() {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = true),
          child: SvgPicture.asset(AssetConstants.winFolderIcon),
        ),
        SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(AssetConstants.winPanelIcon),
            SvgPicture.asset(AssetConstants.panelIcon, height: 36, width: 36),
          ],
        ),
        Spacer(),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Text(
              StringConstants.add,
              style: StyleConstants.white12w400Style,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width:
          _expanded ? _expandedWidth : WindowsDashboardSideBar.collapsedWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: ColorConstants.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: IconButton(
          //     onPressed: () => setState(() => _expanded = !_expanded),
          //     icon: Icon(
          //       _expanded ? Icons.chevron_left : Icons.chevron_right,
          //       color: ColorConstants.textDark,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 12),
          Expanded(child: _expanded ? _expandedItems() : _collapsedItems()),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FolderElbowPainter extends CustomPainter {
  const _FolderElbowPainter({
    required this.folderCenterX,
    required this.elbowY,
    required this.cardLeft,
  });

  final double folderCenterX;
  final double elbowY;
  final double cardLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = ColorConstants.borderLight
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    _dash(
      canvas,
      Offset(folderCenterX, 0),
      Offset(folderCenterX, elbowY),
      paint,
    );
    _dash(
      canvas,
      Offset(folderCenterX, elbowY),
      Offset(cardLeft, elbowY),
      paint,
    );
  }

  void _dash(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final step = delta / length;
    var drawn = 0.0;
    while (drawn < length) {
      final dashEnd = (drawn + dash).clamp(0.0, length);
      canvas.drawLine(start + step * drawn, start + step * dashEnd, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _FolderElbowPainter oldDelegate) {
    return oldDelegate.folderCenterX != folderCenterX ||
        oldDelegate.elbowY != elbowY ||
        oldDelegate.cardLeft != cardLeft;
  }
}
