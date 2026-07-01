import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class PanelSelectionPage extends StatefulWidget {
  final String? selectedPanelType;
  final TextEditingController panelNameController;
  final Function(String?) onPanelTypeChanged;
  final Map<String, String>? validationErrors;

  const PanelSelectionPage({
    super.key,
    required this.selectedPanelType,
    required this.panelNameController,
    required this.onPanelTypeChanged,
    this.validationErrors,
  });

  @override
  State<PanelSelectionPage> createState() => _PanelSelectionPageState();
}

class _PanelSelectionPageState extends State<PanelSelectionPage> {
  @override
  Widget build(BuildContext context) {
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
                                widget.validationErrors?.containsKey(
                                          StringConstants.panelname,
                                        ) ==
                                        true
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
                            widget.validationErrors?.containsKey(
                                      StringConstants.panelname,
                                    ) ==
                                    true
                                ? ColorConstants.primary
                                : ColorConstants.borderGray,
                        width:
                            widget.validationErrors?.containsKey(
                                      StringConstants.panelname,
                                    ) ==
                                    true
                                ? 2
                                : 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.panelNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      onTapOutside: (value) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: StringConstants.enterPanelName,
                        hintStyle: StyleConstants.divider13w400Style,
                      ),
                    ),
                  ),
                  if (widget.validationErrors?.containsKey(
                        StringConstants.panelname,
                      ) ==
                      true) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.validationErrors![StringConstants.panelname]!,
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
                                widget.validationErrors?.containsKey(
                                          StringConstants.paneltype,
                                        ) ==
                                        true
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
                  if (widget.validationErrors?.containsKey(
                        StringConstants.paneltype,
                      ) ==
                      true) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.validationErrors![StringConstants.paneltype]!,
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

  Widget _buildPanelTypeTiles() {
    return Column(
      children:
          PanelTypeConfig.availablePanels.map((panelConfig) {
            return Column(
              children: [
                _buildPanelTypeTile(
                  title: panelConfig.typeName,
                  zoneCount: panelConfig.zoneCount.toString(),
                  sounderCount: panelConfig.sounderCount.toString(),
                  relaysCount: panelConfig.relayCount.toString(),
                  panelFireExtinguisherCount:
                      panelConfig.fireExtinguisherCount.toString(),
                ),
                if (panelConfig != PanelTypeConfig.availablePanels.last)
                  SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildPanelTypeTile({
    required String title,
    required String zoneCount,
    required String sounderCount,
    required String relaysCount,
    required String panelFireExtinguisherCount,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onPanelTypeChanged(title);
      },
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
                value: title,
                groupValue: widget.selectedPanelType,
                onChanged: (value) {
                  widget.onPanelTypeChanged(value);
                },
                activeColor: ColorConstants.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 8),
              Text(title, style: StyleConstants.textDark13w400Style),
              Spacer(),
              SvgPicture.asset(
                AssetConstants.panelTypeIcon1,
                colorFilter: ColorFilter.mode(
                  zoneCount == '0'
                      ? ColorConstants.divider
                      : ColorConstants.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  zoneCount,
                  style: StyleConstants.divider13w400Style.copyWith(
                    color:
                        zoneCount == '0'
                            ? ColorConstants.divider
                            : ColorConstants.primary,
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                AssetConstants.panelTypeIcon2,
                colorFilter: ColorFilter.mode(
                  sounderCount == '0'
                      ? ColorConstants.divider
                      : ColorConstants.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  sounderCount,
                  style: StyleConstants.divider13w400Style.copyWith(
                    color:
                        sounderCount == '0'
                            ? ColorConstants.divider
                            : ColorConstants.primary,
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                AssetConstants.panelTypeIcon3,
                colorFilter: ColorFilter.mode(
                  relaysCount == '0'
                      ? ColorConstants.divider
                      : ColorConstants.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  relaysCount,
                  style: StyleConstants.divider13w400Style.copyWith(
                    color:
                        relaysCount == '0'
                            ? ColorConstants.divider
                            : ColorConstants.primary,
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                AssetConstants.panelTypeIcon4,
                colorFilter: ColorFilter.mode(
                  panelFireExtinguisherCount == '0'
                      ? ColorConstants.divider
                      : ColorConstants.primary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  panelFireExtinguisherCount,
                  style: StyleConstants.divider13w400Style.copyWith(
                    color:
                        panelFireExtinguisherCount == '0'
                            ? ColorConstants.divider
                            : ColorConstants.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
