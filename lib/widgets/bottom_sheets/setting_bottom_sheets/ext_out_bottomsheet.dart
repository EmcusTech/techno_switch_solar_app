import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';

class ExtOutBottomSheet extends StatefulWidget {
  final Function() onCall;
  const ExtOutBottomSheet({super.key, required this.onCall});

  @override
  State<ExtOutBottomSheet> createState() => ExtOutBottomSheetState();
}

class ExtOutBottomSheetState extends State<ExtOutBottomSheet> {
  // Dropdown values

  List<String> enabledOptions = ['No', 'Yes'];
  List<String> actuatorTypeOptions = [
    'Not Defined',
    'Metron',
    'Solenoid',
    'Aerosol',
  ];
  List<String> functionOptions = [
    'Z1 and Z2',
    'Z2 and Z3',
    'Z1 and Z3',
    'Z1 and Z2 and Z3',
    'Z1',
    'Z2',
    'Z3',
    'Any 2 zones',
    'Any 1 zone',
  ];
  List<String> resetInCountOptions = ['Yes', 'No'];
  List<String> holdCountOptions = [
    'Disabled',
    'Restart',
    'Suspend',
    'Continue',
  ];
  List<String> actionOptions = [
    'Continously On',
    'Pulse 100ms On',
    'Pulse 300ms On',
    'Pulse 600ms On',
    'Pulse 1s On',
    'Pulse 5s On',
    'Pulsing 100ms On, 500ms Off',
    'Pulsing 300ms On, 1.5s Off',
    'Pulsing 600ms On, 3s Off',
    'Pulsing 1s On, 5s Off',
  ];

  late String enabled;
  late String actuatorType;
  late String function;
  late String resetInCount;
  late String holdCount;
  late String action;

  // Controllers
  late TextEditingController autoCtrl;
  late TextEditingController manCtrl;
  late TextEditingController releaseCtrl;
  late TextEditingController resetDelayCtrl;
  BleManager? manager;

  String? _autoError;
  String? _manError;
  String? _releaseError;
  String? _resetDelayError;

  bool _computeIsValid() {
    final auto = int.tryParse(autoCtrl.text);
    final man = int.tryParse(manCtrl.text);
    final release = int.tryParse(releaseCtrl.text);
    final resetDelay = int.tryParse(resetDelayCtrl.text);

    if (auto == null || auto < 0 || auto > 60) return false;
    if (man == null || man < 0 || man > 60) return false;
    if (release == null || release < 10 || release > 300) return false;
    if (resetDelay == null || resetDelay < 0 || resetDelay > 1800) return false;
    return true;
  }

  void _updateValidationErrors() {
    final auto = int.tryParse(autoCtrl.text);
    final man = int.tryParse(manCtrl.text);
    final release = int.tryParse(releaseCtrl.text);
    final resetDelay = int.tryParse(resetDelayCtrl.text);

    _autoError = (auto == null || auto < 0 || auto > 60)
        ? 'Countdown Auto must be between 0 and 60'
        : null;
    _manError = (man == null || man < 0 || man > 60)
        ? 'Countdown Man must be between 0 and 60'
        : null;
    _releaseError = (release == null || release < 10 || release > 300)
        ? 'Release Time must be between 10 and 300'
        : null;
    _resetDelayError = (resetDelay == null || resetDelay < 0 || resetDelay > 1800)
        ? 'Reset Delay must be between 0 and 1800'
        : null;
  }

  final bleController = Get.find<BleLogController>();

  @override
  void dispose() {
    autoCtrl.dispose();
    manCtrl.dispose();
    releaseCtrl.dispose();
    resetDelayCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    autoCtrl = TextEditingController(text: "10");
    manCtrl = TextEditingController(text: "15");
    releaseCtrl = TextEditingController(text: "10");
    resetDelayCtrl = TextEditingController(text: "5");
    enabled = enabledOptions[0];
    actuatorType = actuatorTypeOptions[0];
    function = functionOptions[0];
    resetInCount = resetInCountOptions[0];
    holdCount = holdCountOptions[0];
    action = actionOptions[0];
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
      autoCtrl.text = manager!.extZoneCountdownAuto.value.toString();
      manCtrl.text = manager!.extZoneCountdownMan.value.toString();
      releaseCtrl.text = manager!.extZoneReleaseTime.value.toString();
      resetDelayCtrl.text = manager!.extZoneResetDelay.value.toString();
      enabled = enabledOptions[manager!.isExtZoneEnabled.value];
      actuatorType = actuatorTypeOptions[manager!.extZoneActuatorType.value];
      function = functionOptions[manager!.extZoneFunction.value];
      resetInCount = resetInCountOptions[manager!.isResetAllowed.value];
      holdCount = holdCountOptions[manager!.extZoneHoldMode.value];
      action = actionOptions[manager!.extZoneAction.value];
    }
    super.initState();
  }

  int returnIndex(String value, List<String> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == value) {
        return i;
      }
    }

    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    _updateValidationErrors();
    final formValid = _computeIsValid();

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _title('Ext Out Configuration'),
                  Visibility(
                    visible:
                        !manager!.bleProcess.isExtOutApplyButtonActive.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        "Source: DIP Mode",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEC1D24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ───────────── Scrollable Content ─────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _dropdown(
                        'Enabled',
                        enabled,
                        enabledOptions,
                        (v) => setState(() => enabled = v),
                      ),

                      // _selectorField(
                      //   label: 'Enabled',
                      //   value: enabled,
                      //   options: ['Yes', 'No'],
                      //   onSelected: (v) => setState(() => enabled = v),
                      // ),
                      _dropdown(
                        'Actuator Type',
                        actuatorType,
                        actuatorTypeOptions,
                        (v) => setState(() => actuatorType = v),
                      ),

                      _dropdown(
                        'Function',
                        function,
                        functionOptions,
                        (v) => setState(() => function = v),
                      ),

                      _numberFieldWithValidation(
                        label: 'Countdown Auto (s)',
                        controller: autoCtrl,
                        errorMsg: _autoError,
                      ),
                      _numberFieldWithValidation(
                        label: 'Countdown Man (s)',
                        controller: manCtrl,
                        errorMsg: _manError,
                      ),
                      _numberFieldWithValidation(
                        label: 'Release Time (s)',
                        controller: releaseCtrl,
                        errorMsg: _releaseError,
                      ),
                      _numberFieldWithValidation(
                        label: 'Reset Delay (s)',
                        controller: resetDelayCtrl,
                        errorMsg: _resetDelayError,
                      ),

                      _dropdown(
                        'Reset in Count',
                        resetInCount,
                        resetInCountOptions,
                        (v) => setState(() => resetInCount = v),
                      ),

                      _dropdown(
                        'Hold / Count',
                        holdCount,
                        holdCountOptions,
                        (v) => setState(() => holdCount = v),
                      ),

                      _dropdown(
                        'Action',
                        action,
                        actionOptions,
                        (v) => setState(() => action = v),
                      ),
                    ],
                  ),
                ),
              ),

              // ───────────── Fixed Footer ─────────────
              const SizedBox(height: 12),
              _primaryButton(context, formValid: formValid),
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

  // Widget _selectorField({
  //   required String label,
  //   required String value,
  //   required List<String> options,
  //   required ValueChanged<String> onSelected,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 14),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _label(label),
  //         const SizedBox(height: 6),
  //         GestureDetector(
  //           onTap: () async {
  //             final selected = await _showOptionSelector(
  //               title: label,
  //               options: options,
  //               selected: value,
  //             );
  //             if (selected != null) {
  //               onSelected(selected);
  //             }
  //           },
  //           child: Container(
  //             height: 48,
  //             padding: const EdgeInsets.symmetric(horizontal: 14),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFFF8F8F8),
  //               borderRadius: BorderRadius.circular(12),
  //               border: Border.all(color: const Color(0xFFD0D0D0)),
  //             ),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     value,
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: const Color(0xFF3D3D3D),
  //                     ),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 const Icon(
  //                   Icons.chevron_right_rounded,
  //                   color: Color(0xFF3D3D3D),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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

  Widget _numberFieldWithValidation({
    required String label,
    required TextEditingController controller,
    required String? errorMsg,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(hasError: errorMsg != null),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
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

  Widget _primaryButton(BuildContext context, {required bool formValid}) {
    final canApply = manager!.bleProcess.isExtOutApplyButtonActive.value;

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
        onPressed: (canApply && formValid)
            ? () {
                  int zoneEnable = returnIndex(enabled, enabledOptions);
                  int holdRestart = returnIndex(holdCount, holdCountOptions);
                  int resetAllowedInt = returnIndex(
                    resetInCount,
                    resetInCountOptions,
                  );
                  int functionInt = returnIndex(function, functionOptions);
                  int actuaturTypeInt = returnIndex(
                    actuatorType,
                    actuatorTypeOptions,
                  );
                  bool resetAllowed = false;
                  if (resetAllowedInt == 0) {
                    resetAllowed = true;
                  }

                  final config = ExtZoneModeConfig(
                    extZoneEnable: ExtZoneEnable.values[zoneEnable],
                    extZoneMode: ExtZoneMode.normal,
                    holdMode: HoldMode.values[holdRestart],
                    resetAllowed: resetAllowed,
                    flowDetectionUsed: false,
                  );

                  final String hexValue = ExtZoneModeCodec.encodeHex(config);

                  manager!.extZoneMode.value = hexValue;

                  manager!.extZoneCountdownAuto.value = int.parse(
                    autoCtrl.text.isEmpty ? '0' : autoCtrl.text,
                  );

                  manager!.extZoneCountdownMan.value = int.parse(
                    manCtrl.text,
                  );

                  manager!.extZoneReleaseTime.value = int.parse(
                    releaseCtrl.text,
                  );

                  manager!.extZoneResetDelay.value = int.parse(
                    resetDelayCtrl.text,
                  );

                  manager!.extZoneAction.value = returnIndex(
                    action,
                    actionOptions,
                  );

                  manager!.extZoneFunction.value = functionInt;

                  manager!.extZoneActuatorType.value = actuaturTypeInt;
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
