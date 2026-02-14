import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class InputModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const InputModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

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
    _inputTextError =
        inputTextCtrl.text.length > 21
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
    _loadData();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    inputTextCtrl.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await PeripheralSetupCache.loadInputSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    final g = (data['group'] as int?) ?? 0;
    group = groupOptions[g.clamp(0, groupOptions.length - 1)];
    final f = (data['function'] as int?) ?? 0;
    final opts = functionOptionsMap[group]!;
    function = opts[f.clamp(0, opts.length - 1)];
    enabled = (data['enabled'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    test = (data['test'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    inverted = (data['inverted'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    inputTextCtrl.text = (data['text'] as String?) ?? '';
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    group = groupOptions[manager!.inputSetupGroup.value];
    function = functionOptionsMap[group]![manager!.inputSetupFunction.value];
    enabled = manager!.isInputSetupEnabled.value ? yesNoOptions[1] : yesNoOptions[0];
    test = manager!.isInputSetupTest.value ? yesNoOptions[1] : yesNoOptions[0];
    inverted = manager!.isInputSetupInverted.value ? yesNoOptions[1] : yesNoOptions[0];
    inputTextCtrl.text = manager!.inputSetupText.value;
    if (mounted) setState(() {});
  }

  int returnIndex(String value, List<String> list) {
    return list.indexOf(value);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
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
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction != ScrollDirection.idle) {
                      FocusScope.of(context).unfocus();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        _readOnlyField('Input', 'PROG IN 1'),

                        _inputTextField(),

                        DropdownWidget(
                          label: 'Group',
                          value: group,
                          items: groupOptions,
                          onChanged: (v) {
                            setState(() {
                              group = v;
                              function =
                                  functionOptionsMap[group]!
                                      .first; // reset function
                            });
                          },
                        ),

                        DropdownWidget(
                          label: 'Function',
                          value: function,
                          items: functionOptionsMap[group]!,
                          onChanged: (v) => setState(() => function = v),
                        ),

                        DropdownWidget(
                          label: 'Enabled',
                          value: enabled,
                          items: yesNoOptions,
                          onChanged: (v) {
                            setState(() {
                              enabled = v;

                              // RULE: If Enabled = No → Test must be No
                              if (enabled == 'No') {
                                test = 'No';
                              }
                            });
                          },
                        ),

                        DropdownWidget(
                          label: 'Test',
                          value: test,
                          items: yesNoOptions,
                          onChanged: (v) {
                            setState(() {
                              test = v;

                              // RULE: If Test = Yes → Enabled must be Yes
                              if (test == 'Yes') {
                                enabled = 'Yes';
                              }
                            });
                          },
                        ),

                        DropdownWidget(
                          label: 'Inverted',
                          value: inverted,
                          items: yesNoOptions,
                          onChanged: (v) => setState(() => inverted = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _downloadButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _applyButton(isValid: isValid)),
                ],
              ),
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
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3D3D3D),
                ),
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
            maxLength: 21,
            buildCounter: (
              context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              if (!isFocused) return null;

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "$currentLength / 21",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        currentLength == 21
                            ? const Color(0xFFEC1D24)
                            : Colors.grey,
                  ),
                ),
              );
            },
            inputFormatters: [LengthLimitingTextInputFormatter(21)],
            // onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hasError: _inputTextError != null),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3D3D3D),
            ),
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

  // Widget _dropdown(
  //   String label,
  //   String value,
  //   List<String> items,
  //   ValueChanged<String> onChanged,
  // ) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 14),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _label(label),
  //         const SizedBox(height: 6),
  //         SizedBox(
  //           height: 48,
  //           child: DropdownButtonFormField2<String>(
  //             isExpanded: true,
  //             value: value,

  //             items:
  //                 items
  //                     .map(
  //                       (e) => DropdownMenuItem<String>(
  //                         value: e,
  //                         child: Text(
  //                           e,
  //                           overflow: TextOverflow.ellipsis,
  //                           style: GoogleFonts.inter(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.w500,
  //                             color: const Color(0xFF3D3D3D),
  //                           ),
  //                         ),
  //                       ),
  //                     )
  //                     .toList(),

  //             onChanged: (v) => onChanged(v!),

  //             // 🔥 REMOVE horizontal padding from buttonStyleData
  //             buttonStyleData: ButtonStyleData(
  //               height: 48,
  //               padding: EdgeInsets.zero,
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFF8F8F8),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //             ),

  //             iconStyleData: const IconStyleData(
  //               icon: Icon(
  //                 Icons.keyboard_arrow_down_rounded,
  //                 color: Color(0xFF3D3D3D),
  //               ),
  //               iconSize: 22,
  //             ),

  //             dropdownStyleData: DropdownStyleData(
  //               maxHeight: 280,
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               elevation: 4,
  //             ),

  //             menuItemStyleData: const MenuItemStyleData(
  //               height: 40,
  //               padding: EdgeInsets.symmetric(horizontal: 14),
  //             ),

  //             // 🔥 CONTROL ALL PADDING HERE ONLY
  //             decoration: InputDecoration(
  //               filled: true,
  //               fillColor: const Color(0xFFF8F8F8),
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 14,
  //                 vertical: 12,
  //               ),

  //               enabledBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //                 borderSide: const BorderSide(
  //                   color: Color(0xFFD0D0D0),
  //                   width: 1,
  //                 ),
  //               ),

  //               focusedBorder: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //                 borderSide: const BorderSide(
  //                   color: Color(0xFFEC1D24),
  //                   width: 2,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? const Color(0xFFEC1D24) : const Color(0xFFD0D0D0);

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),

      // 🔥 SAME 24px HORIZONTAL
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

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

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEC1D24),
          side: const BorderSide(color: Color(0xFFEC1D24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: widget.onDownload,
        child: Text(
          'Download',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _applyButton({required bool isValid}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            isValid && manager != null
                ? () {
                  int groupIndex = returnIndex(group, groupOptions);
                  int functionIndex = returnIndex(
                    function,
                    functionOptionsMap[group]!,
                  );
                  bool isEnabled = enabled == 'Yes';
                  bool isTest = test == 'Yes';
                  bool isInverted = inverted == 'Yes';

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

                  widget.onApply();
                }
                : null,
        child: Text(
          'Apply',
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
