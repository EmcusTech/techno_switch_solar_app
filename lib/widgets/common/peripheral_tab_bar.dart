import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

/// Tab row whose selected item is a filled primary card with white text.
///
/// [underline] is the earlier bar: a light track, primary text, and an
/// underline on the selected tab.
class PeripheralTabBar extends StatelessWidget {
  const PeripheralTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.underline = false,
    this.underlineWidth = 480,
  });

  final TabController controller;
  final List<Widget> tabs;
  final ValueChanged<int>? onTap;
  final bool underline;
  final double underlineWidth;

  static const BorderRadius _cardRadius = BorderRadius.only(
    topLeft: Radius.circular(8),
    topRight: Radius.circular(8),
  );

  @override
  Widget build(BuildContext context) {
    if (underline) return _underlineBar();
    return _cardBar();
  }

  Widget _cardBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: ColorConstants.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(color: ColorConstants.transparent),
        labelColor: ColorConstants.white,
        unselectedLabelColor: ColorConstants.textDark,
        labelStyle: StyleConstants.black13w600Style,
        unselectedLabelStyle: StyleConstants.black13w600Style,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(ColorConstants.transparent),
        tabs: [
          for (var i = 0; i < tabs.length; i++)
            _TabCard(controller: controller, index: i, child: tabs[i]),
        ],
      ),
    );
  }

  Widget _underlineBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: underlineWidth,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: ColorConstants.surfaceLight,
        ),
        child: TabBar(
          controller: controller,
          onTap: onTap,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: ColorConstants.transparent,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.5, color: ColorConstants.primary),
          ),
          labelColor: ColorConstants.primary,
          unselectedLabelColor: ColorConstants.textSubtle,
          labelStyle: StyleConstants.black13w600Style,
          unselectedLabelStyle: StyleConstants.black13w500Style,
          tabs: tabs,
        ),
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  const _TabCard({
    required this.controller,
    required this.index,
    required this.child,
  });

  final TabController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value =
            controller.animation?.value ?? controller.index.toDouble();
        final blend = (1 - (value - index).abs()).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              ColorConstants.colorFff0F0F0,
              ColorConstants.primary,
              blend,
            ),
            borderRadius: PeripheralTabBar._cardRadius,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}
