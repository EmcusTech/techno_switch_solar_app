import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ExtOutBottomSheet extends StatefulWidget {
  const ExtOutBottomSheet({super.key});

  @override
  State<ExtOutBottomSheet> createState() => ExtOutBottomSheetState();
}

class ExtOutBottomSheetState extends State<ExtOutBottomSheet> {
  // Dropdown values
  String enabled = 'Yes';
  String actuatorType = 'Not Defined';
  String function = 'Z1 and Z2';
  String resetInCount = 'Yes';
  String holdCount = 'Disabled';
  String action = 'Pulse 100ms On';

  // Controllers
  final autoCtrl = TextEditingController();
  final manCtrl = TextEditingController();
  final releaseCtrl = TextEditingController();
  final resetDelayCtrl = TextEditingController();

  @override
  void dispose() {
    autoCtrl.dispose();
    manCtrl.dispose();
    releaseCtrl.dispose();
    resetDelayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              // ───────────── Fixed Header ─────────────
              _dragHandle(),
              _title('Ext Out Configuration'),

              // ───────────── Scrollable Content ─────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _dropdown('Enabled', enabled, [
                        'Yes',
                        'No',
                      ], (v) => setState(() => enabled = v)),

                      // _selectorField(
                      //   label: 'Enabled',
                      //   value: enabled,
                      //   options: ['Yes', 'No'],
                      //   onSelected: (v) => setState(() => enabled = v),
                      // ),
                      _dropdown(
                        'Actuator Type',
                        actuatorType,
                        ['Not Defined', 'Metron', 'Solenoid', 'Aerosol'],
                        (v) => setState(() => actuatorType = v),
                      ),

                      _dropdown('Function', function, [
                        'Z1 and Z2',
                        'Z2 and Z3',
                        'Z1 and Z3',
                        'Z1 and Z2 and Z3',
                        'Z1',
                        'Z2',
                        'Z3',
                        'Any 2 zones',
                        'Any 1 zone',
                      ], (v) => setState(() => function = v)),

                      _numberField('Countdown Auto (s)', autoCtrl),
                      _numberField('Countdown Man (s)', manCtrl),
                      _numberField('Release Time (s)', releaseCtrl),
                      _numberField('Reset Delay (s)', resetDelayCtrl),

                      _dropdown(
                        'Reset in Count',
                        resetInCount,
                        ['Yes', 'No'],
                        (v) => setState(() => resetInCount = v),
                      ),

                      _dropdown(
                        'Hold / Count',
                        holdCount,
                        ['Disabled', 'Restart', 'Suspend', 'Continue'],
                        (v) => setState(() => holdCount = v),
                      ),

                      _dropdown('Action', action, [
                        'Pulse 100ms On',
                        'Pulse 300ms On',
                        'Pulse 600ms On',
                        'Pulse 1s On',
                        'Pulse 5s On',
                        'Pulsing 100ms On, 500ms Off',
                        'Pulsing 300ms On, 1.5s Off',
                        'Pulsing 600ms On, 3s Off',
                        'Pulsing 1s On, 3s Off',
                      ], (v) => setState(() => action = v)),
                    ],
                  ),
                ),
              ),

              // ───────────── Fixed Footer ─────────────
              const SizedBox(height: 12),
              _primaryButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI Helpers ----------

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D3D3D),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF3D3D3D),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
              items:
                  items
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged: (v) => onChanged(v!),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD0D0D0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD0D0D0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEC1D24),
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white,
              menuMaxHeight: 280,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final selected = await _showOptionSelector(
                title: label,
                options: options,
                selected: value,
              );
              if (selected != null) {
                onSelected(selected);
              }
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD0D0D0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3D3D3D),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF3D3D3D),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showOptionSelector({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _dragHandle(),
                  _title(title),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final option = options[index];
                        final isSelected = option == selected;

                        return ListTile(
                          onTap: () {
                            Navigator.of(context).pop(option);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(
                            option,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color: const Color(0xFF3D3D3D),
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFEC1D24),
                                  )
                                  : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D3D3D),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEC1D24), width: 2),
      ),
    );
  }

  Widget _primaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(
          'Apply Configuration',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
