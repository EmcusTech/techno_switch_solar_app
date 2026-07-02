import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_selection_page_model.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class PanelSelectionForm extends StatelessWidget {
  const PanelSelectionForm({super.key, required this.model});

  final PanelSelectionPageModel model;

  bool _hasError(String key) =>
      model.validationErrors?.containsKey(key) == true;

  String? _errorMessage(String key) => model.validationErrors?[key];

  Widget _buildPanelTypeTiles() {
    final panelTypes = model.panelTypes;
    return Column(
      children: [
        for (var i = 0; i < panelTypes.length; i++) ...[
          _buildPanelTypeTile(panelTypes[i]),
          if (i < panelTypes.length - 1) SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPanelTypeTile(PanelTypeOption option) {
    final zoneCount = option.zoneCount.toString();
    final sounderCount = option.sounderCount.toString();
    final relaysCount = option.relayCount.toString();
    final panelFireExtinguisherCount = option.fireExtinguisherCount.toString();

    return GestureDetector(
      onTap: () => model.onPanelTypeChanged(option.typeName),
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
                groupValue: model.selectedPanelType,
                onChanged: model.onPanelTypeChanged,
                activeColor: ColorConstants.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 8),
              Text(option.typeName, style: StyleConstants.textDark13w400Style),
              Spacer(),
              _buildCountIcon(AssetConstants.panelTypeIcon1, zoneCount),
              SizedBox(width: 6),
              _buildCountIcon(AssetConstants.panelTypeIcon2, sounderCount),
              SizedBox(width: 6),
              _buildCountIcon(AssetConstants.panelTypeIcon3, relaysCount),
              SizedBox(width: 6),
              _buildCountIcon(
                AssetConstants.panelTypeIcon4,
                panelFireExtinguisherCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountIcon(String asset, String count) {
    final isZero = count == '0';
    final color = isZero ? ColorConstants.divider : ColorConstants.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(width: 6),
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

  @override
  Widget build(BuildContext context) {
    final panelNameError = _hasError(StringConstants.panelname);
    final panelTypeError = _hasError(StringConstants.paneltype);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.panelSelection,
            style: StyleConstants.textBodyDark18w600Style,
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: StringConstants.panelName,
                          style: StyleConstants.primary13w600Style.copyWith(
                            color:
                                panelNameError
                                    ? ColorConstants.primary
                                    : ColorConstants.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: StringConstants.strb411bc68,
                          style: StyleConstants.primary13w600Style,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            panelNameError
                                ? ColorConstants.primary
                                : ColorConstants.borderGray,
                        width: panelNameError ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: model.panelNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted:
                          (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      onTapOutside: (value) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: StringConstants.enterPanelName,
                        hintStyle: StyleConstants.divider13w400Style,
                      ),
                    ),
                  ),
                  if (panelNameError &&
                      _errorMessage(StringConstants.panelname) != null) ...[
                    SizedBox(height: 4),
                    Text(
                      _errorMessage(StringConstants.panelname)!,
                      style: StyleConstants.primary12w500Style,
                    ),
                  ],
                  SizedBox(height: 36),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: StringConstants.panelType,
                          style: StyleConstants.primary13w600Style.copyWith(
                            color:
                                panelTypeError
                                    ? ColorConstants.primary
                                    : ColorConstants.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: StringConstants.strb411bc68,
                          style: StyleConstants.primary13w600Style,
                        ),
                      ],
                    ),
                  ),
                  if (panelTypeError &&
                      _errorMessage(StringConstants.paneltype) != null) ...[
                    SizedBox(height: 4),
                    Text(
                      _errorMessage(StringConstants.paneltype)!,
                      style: StyleConstants.primary12w500Style,
                    ),
                  ],
                  SizedBox(height: 18),
                  _buildPanelTypeTiles(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
