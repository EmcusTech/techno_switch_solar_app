import 'package:flutter/material.dart';
import 'package:Technoswitch/features/help/controllers/help_screen_controller.dart';
import 'package:Technoswitch/features/help/widgets/help_action_row.dart';
import 'package:Technoswitch/features/help/widgets/help_card.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class HelpSupportLinksSection extends StatelessWidget {
  const HelpSupportLinksSection({super.key, required this.controller});

  final HelpScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.additionalSupport,
            style: StyleConstants.textDark18w600Style,
          ),
          const SizedBox(height: 16),
          HelpCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: HelpActionRow(
              title: StringConstants.userManual,
              subtitle: StringConstants.accessOurComprehensiveUserManual,
              icon: Icons.menu_book_outlined,
              onTap: controller.openUserManual,
              showChevron: true,
            ),
          ),
          HelpCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: HelpActionRow(
              title: StringConstants.videoTutorials,
              subtitle: StringConstants.watchStepByStepVideoGuides,
              icon: Icons.play_circle_outline,
              onTap: controller.openVideoTutorials,
              showChevron: true,
            ),
          ),
          HelpCard(
            padding: const EdgeInsets.all(16),
            child: HelpActionRow(
              title: StringConstants.communityForum,
              subtitle: StringConstants.joinOurCommunityDiscussions,
              icon: Icons.forum_outlined,
              onTap: controller.openCommunityForum,
              showChevron: true,
            ),
          ),
        ],
      ),
    );
  }
}
