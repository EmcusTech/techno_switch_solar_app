import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';
import 'package:techno_switch_solar_app/features/help/widgets/help_action_row.dart';
import 'package:techno_switch_solar_app/features/help/widgets/help_card.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HelpContactSection extends StatelessWidget {
  const HelpContactSection({super.key, required this.controller});

  final HelpScreenController controller;

  @override
  Widget build(BuildContext context) {
    return HelpCard(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.needImmediateHelp,
            style: StyleConstants.textDark18w600Style,
          ),
          const SizedBox(height: 16),
          HelpActionRow(
            title: StringConstants.callSupport,
            subtitle: StringConstants.s18001234567,
            icon: Icons.phone_outlined,
            onTap: controller.callSupport,
          ),
          const SizedBox(height: 12),
          HelpActionRow(
            title: StringConstants.emailSupport,
            subtitle: StringConstants.supportTechnoswitchCom,
            icon: Icons.email_outlined,
            onTap: controller.emailSupport,
          ),
        ],
      ),
    );
  }
}
