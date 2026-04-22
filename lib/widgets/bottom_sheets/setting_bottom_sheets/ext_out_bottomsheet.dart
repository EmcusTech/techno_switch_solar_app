import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class ExtOutBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ExtOutBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

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
    'Continous',
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

  final FocusNode autoFocusNode = FocusNode();
  final FocusNode manFocusNode = FocusNode();
  final FocusNode releaseFocusNode = FocusNode();
  final FocusNode resetDelayFocusNode = FocusNode();

  BleManager? manager;

  final String _autoError = "Countdown Auto must be between 0 and 60";
  final String _manError = "Countdown Man must be between 0 and 60";
  final String _releaseError = "Release Time must be between 10 and 300";
  final String _resetDelayError = "Reset Delay must be between 0 and 1800";

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

  // void _updateValidationErrors() {
  //   final auto = int.tryParse(autoCtrl.text);
  //   final man = int.tryParse(manCtrl.text);
  //   final release = int.tryParse(releaseCtrl.text);
  //   final resetDelay = int.tryParse(resetDelayCtrl.text);

  //   _autoError =
  //       (auto == null || auto < 0 || auto > 60)
  //           ? 'Countdown Auto must be between 0 and 60'
  //           : null;
  //   _manError =
  //       (man == null || man < 0 || man > 60)
  //           ? 'Countdown Man must be between 0 and 60'
  //           : null;
  //   _releaseError =
  //       (release == null || release < 10 || release > 300)
  //           ? 'Release Time must be between 10 and 300'
  //           : null;
  //   _resetDelayError =
  //       (resetDelay == null || resetDelay < 0 || resetDelay > 1800)
  //           ? 'Reset Delay must be between 0 and 1800'
  //           : null;
  // }

  final bleController = Get.find<BleLogController>();

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    autoCtrl.dispose();
    manCtrl.dispose();
    releaseCtrl.dispose();
    resetDelayCtrl.dispose();
    autoFocusNode.dispose();
    manFocusNode.dispose();
    releaseFocusNode.dispose();
    resetDelayFocusNode.dispose();
    autoCtrl.dispose();
    manCtrl.dispose();
    releaseCtrl.dispose();
    resetDelayCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
    autoFocusNode.addListener(() {
      if (autoFocusNode.hasFocus) {
        debugPrint("Auto field is focused");
      } else {
        debugPrint("Auto field lost focus");
      }
    });
    manFocusNode.addListener(() {
      if (manFocusNode.hasFocus) {
        debugPrint("Man field is focused");
      } else {
        debugPrint("Man field lost focus");
      }
    });
    releaseFocusNode.addListener(() {
      if (releaseFocusNode.hasFocus) {
        debugPrint("Release field is focused");
      } else {
        debugPrint("Release field lost focus");
      }
    });
    resetDelayFocusNode.addListener(() {
      if (resetDelayFocusNode.hasFocus) {
        debugPrint("Reset Delay field is focused");
      } else {
        debugPrint("Reset Delay field lost focus");
      }
    });
    _loadData();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await PeripheralSetupCache.loadExtOutSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    final en = (data['enabled'] as int?) ?? 0;
    enabled = enabledOptions[en.clamp(0, enabledOptions.length - 1)];
    final at = (data['actuatorType'] as int?) ?? 0;
    actuatorType =
        actuatorTypeOptions[at.clamp(0, actuatorTypeOptions.length - 1)];
    final fn = (data['function'] as int?) ?? 0;
    function = functionOptions[fn.clamp(0, functionOptions.length - 1)];
    final ra = (data['resetAllowed'] as int?) ?? 0;
    resetInCount =
        resetInCountOptions[ra.clamp(0, resetInCountOptions.length - 1)];
    final hc = (data['holdMode'] as int?) ?? 0;
    holdCount = holdCountOptions[hc.clamp(0, holdCountOptions.length - 1)];
    final ac = (data['action'] as int?) ?? 0;
    action = actionOptions[ac.clamp(0, actionOptions.length - 1)];
    autoCtrl.text = (data['countdownAuto'] as int?)?.toString() ?? '10';
    manCtrl.text = (data['countdownMan'] as int?)?.toString() ?? '15';
    releaseCtrl.text = (data['releaseTime'] as int?)?.toString() ?? '10';
    resetDelayCtrl.text = (data['resetDelay'] as int?)?.toString() ?? '5';
    final solarRaw = data['isSolar'];
    if (manager != null && solarRaw is bool) {
      manager!.bleProcess.isExtOutApplyButtonActive.value = solarRaw;
    }
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
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
    if (mounted) setState(() {});
  }

  int returnIndex(String value, List<String> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == value) {
        return i;
      }
    }

    return -1;
  }

  Widget _modeBadge() {
    if (manager == null) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: manager!.bleProcess.isExtOutApplyButtonActive,
      builder: (context, isSolar, _) {
        final bgColor =
            isSolar ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

        final textColor =
            isSolar ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

        final icon =
            isSolar
                ? Icons.wb_sunny_rounded
                : Icons.settings_input_component_rounded;

        final label = isSolar ? "Solar Mode" : "DIP Mode";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _title('Ext Out Config'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _modeBadge(),
        ),
      ],
    );
  }

  Widget _formFields() {
    return Column(
      children: [
        DropdownWidget(
          label: 'Enabled',
          value: enabled,
          items: enabledOptions,
          onChanged: (v) => setState(() => enabled = v),
        ),
        DropdownWidget(
          label: 'Actuator Type',
          value: actuatorType,
          items: actuatorTypeOptions,
          onChanged: (v) => setState(() => actuatorType = v),
        ),
        DropdownWidget(
          label: 'Function',
          value: function,
          items: functionOptions,
          onChanged: (v) => setState(() => function = v),
        ),
        _numberFieldWithValidation(
          label: 'Countdown Auto (s)',
          controller: autoCtrl,
          errorMsg: _autoError,
          focusNode: autoFocusNode,
        ),
        _numberFieldWithValidation(
          label: 'Countdown Man (s)',
          controller: manCtrl,
          errorMsg: _manError,
          focusNode: manFocusNode,
        ),
        _numberFieldWithValidation(
          label: 'Release Time (s)',
          controller: releaseCtrl,
          errorMsg: _releaseError,
          focusNode: releaseFocusNode,
        ),
        _numberFieldWithValidation(
          label: 'Reset Delay (s)',
          controller: resetDelayCtrl,
          errorMsg: _resetDelayError,
          focusNode: resetDelayFocusNode,
        ),
        DropdownWidget(
          label: 'Reset in Count',
          value: resetInCount,
          items: resetInCountOptions,
          onChanged: (v) => setState(() => resetInCount = v),
        ),
        DropdownWidget(
          label: 'Hold / Count',
          value: holdCount,
          items: holdCountOptions,
          onChanged: (v) => setState(() => holdCount = v),
        ),
        DropdownWidget(
          label: 'Action',
          value: action,
          items: actionOptions,
          onChanged: (v) => setState(() => action = v),
        ),
      ],
    );
  }

  void _pushExtOutToManager() {
    final m = manager!;
    int zoneEnable = returnIndex(enabled, enabledOptions);
    int holdRestart = returnIndex(holdCount, holdCountOptions);
    int resetAllowedInt = returnIndex(resetInCount, resetInCountOptions);
    int functionInt = returnIndex(function, functionOptions);
    int actuaturTypeInt = returnIndex(actuatorType, actuatorTypeOptions);
    bool resetAllowed = resetAllowedInt == 0;

    final config = ExtZoneModeConfig(
      extZoneEnable: ExtZoneEnable.values[zoneEnable],
      extZoneMode: ExtZoneMode.normal,
      holdMode: HoldMode.values[holdRestart],
      resetAllowed: resetAllowed,
      flowDetectionUsed: false,
    );

    final String hexValue = ExtZoneModeCodec.encodeHex(config);

    m.isExtZoneEnabled.value = zoneEnable;
    m.extZoneMode.value = hexValue;
    m.extZoneCountdownAuto.value = int.parse(
      autoCtrl.text.isEmpty ? '0' : autoCtrl.text,
    );
    m.extZoneCountdownMan.value = int.parse(manCtrl.text);
    m.extZoneReleaseTime.value = int.parse(releaseCtrl.text);
    m.extZoneResetDelay.value = int.parse(resetDelayCtrl.text);
    m.extZoneAction.value = returnIndex(action, actionOptions);
    m.extZoneFunction.value = functionInt;
    m.extZoneActuatorType.value = actuaturTypeInt;
  }

  Future<bool> commitLocal() async {
    if (manager == null) return false;
    final formValid = _computeIsValid();
    if (!formValid) return false;
    final canApply = manager!.bleProcess.isExtOutApplyButtonActive.value;
    if (!widget.embedInCreateFlow && !canApply) return false;

    FocusManager.instance.primaryFocus?.unfocus();
    _pushExtOutToManager();
    await PanelConfigCacheSync.saveExtOut(
      manager!,
      widget.deviceId,
      widget.refreshTrigger,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    final formValid = _computeIsValid();

    final scroll = NotificationListener<UserScrollNotification>(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedInCreateFlow) _headerRow(),
            _formFields(),
          ],
        ),
      ),
    );

    if (widget.embedInCreateFlow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: scroll)],
      );
    }

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
              _headerRow(),
              Expanded(child: scroll),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _downloadButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _applyButton(formValid: formValid)),
                ],
              ),
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
  //           child: DropdownButtonFormField<String>(
  //             value: value,
  //             isExpanded: true,
  //             icon: const Icon(
  //               Icons.keyboard_arrow_down_rounded,
  //               color: Color(0xFF3D3D3D),
  //             ),
  //             style: GoogleFonts.inter(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: const Color(0xFF3D3D3D),
  //             ),
  //             items:
  //                 items
  //                     .map(
  //                       (e) => DropdownMenuItem<String>(
  //                         value: e,
  //                         child: Text(e, overflow: TextOverflow.ellipsis),
  //                       ),
  //                     )
  //                     .toList(),
  //             onChanged: (v) => onChanged(v!),
  //             decoration: InputDecoration(
  //               filled: true,
  //               fillColor: const Color(0xFFF8F8F8),
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 14,
  //                 vertical: 12,
  //               ),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //                 borderSide: const BorderSide(
  //                   color: Color(0xFFD0D0D0),
  //                   width: 1,
  //                 ),
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
  //             dropdownColor: Colors.white,
  //             menuMaxHeight: 280,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
    required String errorMsg,
    required FocusNode focusNode,
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
            focusNode: focusNode,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(),
          ),
          if (focusNode.hasFocus) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
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
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          'Download',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _applyButton({required bool formValid}) {
    final canApply =
        manager != null && manager!.bleProcess.isExtOutApplyButtonActive.value;

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
            (canApply && formValid && manager != null)
                ? () async {
                  if (await commitLocal()) {
                    widget.onApply();
                  }
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
