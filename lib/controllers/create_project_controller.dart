import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/models/create_project/site_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/general_settings_data.dart';
import 'package:techno_switch_solar_app/models/create_project/zone_settings_data.dart';
import 'package:techno_switch_solar_app/models/create_project/sounder_data.dart';
import 'package:techno_switch_solar_app/models/create_project/relay_data.dart';
import 'package:techno_switch_solar_app/models/create_project/input_data.dart';
import 'package:techno_switch_solar_app/models/create_project/lbus_data.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';

/// Controller class that manages all state for the create project flow
/// This follows the Single Responsibility Principle and separation of concerns
class CreateProjectController extends ChangeNotifier {
  // Controllers for text inputs
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController installerNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController saqccRegNumberController =
      TextEditingController();
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController installerContactNumberController =
      TextEditingController();
  final TextEditingController installerEmailController =
      TextEditingController();
  final TextEditingController siteDescriptionController =
      TextEditingController();
  final TextEditingController panelNameController = TextEditingController();

  // Data models
  SiteFormData siteData = SiteFormData();
  PanelFormData panelData = PanelFormData();
  GeneralSettingsData generalSettings = GeneralSettingsData();
  ZoneSettingsData zoneSettings = ZoneSettingsData();
  SounderData sounderData = SounderData();
  SounderSettingsData sounderSettings = SounderSettingsData();
  InputData inputData = InputData();
  RelayData relayData = RelayData();
  LBusData lbusData = LBusData();
  ExtinguishingData extinguishingData = ExtinguishingData();

  // Validation errors
  Map<String, String> validationErrors = {};

  CreateProjectController() {
    _initializeControllerListeners();
  }

  /// Initialize listeners for text controllers to sync with data models
  void _initializeControllerListeners() {
    siteNameController.addListener(() {
      siteData = siteData.copyWith(siteName: siteNameController.text);
    });

    installerNameController.addListener(() {
      siteData = siteData.copyWith(installerName: installerNameController.text);
    });

    companyNameController.addListener(() {
      siteData = siteData.copyWith(companyName: companyNameController.text);
    });

    saqccRegNumberController.addListener(() {
      siteData = siteData.copyWith(
        saqccRegNumber: saqccRegNumberController.text,
      );
    });

    buildingNameController.addListener(() {
      siteData = siteData.copyWith(buildingName: buildingNameController.text);
    });

    installerContactNumberController.addListener(() {
      siteData = siteData.copyWith(
        installerContactNumber: installerContactNumberController.text,
      );
    });

    installerEmailController.addListener(() {
      siteData = siteData.copyWith(
        installerEmail: installerEmailController.text,
      );
    });

    siteDescriptionController.addListener(() {
      siteData = siteData.copyWith(
        siteDescription: siteDescriptionController.text,
      );
    });

    panelNameController.addListener(() {
      panelData = panelData.copyWith(panelName: panelNameController.text);
    });
  }

  // Panel Type Management
  void updatePanelType(String? panelType) {
    panelData = panelData.copyWith(selectedPanelType: panelType);

    if (panelType != null) {
      final panelConfig = PanelTypeConfig.getByTypeName(panelType);
      if (panelConfig != null) {
        zoneSettings.initializeZones(panelConfig.zoneCount);
        sounderData.initializeSounders(
          panelConfig.sounderCount,
          zoneSettings.zoneTexts.keys.isNotEmpty
              ? zoneSettings.zoneTexts.keys.first
              : 'Zone 1',
        );
        relayData.initializeRelays(panelConfig.relayCount);
      }
    }
    notifyListeners();
  }

  // General Settings Management
  void updateGeneralSetting(String label, String value) {
    switch (label) {
      case 'Level Timeout':
        generalSettings = generalSettings.copyWith(levelTimeout: value);
        break;
      case 'Fault Latching':
        generalSettings = generalSettings.copyWith(faultLatching: value);
        break;
      case 'Panel Date & Time':
        generalSettings = generalSettings.copyWith(panelDateTime: value);
        break;
      case 'Service Due':
        generalSettings = generalSettings.copyWith(serviceDue: value);
        break;
      case 'Service Due Reminder':
        generalSettings = generalSettings.copyWith(serviceDueReminder: value);
        break;
      case 'Event Reminder':
        generalSettings = generalSettings.copyWith(eventReminder: value);
        break;
    }
    notifyListeners();
  }

  void updateSliderSetting(String label, double value) {
    switch (label) {
      case 'Level Timeout':
        generalSettings = generalSettings.copyWith(
          levelTimeout: '${value.toInt()} Seconds',
        );
        break;
      case 'Timer Settings':
        generalSettings = generalSettings.copyWith(timerSettings: value);
        break;
    }
    notifyListeners();
  }

  void setExpandedField(String? field) {
    generalSettings = generalSettings.copyWith(expandedField: field);
    notifyListeners();
  }

  // Zone Management
  void setExpandedZone(String? zoneName) {
    zoneSettings.expandedZone = zoneName;
    notifyListeners();
  }

  void updateZoneField(String zoneName, String fieldType, String value) {
    zoneSettings.updateZoneField(zoneName, fieldType, value);
    notifyListeners();
  }

  // Sounder Management
  void setExpandedSounder(String? sounderName) {
    sounderData.expandedSounder = sounderName;
    notifyListeners();
  }

  void updateSounderField(String sounderName, String fieldType, String value) {
    sounderData.updateSounderField(sounderName, fieldType, value);
    notifyListeners();
  }

  void updateSounderSetting(String label, String value) {
    switch (label) {
      case 'Fire Sound':
        sounderSettings.fireSoundTone = value;
        break;
      case 'Sounder Delay':
        // Handle both fire and ext sounder delay
        if (sounderSettings.fireSounderDelay == value) {
          sounderSettings.fireSounderDelay = value;
        } else {
          sounderSettings.extSounderDelay = value;
        }
        break;
      case 'Count Down Action':
        sounderSettings.countDownAction = value;
        break;
      case 'Hold Action':
        sounderSettings.holdAction = value;
        break;
      case 'Release Action':
        sounderSettings.releaseAction = value;
        break;
    }
    notifyListeners();
  }

  // Input Management
  void updateInputSetting(String label, String value) {
    inputData.updateField(label, value);
    notifyListeners();
  }

  // Relay Management
  void setExpandedRelay(String? relayName) {
    relayData.expandedRelay = relayName;
    notifyListeners();
  }

  void updateRelayField(String relayName, String fieldType, String value) {
    relayData.updateRelayField(relayName, fieldType, value);
    notifyListeners();
  }

  // L-BUS Management
  void setExpandedLBus(String? lbusName) {
    lbusData.expandedLBus = lbusName;
    notifyListeners();
  }

  void updateLBusField(String lbusName, String fieldType, String value) {
    lbusData.updateLBusField(lbusName, fieldType, value);
    notifyListeners();
  }

  // Extinguishing Management
  void updateExtinguishingSetting(String label, String value) {
    extinguishingData.updateField(label, value);
    notifyListeners();
  }

  // Validation
  bool validateStep(int step) {
    validationErrors.clear();

    if (step == 1) {
      // Site Creation validation
      if (siteNameController.text.trim().isEmpty) {
        validationErrors['siteName'] = 'Site Name is required';
      }
      if (saqccRegNumberController.text.trim().isEmpty) {
        validationErrors['saqccRegNumber'] =
            'SAQCC Registration Number is required';
      }
    } else if (step == 2) {
      // Panel Selection validation
      if (panelNameController.text.trim().isEmpty) {
        validationErrors['panelName'] = 'Panel Name is required';
      }
      if (panelData.selectedPanelType == null) {
        validationErrors['panelType'] = 'Panel Type is required';
      }
    }

    if (validationErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    return true;
  }

  void clearValidationErrors() {
    validationErrors.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    siteNameController.dispose();
    installerNameController.dispose();
    companyNameController.dispose();
    saqccRegNumberController.dispose();
    buildingNameController.dispose();
    installerContactNumberController.dispose();
    installerEmailController.dispose();
    siteDescriptionController.dispose();
    panelNameController.dispose();
    super.dispose();
  }
}
