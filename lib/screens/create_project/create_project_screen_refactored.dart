import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
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
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
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
  final BleLogController _bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();

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

  /// Same flow as [ProjectDashboardScreen] / `_ProjectDashboardContentState`.
  Future<bool> _confirmAndDisconnect() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Disconnect device?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Going back will disconnect the device. Are you sure?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Disconnect',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDisconnect == true) {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      _controller.setCreateProjectPanelBleVerified(false);
      return true;
    }
    return false;
  }

  Future<void> _onLeadingBackPressed() async {
    if (_bleController.isConnected) {
      final shouldPop = await _confirmAndDisconnect();
      if (shouldPop && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) Navigator.of(context).pop();
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

  Future<void> _goToNextStep() async {
    if (_currentStep >= _totalSteps) return;

    if (!_controller.validateStep(_currentStep)) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_currentStep == 2) {
      _controller.clearValidationErrors();
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => ScanningScreen(
                createProjectExpectedPanelType:
                    _controller.panelData.selectedPanelType,
              ),
        ),
      );
      if (!mounted) return;
      if (verified == true) {
        _controller.setCreateProjectPanelBleVerified(true);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    _controller.clearValidationErrors();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      if (_currentStep == 3) {
        _bleManager.disconnectConnectedDevice();
        _controller.setCreateProjectPanelBleVerified(false);
      }
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
    return WillPopScope(
      onWillPop: () async {
        if (_bleController.isConnected) {
          return _confirmAndDisconnect();
        }
        return true;
      },
      child: Scaffold(
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
                              if (_currentStep < _totalSteps)
                                _buildNavigation(),
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _onLeadingBackPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF3D3D3D),
              size: 18,
            ),
          ),
        ),
        SizedBox(width: 12),
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
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _totalSteps,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return SiteCreationPage(
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
            );
          case 1:
            return PanelSelectionPage(
              selectedPanelType: _controller.panelData.selectedPanelType,
              panelNameController: _controller.panelNameController,
              onPanelTypeChanged: _controller.updatePanelType,
              validationErrors: _controller.validationErrors,
            );
          case 2:
            return GeneralSettingsPage(
              levelTimeout: _controller.generalSettings.levelTimeout,
              timerSettings: _controller.generalSettings.timerSettings,
              faultLatching: _controller.generalSettings.faultLatching,
              panelDateTime: _controller.generalSettings.panelDateTime,
              serviceDue: _controller.generalSettings.serviceDue,
              serviceDueReminder:
                  _controller.generalSettings.serviceDueReminder,
              eventReminder: _controller.generalSettings.eventReminder,
              expandedField: _controller.generalSettings.expandedField,
              onFieldChanged: _controller.updateGeneralSetting,
              onSliderChanged: _controller.updateSliderSetting,
              onExpandedChanged: _controller.setExpandedField,
            );
          case 3:
            return ZoneSettingsPage(
              expandedZone: _controller.zoneSettings.expandedZone,
              zoneTexts: _controller.zoneSettings.zoneTexts,
              zoneTypes: _controller.zoneSettings.zoneTypes,
              zoneStates: _controller.zoneSettings.zoneStates,
              zoneTests: _controller.zoneSettings.zoneTests,
              zoneModes: _controller.zoneSettings.zoneModes,
              zoneVerificationTimes:
                  _controller.zoneSettings.zoneVerificationTimes,
              onZoneExpanded: _controller.setExpandedZone,
              onZoneFieldChanged: _controller.updateZoneField,
            );
          case 4:
            return SounderPage(
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
            );
          case 5:
            return SounderSettingsPage(
              fireSoundTone: _controller.sounderSettings.fireSoundTone,
              fireSounderDelay: _controller.sounderSettings.fireSounderDelay,
              countDownAction: _controller.sounderSettings.countDownAction,
              holdAction: _controller.sounderSettings.holdAction,
              releaseAction: _controller.sounderSettings.releaseAction,
              extSounderDelay: _controller.sounderSettings.extSounderDelay,
              onSounderSettingChanged: _controller.updateSounderSetting,
            );
          case 6:
            return InputPage(
              inputText: _controller.inputData.inputText,
              inverted: _controller.inputData.inverted,
              test: _controller.inputData.test,
              input1: _controller.inputData.input1,
              group: _controller.inputData.group,
              function: _controller.inputData.function,
              onInputSettingChanged: _controller.updateInputSetting,
            );
          case 7:
            return RelayPage(
              expandedRelay: _controller.relayData.expandedRelay,
              relayTexts: _controller.relayData.relayTexts,
              relayTests: _controller.relayData.relayTests,
              relayStates: _controller.relayData.relayStates,
              relayGroups: _controller.relayData.relayGroups,
              relayFunctions: _controller.relayData.relayFunctions,
              onRelayExpanded: _controller.setExpandedRelay,
              onRelayFieldChanged: _controller.updateRelayField,
            );
          case 8:
            return LBusDevicesPage(
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
            );
          case 9:
            return ProjectSummaryPage(
              enabled: _controller.extinguishingData.enabled,
              actuatorType: _controller.extinguishingData.actuatorType,
              function: _controller.extinguishingData.function,
              autoCountdown: _controller.extinguishingData.autoCountdown,
              manualCountdown: _controller.extinguishingData.manualCountdown,
              releaseTime: _controller.extinguishingData.releaseTime,
              resetInCount: _controller.extinguishingData.resetInCount,
              holdCount: _controller.extinguishingData.holdCount,
              action: _controller.extinguishingData.action,
              onExtinguishingSettingChanged:
                  _controller.updateExtinguishingSetting,
              onUploadToPanel: _createSite,
            );
          default:
            return const SizedBox.shrink();
        }
      },
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
          onTap: () => _goToNextStep(),
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
                    _currentStep == 2 ? 'Connect panel' : 'Next',
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
