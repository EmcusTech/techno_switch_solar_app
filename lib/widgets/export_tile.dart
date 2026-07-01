import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class ExportTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;

  const ExportTile({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SvgPicture.asset(iconPath),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: StyleConstants.textBodyDark16w600Style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
