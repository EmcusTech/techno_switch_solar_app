import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/help/controllers/help_screen_controller.dart';
import 'package:Technoswitch/features/help/views/help_ui_delegate_mixin.dart';
import 'package:Technoswitch/features/help/widgets/help_contact_section.dart';
import 'package:Technoswitch/features/help/widgets/help_faq_section.dart';
import 'package:Technoswitch/features/help/widgets/help_shell.dart';
import 'package:Technoswitch/features/help/widgets/help_support_links_section.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with HelpUiDelegateMixin {
  late final HelpScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<HelpScreenController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HelpShell(
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
          HelpContactSection(controller: _controller),
          HelpFaqSection(items: HelpScreenController.faqItems),
          HelpSupportLinksSection(controller: _controller),
        ],
      ),
    );
  }
}
