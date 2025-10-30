import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';

class PanelSelectionPage extends StatefulWidget {
  final String? selectedPanelType;
  final TextEditingController panelNameController;
  final Function(String?) onPanelTypeChanged;

  const PanelSelectionPage({
    super.key,
    required this.selectedPanelType,
    required this.panelNameController,
    required this.onPanelTypeChanged,
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
            'Panel Selection',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel Name',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF696969),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: TextField(
                      controller: widget.panelNameController,
                      onTapOutside: (value) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                        hintText: 'Enter Panel Name',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 36),
                  Text(
                    'Panel Type',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF696969),
                    ),
                  ),
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
                if (panelConfig !=
                    PanelTypeConfig
                        .availablePanels
                        .last) // Don't add spacing after last item
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
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
                activeColor: Color(0xFFEC1D24),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              Spacer(),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_1.svg',
                colorFilter: ColorFilter.mode(
                  zoneCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  zoneCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        zoneCount == '0'
                            ? Color(0xFFBDBDBD)
                            : Color(0xFFEC1D24),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_2.svg',
                colorFilter: ColorFilter.mode(
                  sounderCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  sounderCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        sounderCount == '0'
                            ? Color(0xFFBDBDBD)
                            : Color(0xFFEC1D24),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_3.svg',
                colorFilter: ColorFilter.mode(
                  relaysCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  relaysCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        relaysCount == '0'
                            ? Color(0xFFBDBDBD)
                            : Color(0xFFEC1D24),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_4.svg',
                colorFilter: ColorFilter.mode(
                  panelFireExtinguisherCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  panelFireExtinguisherCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        panelFireExtinguisherCount == '0'
                            ? Color(0xFFBDBDBD)
                            : Color(0xFFEC1D24),
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
