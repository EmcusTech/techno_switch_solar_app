import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';

class SiteSummaryCard extends StatelessWidget {
  const SiteSummaryCard({super.key, required this.controller});

  final SiteController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.errorTint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 15,
                bottom: 15,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(AssetConstants.locationIcon),
                          const SizedBox(width: 8),
                          Text(
                            controller.site.siteName,
                            style: StyleConstants.textBodyDark20boldStyle,
                          ),
                        ],
                      ),
                      Text(
                        StringConstants.siteInformation,
                        style: StyleConstants.textNeutral12w400Style,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.confirmDeleteSite,
                    child: SvgPicture.asset(
                      AssetConstants.deleteIcon,
                      colorFilter: const ColorFilter.mode(
                        ColorConstants.errorBright,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(AssetConstants.siteCalenderIcon),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringConstants.created,
                            style: StyleConstants.textNeutral12w400Style,
                          ),
                          Text(
                            DateFormat('MMM d, y').format(
                              controller.siteWithLogCount.site.createdAt,
                            ),
                            style: StyleConstants.textNeutral12w400Style,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CommonCtaButton(
                    onTap: controller.openSiteDetail,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(AssetConstants.detailsIcon),
                        const SizedBox(width: 8),
                        Text(
                          StringConstants.viewSiteDetails,
                          style: StyleConstants.white14w500Style,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
