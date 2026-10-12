import 'package:Technoswitch/ble/demo/demo_ble.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/utils/site_service.dart';
import 'package:Technoswitch/widgets/dialogs/app_styled_dialogs.dart';
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
  int _selectedIndex = 0;
  final List<String> _panelNames = ['Technoswitch'];

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

  static const double _expandedWidth = 180;
  static const double _folderSize = 24;
  static const double _cardTop = 20;
  static const double _cardHeight = 40;
  static const double _cardGap = 12;
  static const double _cardWidth = _expandedWidth - 50;
  static const double _cardLeft = (_expandedWidth - 24) - _cardWidth;

  Future<void> _addPanel() async {
    if (!DemoBle.enabled) return;
    final name = await showAppStyledTextInputDialog(
      context: context,
      title: StringConstants.addPanel,
      message: StringConstants.enterPanelName,
      hintText: StringConstants.panelName,
      confirmLabel: StringConstants.add,
      validator: (value) {
        if (value.trim().isEmpty) return StringConstants.panelNameRequired;
        return null;
      },
    );
    if (!mounted || name == null || name.trim().isEmpty) return;
    setState(() {
      _panelNames.add(name.trim());
      _selectedIndex = _panelNames.length - 1;
    });
    _publishSelection();
  }

  void _selectPanel(int index) {
    setState(() => _selectedIndex = index);
    _publishSelection();
  }

  void _publishSelection() {
    widget.controller.selectedDemoPanelName.value = _panelNames[_selectedIndex];
  }

  double _panelListHeight(int count) {
    if (count == 0) return 0;
    return _cardTop + count * _cardHeight + (count - 1) * _cardGap;
  }

  Widget _panelList() {
    final count = _panelNames.length;
    return SizedBox(
      height: _panelListHeight(count + 20),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _FolderElbowPainter(
              folderCenterX: _folderSize / 2,
              elbowYs: [
                for (var i = 0; i < count; i++)
                  _cardTop + i * (_cardHeight + _cardGap) + _cardHeight / 2,
              ],
              cardLeft: _cardLeft,
            ),
          ),
          for (var i = 0; i < count; i++)
            Positioned(
              top: _cardTop + i * (_cardHeight + _cardGap),
              right: 0,
              child: _panelCard(i),
            ),
        ],
      ),
    );
  }

  Widget _panelCard(int index) {
    final selected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _selectPanel(index),
      child: Container(
        width: _cardWidth,
        decoration: BoxDecoration(
          color: ColorConstants.blueTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected ? ColorConstants.primary : ColorConstants.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SvgPicture.asset(AssetConstants.panelIcon, height: 24, width: 24),
              const SizedBox(width: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _panelNames[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: StyleConstants.black12w400Style,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addPanelButton({required bool compact}) {
    final enabled = DemoBle.enabled;
    final background =
        enabled ? ColorConstants.primary : ColorConstants.surfaceMuted;
    final foreground =
        enabled ? ColorConstants.white : ColorConstants.textSubtle;
    return InkWell(
      onTap: enabled ? _addPanel : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 8,
            vertical: 8,
          ),
          child:
              compact
                  ? Text(
                    StringConstants.add,
                    style: StyleConstants.white12w400Style.copyWith(
                      color: foreground,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: foreground, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          StringConstants.addPanel,
                          style: StyleConstants.white12w400Style.copyWith(
                            color: foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

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
              Expanded(
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

          Expanded(child: SingleChildScrollView(child: _panelList())),
          _addPanelButton(compact: false),
        ],
      ),
    );
  }

  Widget _collapsedPanelIcon(int index) {
    final selected = index == _selectedIndex;
    return InkWell(
      onTap: () => _selectPanel(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            AssetConstants.winPanelIcon,
            color: selected ? null : Colors.grey.withValues(alpha: 0.2),
          ),
          SvgPicture.asset(AssetConstants.panelIcon, height: 36, width: 36),
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
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _panelNames.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _collapsedPanelIcon(index),
          ),
        ),
        _addPanelButton(compact: true),
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
    required this.elbowYs,
    required this.cardLeft,
  });

  final double folderCenterX;
  final List<double> elbowYs;
  final double cardLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = ColorConstants.borderLight
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    for (final elbowY in elbowYs) {
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
        oldDelegate.cardLeft != cardLeft ||
        oldDelegate.elbowYs.length != elbowYs.length ||
        oldDelegate.elbowYs.any((y) => !elbowYs.contains(y));
  }
}
