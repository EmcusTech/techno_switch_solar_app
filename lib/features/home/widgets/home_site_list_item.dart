import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

class HomeSiteListItem extends StatelessWidget {
  const HomeSiteListItem({
    super.key,
    required this.controller,
    required this.siteWithLogCount,
    required this.onTap,
  });

  final HomeScreenController controller;
  final SiteWithLogCount siteWithLogCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final site = siteWithLogCount.site;
    final displayDate = controller.siteSummaryDate(siteWithLogCount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          border: Border.all(
            color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Image.asset(
                AssetConstants.panelIconImage,
                height: 62,
                width: 62,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteName,
                      style: StyleConstants.textDark16w700Style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${DateFormat('MMM d').format(displayDate)}, '
                        '${DateFormat('yyyy').format(displayDate)} • '
                        '${DateFormat('hh:mm a').format(displayDate)}',
                        style: StyleConstants.textMuted11w400Style,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ColorConstants.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
