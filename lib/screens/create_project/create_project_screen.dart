import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  late TextEditingController _panelNameController;
  int currentStep = 1;
  final int totalSteps = 8;

  @override
  void initState() {
    _panelNameController = TextEditingController();
    super.initState();
  }

  void _goToNextStep() {
    if (currentStep < totalSteps) {
      setState(() {
        currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
      });
    }
  }

  Widget _getPageContent() {
    switch (currentStep) {
      case 1:
        return Column(
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
                controller: _panelNameController,
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
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Configuration',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Enter your text content here for page 2',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Enter text content...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Configuration',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Configure your devices for page 3',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Setup network configuration for page 4',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Configure security options for page 5',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Advanced configuration options for page 6',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Confirm',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Review your configuration for page 7',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Final Setup',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Complete the final setup for page 8',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF696969),
              ),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/arrow_back_icon.svg',
                        ),
                      ),
                      SizedBox(width: 17),
                      Text(
                        'Create Project',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Step',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFEC1D24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 7,
                            right: 6,
                            top: 2,
                            bottom: 3,
                          ),
                          child: Text(
                            '$currentStep/$totalSteps',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 19,
                          right: 19,
                          top: 22,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _getPageContent()),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Opacity(
                                  opacity: currentStep == 1 ? 0.2 : 1.0,
                                  child: GestureDetector(
                                    onTap: _goToPreviousStep,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEFEEEE),
                                        borderRadius: BorderRadius.circular(28.5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 34,
                                          top: 18,
                                          bottom: 18,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_back,
                                              color: Color(0xFF49454F),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Back',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF49454F),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: _goToNextStep,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFEC1D24),
                                      borderRadius: BorderRadius.circular(28.5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 28,
                                        right: 23,
                                        top: 18,
                                        bottom: 18,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Next',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
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
              color: panelCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 14,
              child: Text(
                panelCount,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color:
                      panelCount == '0' ? Color(0xFFBDBDBD) : Color(0xFFEC1D24),
                ),
              ),
            ),
            SizedBox(width: 6),
            SvgPicture.asset(
              'assets/svgs/panel_type_icon_2.svg',
              color:
                  panelAlarmCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 14,
              child: Text(
                panelAlarmCount,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color:
                      panelAlarmCount == '0'
                          ? Color(0xFFBDBDBD)
                          : Color(0xFFEC1D24),
                ),
              ),
            ),
            SizedBox(width: 6),
            SvgPicture.asset(
              'assets/svgs/panel_type_icon_3.svg',
              color:
                  panelConnectionCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 14,
              child: Text(
                panelConnectionCount,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color:
                      panelConnectionCount == '0'
                          ? Color(0xFFBDBDBD)
                          : Color(0xFFEC1D24),
                ),
              ),
            ),
            SizedBox(width: 6),
            SvgPicture.asset(
              'assets/svgs/panel_type_icon_4.svg',
              color:
                  panelFireExtinguisherCount == '0'
                      ? Color(0xFFBDBDBD)
                      : Color(0xFFEC1D24),
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
    );
  }

  @override
  void dispose() {
    _panelNameController.dispose();
    super.dispose();
  }
}
