import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteDetailField extends StatelessWidget {
  const SiteDetailField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static String displayValue(String raw) => raw.isNotEmpty ? raw : '-';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StyleConstants.textMediumGray13w700Style),
        const SizedBox(height: 4),
        Text(value, style: StyleConstants.textBodyDark20w700Style),
        const SizedBox(height: 24),
      ],
    );
  }
}

List<({String label, String Function(SiteModel site) value})>
siteDetailFields({
  required String siteNameLabel,
  required String installerNameLabel,
  required String companyNameLabel,
  required String saqccRegNumberLabel,
  required String buildingNameLabel,
  required String installerContactNumberLabel,
  required String installerEmailLabel,
  required String siteDescriptionLabel,
}) {
  return [
    (label: siteNameLabel, value: (site) => site.siteName),
    (
      label: installerNameLabel,
      value: (site) => SiteDetailField.displayValue(site.installerName),
    ),
    (
      label: companyNameLabel,
      value: (site) => SiteDetailField.displayValue(site.companyName),
    ),
    (
      label: saqccRegNumberLabel,
      value: (site) => SiteDetailField.displayValue(site.saqccRegNumber),
    ),
    (
      label: buildingNameLabel,
      value: (site) => SiteDetailField.displayValue(site.buildingName),
    ),
    (
      label: installerContactNumberLabel,
      value:
          (site) => SiteDetailField.displayValue(site.installerContactNumber),
    ),
    (
      label: installerEmailLabel,
      value: (site) => SiteDetailField.displayValue(site.installerEmail),
    ),
    (
      label: siteDescriptionLabel,
      value: (site) => SiteDetailField.displayValue(site.siteDescription),
    ),
  ];
}
