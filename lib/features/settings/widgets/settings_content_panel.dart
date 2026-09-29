import 'package:flutter/material.dart';
import 'package:Technoswitch/features/settings/controllers/settings_controller.dart';
import 'package:Technoswitch/features/settings/widgets/settings_menu_list.dart';
import 'package:Technoswitch/features/settings/widgets/settings_panel_header.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class SettingsContentPanel extends StatelessWidget {
  const SettingsContentPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SettingsPanelHeader(controller: controller),
              const SizedBox(height: 10),
              SettingsMenuList(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
