import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HelpActionRow extends StatelessWidget {
  const HelpActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.showChevron = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: ColorConstants.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StyleConstants.textDark16w500Style),
                Text(subtitle, style: StyleConstants.textGray14w400Style),
              ],
            ),
          ),
          if (showChevron)
            const Icon(Icons.chevron_right, color: ColorConstants.textDark),
        ],
      ),
    );
  }
}
