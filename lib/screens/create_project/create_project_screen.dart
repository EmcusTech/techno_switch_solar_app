import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/panel_selection_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/general_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/site_creation_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/zone_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/sounder_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/sounder_settings_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/input_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/relay_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/devices_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/project_summary_page.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';

class CreateSiteScreen extends StatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen> {
  late TextEditingController _panelNameController;
  late TextEditingController _siteNameController;
  late TextEditingController _installerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _saqccRegNumberController;
  late TextEditingController _buildingNameController;
  late TextEditingController _installerContactNumberController;
  late TextEditingController _installerEmailController;
  late TextEditingController _siteDescriptionController;
  late PageController _pageController;
  int currentStep = 1;
  final int totalSteps = 10;
  String? selectedPanelType;

  // General Settings values
  String levelTimeout = '300 Seconds';
  double timerSettings = 300;
  String faultLatching = 'Yes';
  String panelDateTime = '13/05/2025 - 10:31:02';
  String serviceDue = '13/09/2025';
  String serviceDueReminder = '13/09/2025';
  String eventReminder = '13/09/2025';

  // Expanded state for slider fields
  String? expandedField;

  // Zone Settings state
  String? expandedZone;
  Map<String, String> zoneTexts = {
    'Zone 1': '',
    'Zone 2': '',
    'Zone 3': '',
    'Zone 4': '',
  };
  Map<String, String> zoneTypes = {
    'Zone 1': 'Double Knock',
    'Zone 2': 'Double Knock',
    'Zone 3': 'Double Knock',
    'Zone 4': 'Double Knock',
  };
  Map<String, String> zoneStates = {
    'Zone 1': 'Enable',
    'Zone 2': 'Enable',
    'Zone 3': 'Enable',
    'Zone 4': 'Enable',
  };
  Map<String, String> zoneTests = {
    'Zone 1': 'Yes',
    'Zone 2': 'Yes',
    'Zone 3': 'Yes',
    'Zone 4': 'Yes',
  };
  Map<String, String> zoneModes = {
    'Zone 1': 'Yes',
    'Zone 2': 'Yes',
    'Zone 3': 'Yes',
    'Zone 4': 'Yes',
  };
  Map<String, String> zoneVerificationTimes = {
    'Zone 1': '300 Sec',
    'Zone 2': '300 Sec',
    'Zone 3': '300 Sec',
    'Zone 4': '300 Sec',
  };

  // Sounder Settings state
  String? expandedSounder;
  Map<String, String> sounderTexts = {
    'Sounder 1': '',
    'Sounder 2': '',
    'Sounder 3': '',
  };
  Map<String, String> sounderStates = {
    'Sounder 1': 'Enable',
    'Sounder 2': 'Enable',
    'Sounder 3': 'Enable',
  };
  Map<String, String> sounderTests = {
    'Sounder 1': 'Yes',
    'Sounder 2': 'Yes',
    'Sounder 3': 'Yes',
  };
  Map<String, String> sounderTypes = {
    'Sounder 1': 'Horn',
    'Sounder 2': 'Horn',
    'Sounder 3': 'Horn',
  };
  Map<String, String> sounderGroups = {
    'Sounder 1': 'Zone 1',
    'Sounder 2': 'Zone 1',
    'Sounder 3': 'Zone 1',
  };
  Map<String, String> sounderFunctions = {
    'Sounder 1': 'P1',
    'Sounder 2': 'P1',
    'Sounder 3': 'P1',
  };

  // Sounder Settings Page state
  String fireSoundTone = 'Pulsing 1s ON, 4s OFF';
  String fireSounderDelay = '300 Sec';
  String countDownAction = 'Pulsing 1s ON, 4s OFF';
  String holdAction = 'Pulsing 1s ON, 4s OFF';
  String releaseAction = 'Pulsing 1s ON, 4s OFF';
  String extSounderDelay = '300 Sec';

  // Input Page state
  String inputText = 'Input 1';
  String inverted = 'No';
  String test = 'No';
  String input1 = 'Enable';
  String group = 'Group A';
  String function = 'Function 1A';

  // Relay Page state
  String? expandedRelay;
  Map<String, String> relayTexts = {};
  Map<String, String> relayTests = {};
  Map<String, String> relayStates = {};
  Map<String, String> relayGroups = {};
  Map<String, String> relayFunctions = {};

  // L-Bus Devices Page state
  String? expandedLBus;
  Map<String, String> lbusInputs = {'L-BUS 1': '', 'L-BUS 2': ''};
  Map<String, String> lbusInputTexts = {'L-BUS 1': '', 'L-BUS 2': ''};
  Map<String, String> lbusProducts = {
    'L-BUS 1': 'ONYX202',
    'L-BUS 2': 'ONYX202',
  };
  Map<String, String> lbusGroups = {'L-BUS 1': 'Group A', 'L-BUS 2': 'Group A'};
  Map<String, String> lbusFunctions = {
    'L-BUS 1': 'Function A',
    'L-BUS 2': 'Function A',
  };
  Map<String, String> lbusEnabled = {'L-BUS 1': 'Yes', 'L-BUS 2': 'Yes'};
  Map<String, String> lbusTests = {'L-BUS 1': 'No', 'L-BUS 2': 'No'};
  Map<String, String> lbusInverted = {'L-BUS 1': 'No', 'L-BUS 2': 'No'};

  // Extinguishing Out Page state
  String extinguishingEnabled = 'Yes';
  String actuatorType = 'Type B';
  String extinguishingFunction = 'Function B';
  String autoCountdown = '15 Sec';
  String manualCountdown = '30 Sec';
  String releaseTime = '45 Sec';
  String resetInCount = 'Yes';
  String holdCount = '5 Sec';
  String extinguishingAction = 'Extinguish';

  final SiteService _siteService = SiteService();
  bool _isSaving = false;
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    _panelNameController = TextEditingController();
    _siteNameController = TextEditingController();
    _installerNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _saqccRegNumberController = TextEditingController();
    _buildingNameController = TextEditingController();
    _installerContactNumberController = TextEditingController();
    _installerEmailController = TextEditingController();
    _siteDescriptionController = TextEditingController();
    _pageController = PageController();
    super.initState();
  }

  Future<void> _createSite() async {
    // if (_isLoading) return;

    // setState(() {
    //   _isLoading = true;
    //   _validationErrors.clear();
    // });

    try {
      // Validate the form data
      final errors = _siteService.validateSiteData(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      if (errors.isNotEmpty) {
        // setState(() {
        //   _validationErrors = errors;
        //   _isLoading = false;
        // });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the errors in the form'),
            backgroundColor: Color(0xFFEC1D24),
          ),
        );
        return;
      }

      // Create the site
      final site = await _siteService.createSite(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      // Save the logs and associate them with the site
      // await _siteService.storeLogs(widget.retrievedLogs, siteId: site.id!);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Site created successfully!'),
          backgroundColor: Color(0xFF00A706),
        ),
      );

      // Navigate back to home screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      // setState(() {
      //   _isLoading = false;
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating site: $error'),
          backgroundColor: Color(0xFFEC1D24),
        ),
      );
    }
  }

  void _goToNextStep() {
    if (currentStep < totalSteps) {
      // Validate mandatory fields based on current step
      Map<String, String> errors = {};

      if (currentStep == 1) {
        // Site Creation Page validation
        if (_siteNameController.text.trim().isEmpty) {
          errors['siteName'] = 'Site Name is required';
        }
        if (_saqccRegNumberController.text.trim().isEmpty) {
          errors['saqccRegNumber'] = 'SAQCC Registration Number is required';
        }
      } else if (currentStep == 2) {
        // Panel Selection Page validation
        if (_panelNameController.text.trim().isEmpty) {
          errors['panelName'] = 'Panel Name is required';
        }
        if (selectedPanelType == null) {
          errors['panelType'] = 'Panel Type is required';
        }
      }

      // If there are validation errors, show them and don't proceed
      if (errors.isNotEmpty) {
        setState(() {
          _validationErrors = errors;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Color(0xFFEC1D24),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Clear validation errors if validation passes
      setState(() {
        _validationErrors = {};
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      currentStep = page + 1;
    });
  }

  void _onPanelTypeChanged(String? panelType) {
    setState(() {
      selectedPanelType = panelType;

      // Dynamically initialize zones, sounders, and relays based on panel type
      if (panelType != null) {
        final panelConfig = PanelTypeConfig.getByTypeName(panelType);
        if (panelConfig != null) {
          _initializeZones(panelConfig.zoneCount);
          _initializeSounders(panelConfig.sounderCount);
          _initializeRelays(panelConfig.relayCount);
        }
      }
    });
  }

  /// Initialize zones dynamically based on panel configuration
  void _initializeZones(int zoneCount) {
    zoneTexts.clear();
    zoneTypes.clear();
    zoneStates.clear();
    zoneTests.clear();
    zoneModes.clear();
    zoneVerificationTimes.clear();
    expandedZone = null;

    for (int i = 1; i <= zoneCount; i++) {
      final zoneName = 'Zone $i';
      zoneTexts[zoneName] = zoneName; // Initialize with zone name
      zoneTypes[zoneName] = 'Double Knock';
      zoneStates[zoneName] = 'Enable';
      zoneTests[zoneName] = 'Yes';
      zoneModes[zoneName] = 'Yes';
      zoneVerificationTimes[zoneName] = '300 Sec';
    }
  }

  /// Initialize sounders dynamically based on panel configuration
  void _initializeSounders(int sounderCount) {
    sounderTexts.clear();
    sounderStates.clear();
    sounderTests.clear();
    sounderTypes.clear();
    sounderGroups.clear();
    sounderFunctions.clear();
    expandedSounder = null;

    // Get the first available zone, or default to 'Zone 1'
    final defaultZone =
        zoneTexts.keys.isNotEmpty ? zoneTexts.keys.first : 'Zone 1';

    for (int i = 1; i <= sounderCount; i++) {
      final sounderName = 'Sounder $i';
      sounderTexts[sounderName] = sounderName; // Initialize with sounder name
      sounderStates[sounderName] = 'Enable';
      sounderTests[sounderName] = 'Yes';
      sounderTypes[sounderName] = 'Horn';
      sounderGroups[sounderName] = defaultZone;
      sounderFunctions[sounderName] = 'P1';
    }
  }

  /// Initialize relays dynamically based on panel configuration
  void _initializeRelays(int relayCount) {
    relayTexts.clear();
    relayTests.clear();
    relayStates.clear();
    relayGroups.clear();
    relayFunctions.clear();
    expandedRelay = null;

    for (int i = 1; i <= relayCount; i++) {
      final relayName = 'Relay $i';
      relayTexts[relayName] = relayName; // Initialize with relay name
      relayTests[relayName] = 'No';
      relayStates[relayName] = 'Enable';
      relayGroups[relayName] = 'Group A';
      relayFunctions[relayName] = 'Function 1A';
    }
  }

  void _onFieldChanged(String label, String newValue) {
    setState(() {
      switch (label) {
        case 'Level Timeout':
          levelTimeout = newValue;
          break;
        case 'Fault Latching':
          faultLatching = newValue;
          break;
        case 'Panel Date & Time':
          panelDateTime = newValue;
          break;
        case 'Service Due':
          serviceDue = newValue;
          break;
        case 'Service Due Reminder':
          serviceDueReminder = newValue;
          break;
        case 'Event Reminder':
          eventReminder = newValue;
          break;
      }
    });
  }

  void _onSliderChanged(String label, double value) {
    setState(() {
      switch (label) {
        case 'Level Timeout':
          levelTimeout = '${value.toInt()} Seconds';
          break;
        case 'Timer Settings':
          timerSettings = value;
          break;
      }
    });
  }

  void _onExpandedChanged(String? field) {
    setState(() {
      expandedField = field;
    });
  }

  void _onZoneExpanded(String? zoneName) {
    setState(() {
      expandedZone = zoneName;
    });
  }

  void _onZoneFieldChanged(String zoneName, String fieldType, String value) {
    setState(() {
      switch (fieldType) {
        case 'zoneText':
          zoneTexts[zoneName] = value;
          break;
        case 'zoneType':
          zoneTypes[zoneName] = value;
          break;
        case 'zoneState':
          zoneStates[zoneName] = value;
          break;
        case 'zoneTest':
          zoneTests[zoneName] = value;
          break;
        case 'zoneMode':
          zoneModes[zoneName] = value;
          break;
        case 'zoneVerificationTime':
          zoneVerificationTimes[zoneName] = value;
          break;
      }
    });
  }

  void _onSounderExpanded(String? sounderName) {
    setState(() {
      expandedSounder = sounderName;
    });
  }

  void _onSounderFieldChanged(
    String sounderName,
    String fieldType,
    String value,
  ) {
    setState(() {
      switch (fieldType) {
        case 'sounderText':
          sounderTexts[sounderName] = value;
          break;
        case 'sounderState':
          sounderStates[sounderName] = value;
          break;
        case 'sounderTest':
          sounderTests[sounderName] = value;
          break;
        case 'sounderType':
          sounderTypes[sounderName] = value;
          break;
        case 'sounderGroup':
          sounderGroups[sounderName] = value;
          break;
        case 'sounderFunction':
          sounderFunctions[sounderName] = value;
          break;
      }
    });
  }

  void _onSounderSettingChanged(String label, String value) {
    setState(() {
      switch (label) {
        case 'Fire Sound':
          fireSoundTone = value;
          break;
        case 'Sounder Delay':
          if (label == 'Sounder Delay') {
            // Determine if it's fire sounder delay or ext sounder delay based on context
            // For now, we'll assume it's the first one encountered
            if (fireSounderDelay == value) {
              fireSounderDelay = value;
            } else {
              extSounderDelay = value;
            }
          }
          break;
        case 'Count Down Action':
          countDownAction = value;
          break;
        case 'Hold Action':
          holdAction = value;
          break;
        case 'Release Action':
          releaseAction = value;
          break;
      }
    });
  }

  void _onInputSettingChanged(String label, String value) {
    setState(() {
      switch (label) {
        case 'Input Text':
          inputText = value;
          break;
        case 'Inverted':
          inverted = value;
          break;
        case 'Test':
          test = value;
          break;
        case 'Input 1':
          input1 = value;
          break;
        case 'Group':
          group = value;
          break;
        case 'Function':
          function = value;
          break;
      }
    });
  }

  void _onRelayExpanded(String? relayName) {
    setState(() {
      expandedRelay = relayName;
    });
  }

  void _onRelayFieldChanged(String relayName, String fieldType, String value) {
    setState(() {
      switch (fieldType) {
        case 'relayText':
          relayTexts[relayName] = value;
          break;
        case 'relayTest':
          relayTests[relayName] = value;
          break;
        case 'relayState':
          relayStates[relayName] = value;
          break;
        case 'relayGroup':
          relayGroups[relayName] = value;
          break;
        case 'relayFunction':
          relayFunctions[relayName] = value;
          break;
      }
    });
  }

  void _onLBusExpanded(String? lbusName) {
    setState(() {
      expandedLBus = lbusName;
    });
  }

  void _onLBusFieldChanged(String lbusName, String fieldType, String value) {
    setState(() {
      switch (fieldType) {
        case 'input':
          lbusInputs[lbusName] = value;
          break;
        case 'inputText':
          lbusInputTexts[lbusName] = value;
          break;
        case 'product':
          lbusProducts[lbusName] = value;
          break;
        case 'group':
          lbusGroups[lbusName] = value;
          break;
        case 'function':
          lbusFunctions[lbusName] = value;
          break;
        case 'enabled':
          lbusEnabled[lbusName] = value;
          break;
        case 'test':
          lbusTests[lbusName] = value;
          break;
        case 'inverted':
          lbusInverted[lbusName] = value;
          break;
      }
    });
  }

  void _onExtinguishingSettingChanged(String label, String value) {
    setState(() {
      switch (label) {
        case 'Enabled':
          extinguishingEnabled = value;
          break;
        case 'Actuator Type':
          actuatorType = value;
          break;
        case 'Function':
          extinguishingFunction = value;
          break;
        case 'Auto Countdown':
          autoCountdown = value;
          break;
        case 'Manual Countdown':
          manualCountdown = value;
          break;
        case 'Release Time':
          releaseTime = value;
          break;
        case 'Reset in Count':
          resetInCount = value;
          break;
        case 'Hold / Count':
          holdCount = value;
          break;
        case 'Action':
          extinguishingAction = value;
          break;
      }
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
                        color:
                            currentStep < totalSteps
                                ? Colors.white
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: _onPageChanged,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  SiteCreationPage(
                                    siteNameController: _siteNameController,
                                    installerNameController:
                                        _installerNameController,
                                    companyNameController:
                                        _companyNameController,
                                    saqccRegNumberController:
                                        _saqccRegNumberController,
                                    buildingNameController:
                                        _buildingNameController,
                                    installerContactNumberController:
                                        _installerContactNumberController,
                                    installerEmailController:
                                        _installerEmailController,
                                    siteDescriptionController:
                                        _siteDescriptionController,
                                    validationErrors: _validationErrors,
                                  ),
                                  PanelSelectionPage(
                                    selectedPanelType: selectedPanelType,
                                    panelNameController: _panelNameController,
                                    onPanelTypeChanged: _onPanelTypeChanged,
                                    validationErrors: _validationErrors,
                                  ),
                                  GeneralSettingsPage(
                                    levelTimeout: levelTimeout,
                                    timerSettings: timerSettings,
                                    faultLatching: faultLatching,
                                    panelDateTime: panelDateTime,
                                    serviceDue: serviceDue,
                                    serviceDueReminder: serviceDueReminder,
                                    eventReminder: eventReminder,
                                    expandedField: expandedField,
                                    onFieldChanged: _onFieldChanged,
                                    onSliderChanged: _onSliderChanged,
                                    onExpandedChanged: _onExpandedChanged,
                                  ),
                                  ZoneSettingsPage(
                                    expandedZone: expandedZone,
                                    zoneTexts: zoneTexts,
                                    zoneTypes: zoneTypes,
                                    zoneStates: zoneStates,
                                    zoneTests: zoneTests,
                                    zoneModes: zoneModes,
                                    zoneVerificationTimes:
                                        zoneVerificationTimes,
                                    onZoneExpanded: _onZoneExpanded,
                                    onZoneFieldChanged: _onZoneFieldChanged,
                                  ),
                                  SounderPage(
                                    expandedSounder: expandedSounder,
                                    sounderTexts: sounderTexts,
                                    sounderStates: sounderStates,
                                    sounderTests: sounderTests,
                                    sounderTypes: sounderTypes,
                                    sounderGroups: sounderGroups,
                                    sounderFunctions: sounderFunctions,
                                    availableZones:
                                        zoneTexts.keys
                                            .toList(), // Pass available zones
                                    onSounderExpanded: _onSounderExpanded,
                                    onSounderFieldChanged:
                                        _onSounderFieldChanged,
                                  ),
                                  SounderSettingsPage(
                                    fireSoundTone: fireSoundTone,
                                    fireSounderDelay: fireSounderDelay,
                                    countDownAction: countDownAction,
                                    holdAction: holdAction,
                                    releaseAction: releaseAction,
                                    extSounderDelay: extSounderDelay,
                                    onSounderSettingChanged:
                                        _onSounderSettingChanged,
                                  ),
                                  InputPage(
                                    inputText: inputText,
                                    inverted: inverted,
                                    test: test,
                                    input1: input1,
                                    group: group,
                                    function: function,
                                    onInputSettingChanged:
                                        _onInputSettingChanged,
                                  ),
                                  RelayPage(
                                    expandedRelay: expandedRelay,
                                    relayTexts: relayTexts,
                                    relayTests: relayTests,
                                    relayStates: relayStates,
                                    relayGroups: relayGroups,
                                    relayFunctions: relayFunctions,
                                    onRelayExpanded: _onRelayExpanded,
                                    onRelayFieldChanged: _onRelayFieldChanged,
                                  ),
                                  LBusDevicesPage(
                                    expandedLBus: expandedLBus,
                                    lbusInputs: lbusInputs,
                                    lbusInputTexts: lbusInputTexts,
                                    lbusProducts: lbusProducts,
                                    lbusGroups: lbusGroups,
                                    lbusFunctions: lbusFunctions,
                                    lbusEnabled: lbusEnabled,
                                    lbusTests: lbusTests,
                                    lbusInverted: lbusInverted,
                                    onLBusExpanded: _onLBusExpanded,
                                    onLBusFieldChanged: _onLBusFieldChanged,
                                  ),
                                  ProjectSummaryPage(
                                    enabled: extinguishingEnabled,
                                    actuatorType: actuatorType,
                                    function: extinguishingFunction,
                                    autoCountdown: autoCountdown,
                                    manualCountdown: manualCountdown,
                                    releaseTime: releaseTime,
                                    resetInCount: resetInCount,
                                    holdCount: holdCount,
                                    action: extinguishingAction,
                                    onExtinguishingSettingChanged:
                                        _onExtinguishingSettingChanged,
                                    onUploadToPanel: () {
                                      _createSite();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            if (currentStep <
                                totalSteps) // Only show navigation buttons if not on final page
                              Row(
                                children: [
                                  Opacity(
                                    opacity: currentStep == 1 ? 0.2 : 1.0,
                                    child: GestureDetector(
                                      onTap: _goToPreviousStep,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFEFEEEE),
                                          borderRadius: BorderRadius.circular(
                                            28.5,
                                          ),
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
                                        borderRadius: BorderRadius.circular(
                                          28.5,
                                        ),
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

  @override
  void dispose() {
    _panelNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
