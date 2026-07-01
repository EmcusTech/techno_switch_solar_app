import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class PanelSelectionPage extends GetView<CreateProjectController> {
  const PanelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateProjectController>(
      builder:
          (c) => Padding(
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
                                style: StyleConstants.primary13w600Style
                                    .copyWith(
                                      color:
                                          c.validationErrors.containsKey(
                                                StringConstants.panelname,
                                              )
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
                                  c.validationErrors.containsKey(
                                        StringConstants.panelname,
                                      )
                                      ? ColorConstants.primary
                                      : ColorConstants.borderGray,
                              width:
                                  c.validationErrors.containsKey(
                                        StringConstants.panelname,
                                      )
                                      ? 2
                                      : 1,
                            ),
                          ),
                          child: TextField(
                            controller: c.panelNameController,
                            textInputAction: TextInputAction.done,
                            onSubmitted:
                                (_) => FocusScope.of(context).unfocus(),
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
                        if (c.validationErrors.containsKey(
                          StringConstants.panelname,
                        )) ...[
                          SizedBox(height: 4),
                          Text(
                            c.validationErrors[StringConstants.panelname]!,
                            style: StyleConstants.primary12w500Style,
                          ),
                        ],
                        SizedBox(height: 36),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: StringConstants.panelType,
                                style: StyleConstants.primary13w600Style
                                    .copyWith(
                                      color:
                                          c.validationErrors.containsKey(
                                                StringConstants.paneltype,
                                              )
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
                        if (c.validationErrors.containsKey(
                          StringConstants.paneltype,
                        )) ...[
                          SizedBox(height: 4),
                          Text(
                            c.validationErrors[StringConstants.paneltype]!,
                            style: StyleConstants.primary12w500Style,
                          ),
                        ],
                        SizedBox(height: 18),
                        _buildPanelTypeTiles(c),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPanelTypeTiles(CreateProjectController c) {
    return Column(
      children:
          PanelTypeConfig.availablePanels.map((panelConfig) {
            return Column(
              children: [
                _buildPanelTypeTile(
                  c: c,
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
    required CreateProjectController c,
    required String title,
    required String zoneCount,
    required String sounderCount,
    required String relaysCount,
    required String panelFireExtinguisherCount,
  }) {
    return GestureDetector(
      onTap: () {
        c.updatePanelType(title);
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
                groupValue: c.panelData.selectedPanelType,
                onChanged: (value) {
                  c.updatePanelType(value);
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
