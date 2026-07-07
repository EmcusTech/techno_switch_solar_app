import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/help/models/help_faq_item.dart';
import 'package:techno_switch_solar_app/features/help/widgets/help_card.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HelpFaqSection extends StatelessWidget {
  const HelpFaqSection({super.key, required this.items});

  final List<HelpFaqItem> items;

  @override
  Widget build(BuildContext context) {
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
        for (final item in items) _HelpFaqItemTile(item: item),
      ],
    );
  }
}

class _HelpFaqItemTile extends StatelessWidget {
  const _HelpFaqItemTile({required this.item});

  final HelpFaqItem item;

  @override
  Widget build(BuildContext context) {
    return HelpCard(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(item.question, style: StyleConstants.textDark16w500Style),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(item.answer, style: StyleConstants.textGray14w400Style),
          ),
        ],
      ),
    );
  }
}
