import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/models/create_project/site_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/zone_settings_data.dart';
import 'package:techno_switch_solar_app/models/create_project/sounder_data.dart';
import 'package:techno_switch_solar_app/models/create_project/relay_data.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class CreateProjectController extends GetxController {
  final TextEditingController siteNameController = TextEditingController(
    text: '',
  );
  final TextEditingController installerNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController saqccRegNumberController = TextEditingController(
    text: '',
  );
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController installerContactNumberController =
      TextEditingController();
  final TextEditingController installerEmailController =
      TextEditingController();
  final TextEditingController siteDescriptionController =
      TextEditingController();
  final TextEditingController panelNameController = TextEditingController(
    text: '',
  );

  SiteFormData siteData = SiteFormData();
  PanelFormData panelData = PanelFormData();
  ZoneSettingsData zoneSettings = ZoneSettingsData();
  SounderData sounderData = SounderData();
  RelayData relayData = RelayData();

  Map<String, String> validationErrors = {};

  bool createProjectPanelBleVerified = false;

  DiscoveredDevice? connectedDevice;

  bool skippedPanelConnect = false;

  String manualPanelId = '';

  void setCreateProjectPanelBleVerified(bool value) {
    createProjectPanelBleVerified = value;
    update();
  }

  void setConnectedDevice(DiscoveredDevice? device) {
    connectedDevice = device;
    update();
  }

  void setSkippedPanelConnect({required bool skipped, String? panelId}) {
    skippedPanelConnect = skipped;
    manualPanelId = skipped ? (panelId ?? '').trim() : '';
    if (skipped) {
      createProjectPanelBleVerified = false;
      connectedDevice = null;
    }
    update();
  }

  void clearSkippedPanelConnect() {
    skippedPanelConnect = false;
    manualPanelId = '';
    update();
  }

  CreateProjectController() {
    _initializeControllerListeners();
    if (PanelTypeConfig.availablePanels.length == 1) {
      updatePanelType(PanelTypeConfig.availablePanels.first.typeName);
    }
  }

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
    update();
  }

  bool validateStep(int step) {
    validationErrors.clear();

    if (step == 1) {
      if (siteNameController.text.trim().isEmpty) {
        validationErrors[StringConstants.sitename] =
            StringConstants.siteNameRequired;
      }
      if (saqccRegNumberController.text.trim().isEmpty) {
        validationErrors[StringConstants.saqccregnumber] =
            StringConstants.saqccRegNumberRequired;
      }
    } else if (step == 2) {
      if (panelNameController.text.trim().isEmpty) {
        validationErrors[StringConstants.panelname] =
            StringConstants.panelNameRequired;
      }
      if (panelData.selectedPanelType == null) {
        validationErrors[StringConstants.paneltype] =
            StringConstants.panelTypeRequired;
      }
    }

    if (validationErrors.isNotEmpty) {
      update();
      return false;
    }

    return true;
  }

  void clearValidationErrors() {
    validationErrors.clear();
    update();
  }

  @override
  void onClose() {
    siteNameController.dispose();
    installerNameController.dispose();
    companyNameController.dispose();
    saqccRegNumberController.dispose();
    buildingNameController.dispose();
    installerContactNumberController.dispose();
    installerEmailController.dispose();
    siteDescriptionController.dispose();
    panelNameController.dispose();
    super.onClose();
  }
}
