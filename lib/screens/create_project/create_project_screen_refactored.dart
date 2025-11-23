import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/site_creation_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/panel_selection_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/general_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/zone_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/sounder_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/sounder_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/input_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/relay_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/devices_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/project_summary_page.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';

/// Refactored CreateSiteScreen with clean architecture
/// - Uses a dedicated controller for state management
/// - Reduced complexity and code duplication
/// - Better separation of concerns
/// - Maintains same UI and functionality
class CreateSiteScreenRefactored extends StatefulWidget {
  const CreateSiteScreenRefactored({super.key});

  @override
  State<CreateSiteScreenRefactored> createState() =>
      _CreateSiteScreenRefactoredState();
}

class _CreateSiteScreenRefactoredState
    extends State<CreateSiteScreenRefactored> {
  late CreateProjectController _controller;
  late PageController _pageController;
  final SiteService _siteService = SiteService();

  int _currentStep = 1;
  static const int _totalSteps = 10;

  @override
  void initState() {
    super.initState();
    _controller = CreateProjectController();
    _pageController = PageController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _createSite() async {
    try {
      final errors = _siteService.validateSiteData(
        siteName: _controller.siteNameController.text,
        installerName: _controller.installerNameController.text,
        companyName: _controller.companyNameController.text,
        saqccRegNumber: _controller.saqccRegNumberController.text,
        buildingName: _controller.buildingNameController.text,
        installerContactNumber:
            _controller.installerContactNumberController.text,
        installerEmail: _controller.installerEmailController.text,
        siteDescription: _controller.siteDescriptionController.text,
      );

      if (errors.isNotEmpty) {
        print('errors: $errors');
        _showSnackBar('Please fix the errors in the form', isError: true);
        return;
      }

      final site = await _siteService.createSite(
        siteName: _controller.siteNameController.text,
        installerName: _controller.installerNameController.text,
        companyName: _controller.companyNameController.text,
        saqccRegNumber: _controller.saqccRegNumberController.text,
        buildingName: _controller.buildingNameController.text,
        installerContactNumber:
            _controller.installerContactNumberController.text,
        installerEmail: _controller.installerEmailController.text,
        siteDescription: _controller.siteDescriptionController.text,
      );

      _showSnackBar('Site created successfully!', isError: false);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      _showSnackBar('Error creating site: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFEC1D24) : Color(0xFF00A706),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps) {
      // Validate current step
      if (!_controller.validateStep(_currentStep)) {
        _showSnackBar('Please fill in all required fields', isError: true);
        return;
      }

      // Clear validation errors if validation passes
      _controller.clearValidationErrors();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentStep = page + 1;
    });
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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAppBar(),
                  SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            _currentStep < _totalSteps
                                ? Colors.white
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPageView()),
                            SizedBox(height: 20),
                            if (_currentStep < _totalSteps) _buildNavigation(),
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

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: SvgPicture.asset('assets/svgs/arrow_back_icon.svg'),
        ),
        SizedBox(width: 17),
        Text(
          'Create Site',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A3A3A),
          ),
        ),
        Spacer(),
        Text(
          'Step',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
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
              '$_currentStep/$_totalSteps',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SiteCreationPage(
          siteNameController: _controller.siteNameController,
          installerNameController: _controller.installerNameController,
          companyNameController: _controller.companyNameController,
          saqccRegNumberController: _controller.saqccRegNumberController,
          buildingNameController: _controller.buildingNameController,
          installerContactNumberController:
              _controller.installerContactNumberController,
          installerEmailController: _controller.installerEmailController,
          siteDescriptionController: _controller.siteDescriptionController,
          validationErrors: _controller.validationErrors,
        ),
        PanelSelectionPage(
          selectedPanelType: _controller.panelData.selectedPanelType,
          panelNameController: _controller.panelNameController,
          onPanelTypeChanged: _controller.updatePanelType,
          validationErrors: _controller.validationErrors,
        ),
        GeneralSettingsPage(
          levelTimeout: _controller.generalSettings.levelTimeout,
          timerSettings: _controller.generalSettings.timerSettings,
          faultLatching: _controller.generalSettings.faultLatching,
          panelDateTime: _controller.generalSettings.panelDateTime,
          serviceDue: _controller.generalSettings.serviceDue,
          serviceDueReminder: _controller.generalSettings.serviceDueReminder,
          eventReminder: _controller.generalSettings.eventReminder,
          expandedField: _controller.generalSettings.expandedField,
          onFieldChanged: _controller.updateGeneralSetting,
          onSliderChanged: _controller.updateSliderSetting,
          onExpandedChanged: _controller.setExpandedField,
        ),
        ZoneSettingsPage(
          expandedZone: _controller.zoneSettings.expandedZone,
          zoneTexts: _controller.zoneSettings.zoneTexts,
          zoneTypes: _controller.zoneSettings.zoneTypes,
          zoneStates: _controller.zoneSettings.zoneStates,
          zoneTests: _controller.zoneSettings.zoneTests,
          zoneModes: _controller.zoneSettings.zoneModes,
          zoneVerificationTimes: _controller.zoneSettings.zoneVerificationTimes,
          onZoneExpanded: _controller.setExpandedZone,
          onZoneFieldChanged: _controller.updateZoneField,
        ),
        SounderPage(
          expandedSounder: _controller.sounderData.expandedSounder,
          sounderTexts: _controller.sounderData.sounderTexts,
          sounderStates: _controller.sounderData.sounderStates,
          sounderTests: _controller.sounderData.sounderTests,
          sounderTypes: _controller.sounderData.sounderTypes,
          sounderGroups: _controller.sounderData.sounderGroups,
          sounderFunctions: _controller.sounderData.sounderFunctions,
          availableZones: _controller.zoneSettings.zoneTexts.keys.toList(),
          onSounderExpanded: _controller.setExpandedSounder,
          onSounderFieldChanged: _controller.updateSounderField,
        ),
        SounderSettingsPage(
          fireSoundTone: _controller.sounderSettings.fireSoundTone,
          fireSounderDelay: _controller.sounderSettings.fireSounderDelay,
          countDownAction: _controller.sounderSettings.countDownAction,
          holdAction: _controller.sounderSettings.holdAction,
          releaseAction: _controller.sounderSettings.releaseAction,
          extSounderDelay: _controller.sounderSettings.extSounderDelay,
          onSounderSettingChanged: _controller.updateSounderSetting,
        ),
        InputPage(
          inputText: _controller.inputData.inputText,
          inverted: _controller.inputData.inverted,
          test: _controller.inputData.test,
          input1: _controller.inputData.input1,
          group: _controller.inputData.group,
          function: _controller.inputData.function,
          onInputSettingChanged: _controller.updateInputSetting,
        ),
        RelayPage(
          expandedRelay: _controller.relayData.expandedRelay,
          relayTexts: _controller.relayData.relayTexts,
          relayTests: _controller.relayData.relayTests,
          relayStates: _controller.relayData.relayStates,
          relayGroups: _controller.relayData.relayGroups,
          relayFunctions: _controller.relayData.relayFunctions,
          onRelayExpanded: _controller.setExpandedRelay,
          onRelayFieldChanged: _controller.updateRelayField,
        ),
        LBusDevicesPage(
          expandedLBus: _controller.lbusData.expandedLBus,
          lbusInputs: _controller.lbusData.lbusInputs,
          lbusInputTexts: _controller.lbusData.lbusInputTexts,
          lbusProducts: _controller.lbusData.lbusProducts,
          lbusGroups: _controller.lbusData.lbusGroups,
          lbusFunctions: _controller.lbusData.lbusFunctions,
          lbusEnabled: _controller.lbusData.lbusEnabled,
          lbusTests: _controller.lbusData.lbusTests,
          lbusInverted: _controller.lbusData.lbusInverted,
          onLBusExpanded: _controller.setExpandedLBus,
          onLBusFieldChanged: _controller.updateLBusField,
        ),
        ProjectSummaryPage(
          enabled: _controller.extinguishingData.enabled,
          actuatorType: _controller.extinguishingData.actuatorType,
          function: _controller.extinguishingData.function,
          autoCountdown: _controller.extinguishingData.autoCountdown,
          manualCountdown: _controller.extinguishingData.manualCountdown,
          releaseTime: _controller.extinguishingData.releaseTime,
          resetInCount: _controller.extinguishingData.resetInCount,
          holdCount: _controller.extinguishingData.holdCount,
          action: _controller.extinguishingData.action,
          onExtinguishingSettingChanged: _controller.updateExtinguishingSetting,
          onUploadToPanel: _createSite,
        ),
      ],
    );
  }

  Widget _buildNavigation() {
    return Row(
      children: [
        Opacity(
          opacity: _currentStep == 1 ? 0.2 : 1.0,
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
                    Icon(Icons.arrow_back, color: Color(0xFF49454F)),
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
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
