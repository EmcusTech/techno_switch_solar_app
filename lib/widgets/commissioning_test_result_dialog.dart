import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFBDEE1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFFEC1D24),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3D3D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
              ),
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
                        color: const Color(0xFFEFEEEE),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD0D0D0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
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
                                ? const Color(0xFFEC1D24)
                                : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _resultChip(
                  label: 'Pass',
                  isSelected: selected == 'pass',
                  selectedColor: const Color(0xFFE8F5E9),
                  selectedBorder: const Color(0xFF4CAF50),
                  onTap: () => _setResult(item.id, 'pass'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultChip(
                  label: 'Fail',
                  isSelected: selected == 'fail',
                  selectedColor: const Color(0xFFFDECEA),
                  selectedBorder: const Color(0xFFEC1D24),
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
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : const Color(0xFFD0D0D0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? selectedBorder : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
