import 'package:flutter/material.dart';

class SiteCreationPageModel {
  final TextEditingController siteNameController;
  final TextEditingController installerNameController;
  final TextEditingController companyNameController;
  final TextEditingController saqccRegNumberController;
  final TextEditingController buildingNameController;
  final TextEditingController installerContactNumberController;
  final TextEditingController installerEmailController;
  final TextEditingController siteDescriptionController;
  final Map<String, String>? validationErrors;

  SiteCreationPageModel({
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

  SiteCreationPageModel copyWith({
    TextEditingController? siteNameController,
    TextEditingController? installerNameController,
    TextEditingController? companyNameController,
    TextEditingController? saqccRegNumberController,
    TextEditingController? buildingNameController,
    TextEditingController? installerContactNumberController,
    TextEditingController? installerEmailController,
    TextEditingController? siteDescriptionController,
    Map<String, String>? validationErrors,
  }) {
    return SiteCreationPageModel(
      siteNameController: siteNameController ?? this.siteNameController,
      installerNameController:
          installerNameController ?? this.installerNameController,
      companyNameController:
          companyNameController ?? this.companyNameController,
      saqccRegNumberController:
          saqccRegNumberController ?? this.saqccRegNumberController,
      buildingNameController:
          buildingNameController ?? this.buildingNameController,
      installerContactNumberController:
          installerContactNumberController ??
          this.installerContactNumberController,
      installerEmailController:
          installerEmailController ?? this.installerEmailController,
      siteDescriptionController:
          siteDescriptionController ?? this.siteDescriptionController,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}
