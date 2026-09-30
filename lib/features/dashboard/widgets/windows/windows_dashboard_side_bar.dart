import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:flutter_svg/svg.dart';

class WindowsDashboardSideBar extends StatefulWidget {
  const WindowsDashboardSideBar({super.key});

  static const double collapsedWidth = 80;

  @override
  State<WindowsDashboardSideBar> createState() =>
      _WindowsDashboardSideBarState();
}

class _WindowsDashboardSideBarState extends State<WindowsDashboardSideBar> {
  bool _expanded = false;

  static const double _expandedWidth = 160;

  Widget _expandedItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetConstants.winFolderIcon),
              SizedBox(width: 4),
              Text("hey"),
              Spacer(),
              InkWell(
                onTap: () => setState(() => _expanded = false),
                child: SvgPicture.asset(AssetConstants.winSidePanelCloseIcon),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Align(
              alignment: Alignment.centerRight,
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
                    ],
                  ),
                ),
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
        ],
      ),
    );
  }
}
