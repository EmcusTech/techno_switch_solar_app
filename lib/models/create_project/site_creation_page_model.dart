import 'package:flutter/material.dart';

class SiteCreationPageModel {
  const SiteCreationPageModel({
    required this.siteNameController,
    required this.installerNameController,
    required this.companyNameController,
    required this.saqccRegNumberController,
    required this.buildingNameController,
    required this.installerContactNumberController,
    required this.installerEmailController,
    required this.siteDescriptionController,
    this.validationErrors,
  });

  final TextEditingController siteNameController;
  final TextEditingController installerNameController;
  final TextEditingController companyNameController;
  final TextEditingController saqccRegNumberController;
  final TextEditingController buildingNameController;
  final TextEditingController installerContactNumberController;
  final TextEditingController installerEmailController;
  final TextEditingController siteDescriptionController;
  final Map<String, String>? validationErrors;
}
