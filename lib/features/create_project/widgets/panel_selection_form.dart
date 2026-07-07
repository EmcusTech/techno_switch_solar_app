import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_step_form_shell.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/create_project_validated_field.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/panel_type_tile.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_selection_page_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelSelectionForm extends StatelessWidget {
  const PanelSelectionForm({super.key, required this.model});

  final PanelSelectionPageModel model;

  @override
  Widget build(BuildContext context) {
    final errors = model.validationErrors;

    return CreateProjectStepFormShell(
      title: StringConstants.panelSelection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateProjectValidatedField(
            label: StringConstants.panelName,
            controller: model.panelNameController,
            hintText: StringConstants.enterPanelName,
            validationKey: StringConstants.panelname,
            validationErrors: errors,
            isRequired: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: 36),
          CreateProjectFormLabel(
            label: StringConstants.panelType,
            validationKey: StringConstants.paneltype,
            validationErrors: errors,
            isRequired: true,
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              for (var i = 0; i < model.panelTypes.length; i++) ...[
                PanelTypeTile(
                  option: model.panelTypes[i],
                  selectedPanelType: model.selectedPanelType,
                  onPanelTypeChanged: model.onPanelTypeChanged,
                ),
                if (i < model.panelTypes.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
          CreateProjectValidationError(
            validationKey: StringConstants.paneltype,
            validationErrors: errors,
          ),
        ],
      ),
    );
  }
}
