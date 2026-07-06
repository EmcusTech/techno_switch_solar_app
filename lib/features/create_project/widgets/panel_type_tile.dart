import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_selection_page_model.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class PanelTypeCountIcon extends StatelessWidget {
  const PanelTypeCountIcon({super.key, required this.asset, required this.count});

  final String asset;
  final String count;

  @override
  Widget build(BuildContext context) {
    final isZero = count == '0';
    final color = isZero ? ColorConstants.divider : ColorConstants.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 14,
          child: Text(
            count,
            style: StyleConstants.divider13w400Style.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class PanelTypeTile extends StatelessWidget {
  const PanelTypeTile({
    super.key,
    required this.option,
    required this.selectedPanelType,
    required this.onPanelTypeChanged,
  });

  final PanelTypeOption option;
  final String? selectedPanelType;
  final void Function(String?) onPanelTypeChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPanelTypeChanged(option.typeName),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ColorConstants.borderGray, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<String>(
                value: option.typeName,
                groupValue: selectedPanelType,
                onChanged: onPanelTypeChanged,
                activeColor: ColorConstants.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Text(option.typeName, style: StyleConstants.textDark13w400Style),
              const Spacer(),
              PanelTypeCountIcon(
                asset: AssetConstants.panelTypeIcon1,
                count: option.zoneCount.toString(),
              ),
              const SizedBox(width: 6),
              PanelTypeCountIcon(
                asset: AssetConstants.panelTypeIcon2,
                count: option.sounderCount.toString(),
              ),
              const SizedBox(width: 6),
              PanelTypeCountIcon(
                asset: AssetConstants.panelTypeIcon3,
                count: option.relayCount.toString(),
              ),
              const SizedBox(width: 6),
              PanelTypeCountIcon(
                asset: AssetConstants.panelTypeIcon4,
                count: option.fireExtinguisherCount.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
