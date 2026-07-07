import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BottomNavigationBar(
          iconSize: 24,
          currentIndex: controller.selectedIndex,
          selectedItemColor: ColorConstants.white,
          unselectedItemColor: Colors.grey,
          onTap: controller.setSelectedIndex,
          backgroundColor: ColorConstants.primary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: StyleConstants.black12w600Style,
          unselectedLabelStyle: StyleConstants.black12w500Style,
          items: [
            _item(
              index: 0,
              label: StringConstants.home,
              asset: AssetConstants.homeIcon,
            ),
            _item(
              index: 1,
              label: StringConstants.settings,
              asset: AssetConstants.settingIcon,
            ),
            _item(
              index: 2,
              label: StringConstants.help,
              asset: AssetConstants.helpIcon,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _item({
    required int index,
    required String label,
    required String asset,
  }) {
    final isSelected = controller.selectedIndex == index;
    final color =
        isSelected ? ColorConstants.white : Colors.grey;

    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        asset,
        height: 24,
        width: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      label: label,
    );
  }
}
