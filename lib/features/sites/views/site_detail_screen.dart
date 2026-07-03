import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteDetailScreen extends GetView<SiteDetailController> {
  const SiteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SiteDetailPageHost(controller: controller);
  }
}

class _SiteDetailPageHost extends StatefulWidget {
  const _SiteDetailPageHost({required this.controller});

  final SiteDetailController controller;

  @override
  State<_SiteDetailPageHost> createState() => _SiteDetailPageHostState();
}

class _SiteDetailPageHostState extends State<_SiteDetailPageHost>
    implements SiteDetailUiDelegate {
  SiteDetailController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SiteDetailController>()) {
      Get.delete<SiteDetailController>();
    }
    super.dispose();
  }

  String _displayValue(String value) => value.isNotEmpty ? value : '-';

  @override
  Widget build(BuildContext context) {
    final site = _controller.siteWithLogCount.site;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                        onTap: _controller.popBack,
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
                      const SizedBox(width: 12),
                      Text(
                        StringConstants.siteDetails,
                        style: StyleConstants.black20w700Style,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                            StringConstants.siteName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            site.siteName,
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.installerName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.installerName),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.companyName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.companyName),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.saqccRegistrationNumber,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.saqccRegNumber),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.buildingName,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.buildingName),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.installerContactNumber,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.installerContactNumber),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.installerEmail,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.installerEmail),
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            StringConstants.siteDescription,
                            style: StyleConstants.textMediumGray13w700Style,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayValue(site.siteDescription),
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
