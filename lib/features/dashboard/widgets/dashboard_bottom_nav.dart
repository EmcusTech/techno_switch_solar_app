import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key, required this.controller});

  final ProjectDashboardController controller;

  static const _disabledIndexes = {1, 2};

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
          backgroundColor: ColorConstants.primary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: controller.selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            if (_disabledIndexes.contains(index)) return;
            controller.setSelectedIndex(index);
          },
          items: [
            _item(
              index: 0,
              label: StringConstants.dashboard,
              asset: AssetConstants.dashboardIcon,
            ),
            _item(
              index: 1,
              label: StringConstants.settings,
              asset: AssetConstants.settingIcon,
            ),
            _item(
              index: 2,
              label: StringConstants.testMode,
              asset: AssetConstants.testModeIcon,
            ),
            _item(
              index: 3,
              label: StringConstants.logHistory,
              asset: AssetConstants.logHistoryIcon,
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
    final isDisabled = _disabledIndexes.contains(index);
    final isSelected = controller.selectedIndex == index;
    final color =
        isDisabled
            ? Colors.grey
            : isSelected
            ? ColorConstants.white
            : ColorConstants.blackMaterial;

    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset,
            height: 24,
            width: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: StyleConstants.black12w400Style.copyWith(color: color),
          ),
        ],
      ),
      label: '',
    );
  }
}
