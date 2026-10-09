import 'package:flutter/material.dart';
import 'package:Technoswitch/features/create_project/widgets/create_project_step_form_shell.dart';
import 'package:Technoswitch/features/create_project/widgets/create_project_validated_field.dart';
import 'package:Technoswitch/models/create_project/site_creation_page_model.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

class SiteCreationForm extends StatelessWidget {
  const SiteCreationForm({super.key, required this.model});

  final SiteCreationPageModel model;

  @override
  Widget build(BuildContext context) {
    final errors = model.validationErrors;

    return CreateProjectStepFormShell(
      title: StringConstants.siteCreation,
      child: peripheralSheetFieldGrid([
        _field(
          CreateProjectValidatedField(
            label: StringConstants.siteName,
            controller: model.siteNameController,
            hintText: UiStrings.enterSiteNameHint,
            validationKey: StringConstants.sitename,
            validationErrors: errors,
            isRequired: true,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.installerName,
            controller: model.installerNameController,
            hintText: UiStrings.enterInstallerNameHint,
            validationKey: StringConstants.installername,
            validationErrors: errors,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.companyName,
            controller: model.companyNameController,
            hintText: UiStrings.enterCompanyNameHint,
            validationKey: StringConstants.companyname,
            validationErrors: errors,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.saqccRegistrationNumber,
            controller: model.saqccRegNumberController,
            hintText: UiStrings.enterSaqccRegistrationNumberHint,
            validationKey: StringConstants.saqccregnumber,
            validationErrors: errors,
            isRequired: true,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.buildingName,
            controller: model.buildingNameController,
            hintText: UiStrings.enterBuildingNameHint,
            validationKey: StringConstants.buildingname,
            validationErrors: errors,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.installerContactNumber,
            controller: model.installerContactNumberController,
            hintText: UiStrings.enterInstallerContactNumberHint,
            validationKey: StringConstants.installercontactnumber,
            validationErrors: errors,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.installerEmail,
            controller: model.installerEmailController,
            hintText: UiStrings.enterInstallerEmailHint,
            validationKey: StringConstants.installeremail,
            validationErrors: errors,
          ),
        ),
        _field(
          CreateProjectValidatedField(
            label: StringConstants.siteDescription,
            controller: model.siteDescriptionController,
            hintText: UiStrings.enterSiteDescriptionHint,
            validationKey: StringConstants.sitedescription,
            validationErrors: errors,
            maxLines: 5,
          ),
        ),
      ]),
    );
  }

  Widget _field(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: child,
    );
  }
}
