import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteDetailScreen extends StatelessWidget {
  final SiteWithLogCount siteWithLogCount;
  const SiteDetailScreen({super.key, required this.siteWithLogCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.blackMaterial.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: ColorConstants.textDark,
                            size: 18,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        StringConstants.siteDetails,
                        style: StyleConstants.black20w700Style,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 35,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Site Name",
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.siteName,
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.installerName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.installerName.isNotEmpty
                                ? siteWithLogCount.site.installerName
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.companyName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.companyName.isNotEmpty
                                ? siteWithLogCount.site.companyName
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.saqccRegistrationNumber,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.saqccRegNumber.isNotEmpty
                                ? siteWithLogCount.site.saqccRegNumber
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.buildingName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.buildingName.isNotEmpty
                                ? siteWithLogCount.site.buildingName
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.installerContactNumber,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount
                                    .site
                                    .installerContactNumber
                                    .isNotEmpty
                                ? siteWithLogCount.site.installerContactNumber
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.installerEmail,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.installerEmail.isNotEmpty
                                ? siteWithLogCount.site.installerEmail
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          SizedBox(height: 24),
                          Text(
                            StringConstants.siteDescription,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          SizedBox(height: 4),
                          Text(
                            siteWithLogCount.site.siteDescription.isNotEmpty
                                ? siteWithLogCount.site.siteDescription
                                : '-',
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
