import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_step_form_shell.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_validated_field.dart';
import 'package:techno_switch_solar_app/models/create_project/site_creation_page_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SiteCreationForm extends StatelessWidget {
  const SiteCreationForm({super.key, required this.model});

  final SiteCreationPageModel model;

  static const _fieldSpacing = SizedBox(height: 20);

  @override
  Widget build(BuildContext context) {
    final errors = model.validationErrors;

    return CreateProjectStepFormShell(
      title: StringConstants.siteCreation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateProjectValidatedField(
            label: StringConstants.siteName,
            controller: model.siteNameController,
            hintText: UiStrings.enterSiteNameHint,
            validationKey: StringConstants.sitename,
            validationErrors: errors,
            isRequired: true,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.installerName,
            controller: model.installerNameController,
            hintText: UiStrings.enterInstallerNameHint,
            validationKey: StringConstants.installername,
            validationErrors: errors,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.companyName,
            controller: model.companyNameController,
            hintText: UiStrings.enterCompanyNameHint,
            validationKey: StringConstants.companyname,
            validationErrors: errors,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.saqccRegistrationNumber,
            controller: model.saqccRegNumberController,
            hintText: UiStrings.enterSaqccRegistrationNumberHint,
            validationKey: StringConstants.saqccregnumber,
            validationErrors: errors,
            isRequired: true,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.buildingName,
            controller: model.buildingNameController,
            hintText: UiStrings.enterBuildingNameHint,
            validationKey: StringConstants.buildingname,
            validationErrors: errors,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.installerContactNumber,
            controller: model.installerContactNumberController,
            hintText: UiStrings.enterInstallerContactNumberHint,
            validationKey: StringConstants.installercontactnumber,
            validationErrors: errors,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.installerEmail,
            controller: model.installerEmailController,
            hintText: UiStrings.enterInstallerEmailHint,
            validationKey: StringConstants.installeremail,
            validationErrors: errors,
          ),
          _fieldSpacing,
          CreateProjectValidatedField(
            label: StringConstants.siteDescription,
            controller: model.siteDescriptionController,
            hintText: UiStrings.enterSiteDescriptionHint,
            validationKey: StringConstants.sitedescription,
            validationErrors: errors,
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}
