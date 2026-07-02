import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/models/create_project/site_creation_page_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteCreationForm extends StatelessWidget {
  const SiteCreationForm({super.key, required this.model});

  final SiteCreationPageModel model;

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? validationKey,
    int? maxLines = 1,
    bool isRequired = false,
  }) {
    final hasError = model.validationErrors?.containsKey(validationKey) == true;
    final errorMessage = model.validationErrors?[validationKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: StyleConstants.primary13w600Style.copyWith(
                  color:
                      hasError
                          ? ColorConstants.primary
                          : ColorConstants.textSecondary,
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: StringConstants.strb411bc68,
                  style: StyleConstants.primary13w600Style,
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  hasError ? ColorConstants.primary : ColorConstants.borderGray,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onTapOutside: (value) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: StyleConstants.divider13w400Style,
            ),
          ),
        ),
        if (hasError && errorMessage != null) ...[
          SizedBox(height: 4),
          Text(errorMessage, style: StyleConstants.primary12w500Style),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.siteCreation,
            style: StyleConstants.textBodyDark18w600Style,
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Site Name',
                    controller: model.siteNameController,
                    hintText: 'Enter Site Name',
                    validationKey: StringConstants.sitename,
                    isRequired: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.installerName,
                    controller: model.installerNameController,
                    hintText: 'Enter Installer Name',
                    validationKey: StringConstants.installername,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.companyName,
                    controller: model.companyNameController,
                    hintText: 'Enter Company Name',
                    validationKey: StringConstants.companyname,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.saqccRegistrationNumber,
                    controller: model.saqccRegNumberController,
                    hintText: 'Enter SAQCC Registration Number',
                    validationKey: StringConstants.saqccregnumber,
                    isRequired: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.buildingName,
                    controller: model.buildingNameController,
                    hintText: 'Enter Building Name',
                    validationKey: StringConstants.buildingname,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.installerContactNumber,
                    controller: model.installerContactNumberController,
                    hintText: 'Enter Installer Contact Number',
                    validationKey: StringConstants.installercontactnumber,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.installerEmail,
                    controller: model.installerEmailController,
                    hintText: 'Enter Installer Email',
                    validationKey: StringConstants.installeremail,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    label: StringConstants.siteDescription,
                    controller: model.siteDescriptionController,
                    hintText: 'Enter Site Description',
                    validationKey: StringConstants.sitedescription,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SiteCreationPage extends GetView<CreateProjectController> {
  const SiteCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateProjectController>(
      builder:
          (c) => SiteCreationForm(
            model: SiteCreationPageModel(
              siteNameController: c.siteNameController,
              installerNameController: c.installerNameController,
              companyNameController: c.companyNameController,
              saqccRegNumberController: c.saqccRegNumberController,
              buildingNameController: c.buildingNameController,
              installerContactNumberController:
                  c.installerContactNumberController,
              installerEmailController: c.installerEmailController,
              siteDescriptionController: c.siteDescriptionController,
              validationErrors: c.validationErrors,
            ),
          ),
    );
  }
}
