import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: Text(
                StringConstants.helpSupport,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textDark,
                ),
              ),
            ),
            _buildContactSupport(),
            _buildFAQSection(),
            _buildSupportOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.needImmediateHelp,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            StringConstants.callSupport,
            Icons.phone_outlined,
            StringConstants.s18001234567,
            () {},
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            StringConstants.emailSupport,
            Icons.email_outlined,
            StringConstants.supportTechnoswitchCom,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            StringConstants.frequentlyAskedQuestions,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textDark,
            ),
          ),
        ),
        _buildFAQItem(
          'How do I create a new project?',
          StringConstants.toCreateANewProjectTapOnTheNewProjectQuickLinkOnTheHomeScreenFollowTheStepByStepWizardToSetUpYourProjectDetails,
        ),
        _buildFAQItem(
          'How can I retrieve project logs?',
          StringConstants.youCanRetrieveProjectLogsByTappingTheRetrieveLogQuickLinkOnTheHomeScreenSelectYourProjectAndChooseTheDateRangeForTheLogsYouNeed,
        ),
        _buildFAQItem(
          'What maintenance tasks are available?',
          StringConstants.theMaintenanceSectionProvidesVariousToolsForSystemMaintenanceIncludingSystemChecksUpdatesAndTroubleshootingGuides,
        ),
      ],
    );
  }

  Widget _buildSupportOptions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.additionalSupport,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            StringConstants.userManual,
            Icons.menu_book_outlined,
            StringConstants.accessOurComprehensiveUserManual,
            () {},
          ),
          _buildSupportOption(
            StringConstants.videoTutorials,
            Icons.play_circle_outline,
            StringConstants.watchStepByStepVideoGuides,
            () {},
          ),
          _buildSupportOption(
            StringConstants.communityForum,
            Icons.forum_outlined,
            StringConstants.joinOurCommunityDiscussions,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
      String title, IconData icon, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: ColorConstants.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.textDark,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ColorConstants.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ColorConstants.textDark,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: ColorConstants.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
      String title, IconData icon, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: ColorConstants.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: ColorConstants.textDark,
            ),
          ],
        ),
      ),
    );
  }
} 