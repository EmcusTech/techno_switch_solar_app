import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';

class InputModeBottomSheet extends StatefulWidget {
  final Function() onCall;

  const InputModeBottomSheet({super.key, required this.onCall});

  @override
  State<InputModeBottomSheet> createState() => _InputModeBottomSheetState();
}

class _InputModeBottomSheetState extends State<InputModeBottomSheet> {
  // ───────────── Dropdown Options ─────────────

  final List<String> groupOptions = ['None', 'General', 'Ext. Out'];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      'Extnl. Fault',
      'Reset',
      'Extnl. Controls Enabled',
      'Silence Alarm',
      'Sound Alarm',
      'Silence Buzzer',
      'Mute',
      'Extnl. Supervisory',
      'Extnl. Supply Fault',
    ],
    'Ext. Out': [
      'Manual Trigger',
      'Manual Mode',
      'Hold',
      'Extnl. Disable Gas',
      'Extnl. Ext. Fault',
    ],
  };

  final List<String> yesNoOptions = ['No', 'Yes'];

  // ───────────── Selected Values ─────────────

  late String group;
  late String function;
  late String enabled;
  late String test;
  late String inverted;

  late TextEditingController inputTextCtrl;

  BleManager? manager;

  String? _inputTextError;

  bool _computeIsValid() {
    return inputTextCtrl.text.length <= 21;
  }

  void _updateValidationErrors() {
    _inputTextError = inputTextCtrl.text.length > 21
        ? 'Input text must be at most 21 characters (currently ${inputTextCtrl.text.length})'
        : null;
  }

  @override
  void initState() {
    super.initState();

    group = groupOptions[0];
    function = functionOptionsMap[group]!.first;
    enabled = yesNoOptions[0];
    test = yesNoOptions[0];
    inverted = yesNoOptions[0];

    inputTextCtrl = TextEditingController();

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;

      print("Input Setup Group: ${manager!.inputSetupGroup.value}");
      group = groupOptions[manager!.inputSetupGroup.value];
      function = functionOptionsMap[group]![manager!.inputSetupFunction.value];
      enabled =
          manager!.isInputSetupEnabled.value
              ? yesNoOptions[1]
              : yesNoOptions[0];
      test =
          manager!.isInputSetupTest.value ? yesNoOptions[1] : yesNoOptions[0];
      inverted =
          manager!.isInputSetupInverted.value
              ? yesNoOptions[1]
              : yesNoOptions[0];

      inputTextCtrl.text = manager!.inputSetupText.value;
    }
  }

  @override
  void dispose() {
    inputTextCtrl.dispose();
    super.dispose();
  }

  int returnIndex(String value, List<String> list) {
    return list.indexOf(value);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    _updateValidationErrors();
    final isValid = _computeIsValid();

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
              _dragHandle(),
              _title('Input Mode Configuration'),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _readOnlyField('Input', 'PROG IN 1'),

                      _inputTextField(),

                      _dropdown('Group', group, groupOptions, (v) {
                        setState(() {
                          group = v;
                          function =
                              functionOptionsMap[group]!
                                  .first; // reset function
                        });
                      }),

                      _dropdown(
                        'Function',
                        function,
                        functionOptionsMap[group]!,
                        (v) => setState(() => function = v),
                      ),

                      _dropdown('Enabled', enabled, yesNoOptions, (v) {
                        setState(() {
                          enabled = v;

                          // RULE: If Enabled = No → Test must be No
                          if (enabled == 'No') {
                            test = 'No';
                          }
                        });
                      }),

                      _dropdown('Test', test, yesNoOptions, (v) {
                        setState(() {
                          test = v;

                          // RULE: If Test = Yes → Enabled must be Yes
                          if (test == 'Yes') {
                            enabled = 'Yes';
                          }
                        });
                      }),

                      _dropdown(
                        'Inverted',
                        inverted,
                        yesNoOptions,
                        (v) => setState(() => inverted = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _primaryButton(isValid: isValid),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── UI HELPERS ─────────────

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

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputTextField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Input Text'),
          const SizedBox(height: 6),
          TextField(
            controller: inputTextCtrl,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hasError: _inputTextError != null),
          ),
          if (_inputTextError != null) ...[
            const SizedBox(height: 4),
            Text(
              _inputTextError!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEC1D24),
              ),
            ),
          ],
        ],
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
              decoration: _inputDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? const Color(0xFFEC1D24) : const Color(0xFFD0D0D0);
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEC1D24), width: 2),
      ),
    );
  }

  Widget _primaryButton({required bool isValid}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: isValid
            ? () {
          // Example processing logic
          int groupIndex = returnIndex(group, groupOptions);
          int functionIndex = returnIndex(function, functionOptionsMap[group]!);
          bool isEnabled = enabled == 'Yes';
          bool isTest = test == 'Yes';
          bool isInverted = inverted == 'Yes';

          print("Group Index: $groupIndex");
          print("Function Index: $functionIndex");
          print("Enabled: $isEnabled");
          print("Test: $isTest");
          print("Inverted: $isInverted");

          // required this.inputEnable,
          // required this.inputMode,
          // required this.latchMode,
          // required this.invertMode,

          final config = InputModeConfig(
            inputEnable: InputEnable.values[isEnabled ? 1 : 0],
            inputMode: InputMode.values[isTest ? 1 : 0],
            latchMode: LatchMode.nonLatched,
            invertMode: InvertMode.values[isInverted ? 1 : 0],
          );

          final String hexValue = InputModeCodec.encodeHex(config);

          manager!.inputMode.value = hexValue;

          manager!.inputSetupGroup.value = groupIndex;
          manager!.inputSetupFunction.value = functionIndex;
          manager!.isInputSetupEnabled.value = isEnabled;
          manager!.isInputSetupTest.value = isTest;
          manager!.isInputSetupInverted.value = isInverted;
          manager!.inputSetupText.value = inputTextCtrl.text;

          Navigator.pop(context);
          widget.onCall();
        }
            : null,
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
