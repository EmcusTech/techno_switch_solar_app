import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class CommissioningTestItem {
  const CommissioningTestItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// Dialog to record Pass/Fail for each commissioning test item.
Future<Map<String, String>?> showCommissioningTestResultDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<CommissioningTestItem> items,
  Map<String, String>? initialResults,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _CommissioningTestResultDialog(
        title: title,
        subtitle: subtitle,
        items: items,
        initialResults: initialResults ?? const {},
      );
    },
  );
}

class _CommissioningTestResultDialog extends StatefulWidget {
  const _CommissioningTestResultDialog({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.initialResults,
  });

  final String title;
  final String subtitle;
  final List<CommissioningTestItem> items;
  final Map<String, String> initialResults;

  @override
  State<_CommissioningTestResultDialog> createState() =>
      _CommissioningTestResultDialogState();
}

class _CommissioningTestResultDialogState
    extends State<_CommissioningTestResultDialog> {
  late final Map<String, String?> _selections;

  @override
  void initState() {
    super.initState();
    _selections = {
      for (final item in widget.items)
        item.id: widget.initialResults[item.id],
    };
  }

  bool get _allSelected =>
      widget.items.every((item) => _selections[item.id] != null);

  void _setResult(String id, String result) {
    setState(() => _selections[id] = result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 420,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: ColorConstants.errorIconBackground,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.fact_check_outlined,
                  color: ColorConstants.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: StyleConstants.textDark18w700Style,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: StyleConstants.textGray14w400Style,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final item in widget.items) ...[
                      _resultRow(item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorConstants.buttonSecondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: ColorConstants.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          StringConstants.skip,
                          style: StyleConstants.textGray16w600Style,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        _allSelected
                            ? () {
                              final results = <String, String>{};
                              for (final item in widget.items) {
                                final value = _selections[item.id];
                                if (value != null) {
                                  results[item.id] = value;
                                }
                              }
                              Navigator.of(context).pop(results);
                            }
                            : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            _allSelected
                                ? ColorConstants.primary
                                : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          StringConstants.save,
                          style: StyleConstants.white16w600Style,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(CommissioningTestItem item) {
    final selected = _selections[item.id];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: StyleConstants.textDark14w600Style,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _resultChip(
                  label: StringConstants.pass,
                  isSelected: selected == 'pass',
                  selectedColor: ColorConstants.successBackgroundLight,
                  selectedBorder: ColorConstants.successMaterial,
                  onTap: () => _setResult(item.id, 'pass'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultChip(
                  label: StringConstants.fail,
                  isSelected: selected == 'fail',
                  selectedColor: ColorConstants.errorSurface,
                  selectedBorder: ColorConstants.primary,
                  onTap: () => _setResult(item.id, 'fail'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultChip({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required Color selectedBorder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : ColorConstants.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : ColorConstants.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: StyleConstants.textGray14w600Style.copyWith(color: isSelected ? selectedBorder : ColorConstants.textGray),
          ),
        ),
      ),
    );
  }
}
