import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeQuickLinkItem extends StatelessWidget {
  const HomeQuickLinkItem({
    super.key,
    required this.imagePath,
    required this.label,
    this.isEnabled = true,
    this.onTap,
  });

  final String imagePath;
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? ColorConstants.transparent
                    : Colors.grey.shade200,
            border: Border.all(
              color:
                  isEnabled
                      ? ColorConstants.primary.withValues(alpha: 0.31)
                      : Colors.grey.shade200,
            ),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: SvgPicture.asset(
              imagePath,
              colorFilter:
                  isEnabled
                      ? null
                      : ColorFilter.mode(
                        ColorConstants.primary.withValues(alpha: 0.31),
                        BlendMode.srcIn,
                      ),
            ),
          ),
        ),
        const SizedBox(height: 11),
        Text(label, style: StyleConstants.textDark11w400Style),
      ],
    );

    if (!isEnabled || onTap == null) {
      return child;
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}
