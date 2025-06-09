import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
      children: [
        _buildPanelTypeTile(
          title: 'ORYX202',
          panelCount: '0',
          panelAlarmCount: '2',
          panelConnectionCount: '2',
          panelFireExtinguisherCount: '0',
        ),
        SizedBox(height: 16),
        _buildPanelTypeTile(
          title: 'ORYX204',
          panelCount: '1',
          panelAlarmCount: '1',
          panelConnectionCount: '1',
          panelFireExtinguisherCount: '1',
        ),
        SizedBox(height: 16),
        _buildPanelTypeTile(
          title: 'ORYX208',
          panelCount: '1',
          panelAlarmCount: '1',
          panelConnectionCount: '1',
          panelFireExtinguisherCount: '1',
        ),
        SizedBox(height: 16),
        _buildPanelTypeTile(
          title: 'RHINO103',
          panelCount: '1',
          panelAlarmCount: '1',
          panelConnectionCount: '1',
          panelFireExtinguisherCount: '1',
        ),
        SizedBox(height: 16),
        _buildPanelTypeTile(
          title: 'RHINO203',
          panelCount: '1',
          panelAlarmCount: '1',
          panelConnectionCount: '1',
          panelFireExtinguisherCount: '1',
        ),
      ],
    );
  }

  Widget _buildPanelTypeTile({
    required String title,
    required String panelCount,
    required String panelAlarmCount,
    required String panelConnectionCount,
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
                  panelCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  panelCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: panelCount == '0'
                        ? Color(0xFFBDBDBD)
                        : Color(0xFFEC1D24),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_2.svg',
                colorFilter: ColorFilter.mode(
                  panelAlarmCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  panelAlarmCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: panelAlarmCount == '0'
                        ? Color(0xFFBDBDBD)
                        : Color(0xFFEC1D24),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SvgPicture.asset(
                'assets/svgs/panel_type_icon_3.svg',
                colorFilter: ColorFilter.mode(
                  panelConnectionCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: Text(
                  panelConnectionCount,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: panelConnectionCount == '0'
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
                    color: panelFireExtinguisherCount == '0'
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