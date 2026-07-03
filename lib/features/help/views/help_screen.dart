import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/help/models/help_faq_item.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HelpScreen extends GetView<HelpScreenController> {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _HelpPageHost(controller: controller);
  }
}

class _HelpPageHost extends StatefulWidget {
  const _HelpPageHost({required this.controller});

  final HelpScreenController controller;

  @override
  State<_HelpPageHost> createState() => _HelpPageHostState();
}

class _HelpPageHostState extends State<_HelpPageHost>
    implements HelpScreenUiDelegate {
  HelpScreenController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  Future<void> launchPhone(String phoneNumber) async {
    // Plug in url_launcher when enabling the Help tab:
    // await launchUrl(Uri.parse('tel:${phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '')}'));
  }

  @override
  Future<void> launchEmail(String email) async {
    // Plug in url_launcher when enabling the Help tab:
    // await launchUrl(Uri.parse('mailto:$email'));
  }

  @override
  Future<void> launchExternalUrl(String url) async {
    // Plug in url_launcher when enabling the Help tab:
    // await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    super.dispose();
  }

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
                style: StyleConstants.textDark24w700Style,
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
            style: StyleConstants.textDark18w600Style,
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            StringConstants.callSupport,
            Icons.phone_outlined,
            StringConstants.s18001234567,
            _controller.callSupport,
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            StringConstants.emailSupport,
            Icons.email_outlined,
            StringConstants.supportTechnoswitchCom,
            _controller.emailSupport,
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
            style: StyleConstants.textDark18w600Style,
          ),
        ),
        for (final item in HelpScreenController.faqItems) _buildFAQItem(item),
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
            style: StyleConstants.textDark18w600Style,
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            StringConstants.userManual,
            Icons.menu_book_outlined,
            StringConstants.accessOurComprehensiveUserManual,
            _controller.openUserManual,
          ),
          _buildSupportOption(
            StringConstants.videoTutorials,
            Icons.play_circle_outline,
            StringConstants.watchStepByStepVideoGuides,
            _controller.openVideoTutorials,
          ),
          _buildSupportOption(
            StringConstants.communityForum,
            Icons.forum_outlined,
            StringConstants.joinOurCommunityDiscussions,
            _controller.openCommunityForum,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
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
                style: StyleConstants.textDark16w500Style,
              ),
              Text(
                subtitle,
                style: StyleConstants.textGray14w400Style,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(HelpFaqItem item) {
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
          item.question,
          style: StyleConstants.textDark16w500Style,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer,
              style: StyleConstants.textGray14w400Style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
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
                    style: StyleConstants.textDark16w500Style,
                  ),
                  Text(
                    subtitle,
                    style: StyleConstants.textGray14w400Style,
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
