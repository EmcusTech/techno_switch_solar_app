import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/panel_selection_form.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_selection_page_model.dart';

class PanelSelectionPage extends GetView<CreateProjectController> {
  const PanelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateProjectController>(
      builder:
          (c) => PanelSelectionForm(
            model: PanelSelectionPageModel(
              panelNameController: c.panelNameController,
              selectedPanelType: c.panelData.selectedPanelType,
              validationErrors: c.validationErrors,
              panelTypes: c.availablePanelTypeOptions,
              onPanelTypeChanged: c.updatePanelType,
            ),
          ),
    );
  }
}
