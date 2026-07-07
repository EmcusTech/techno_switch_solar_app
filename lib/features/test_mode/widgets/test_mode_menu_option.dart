import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/test_mode/models/test_mode_menu_item.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class TestModeMenuOption extends StatelessWidget {
  const TestModeMenuOption({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TestModeMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.borderGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item.iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      ColorConstants.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(item.title, style: StyleConstants.textDark16w600Style),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ColorConstants.textDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
