import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
  List<String> enabledOptions = [StringConstants.no, StringConstants.yes];
  List<String> actuatorTypeOptions = [
    'Not Defined',
    StringConstants.metron,
    StringConstants.solenoid,
    StringConstants.aerosol,
  ];
  List<String> functionOptions = [
    'Z1 and Z2',
    StringConstants.z2AndZ3,
    StringConstants.z1AndZ3,
    StringConstants.z1AndZ2AndZ3,
    StringConstants.z12,
    StringConstants.z22,
    StringConstants.z32,
    StringConstants.any2Zones,
    StringConstants.any1Zone,
  ];
  List<String> resetInCountOptions = [StringConstants.yes, StringConstants.no];
  List<String> holdCountOptions = [
    'Disabled',
    StringConstants.restart,
    StringConstants.suspend,
    StringConstants.disabled,
  ];
  List<String> actionOptions = [
    'Continous',
    StringConstants.pulse100msOn,
    StringConstants.pulse300msOn,
    StringConstants.pulse600msOn,
    StringConstants.pulse1sOn,
    StringConstants.pulse5sOn,
    StringConstants.pulsing100msOn500msOff,
    StringConstants.pulsing300msOn15sOff,
    StringConstants.pulsing600msOn3sOff,
    StringConstants.pulsing1sOn5sOff,
  ];

  late String enabled;
  late String actuatorType;
  late String function;
  late String resetInCount;
  late String holdCount;
  late String action;
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
  final String _manError = StringConstants.countdownManMustBeBetween0And60;
  final String _releaseError = StringConstants.releaseTimeMustBeBetween10And300;
  final String _resetDelayError = StringConstants.resetDelayMustBeBetween0And1800;

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
        debugPrint(StringConstants.autoFieldIsFocused);
      } else {
        debugPrint(StringConstants.autoFieldLostFocus);
      }
    });
    manFocusNode.addListener(() {
      if (manFocusNode.hasFocus) {
        debugPrint(StringConstants.manFieldIsFocused);
      } else {
        debugPrint(StringConstants.manFieldLostFocus);
      }
    });
    releaseFocusNode.addListener(() {
      if (releaseFocusNode.hasFocus) {
        debugPrint(StringConstants.releaseFieldIsFocused);
      } else {
        debugPrint(StringConstants.releaseFieldLostFocus);
      }
    });
    resetDelayFocusNode.addListener(() {
      if (resetDelayFocusNode.hasFocus) {
        debugPrint(StringConstants.resetDelayFieldIsFocused);
      } else {
        debugPrint(StringConstants.resetDelayFieldLostFocus);
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
    if (manager?.isConnected == true) {
      _loadFromManager();
      return;
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
    final at = (data[StringConstants.actuatortype] as int?) ?? 0;
    actuatorType =
        actuatorTypeOptions[at.clamp(0, actuatorTypeOptions.length - 1)];
    final fn = (data['function'] as int?) ?? 0;
    function = functionOptions[fn.clamp(0, functionOptions.length - 1)];
    final ra = (data[StringConstants.resetallowed] as int?) ?? 0;
    resetInCount =
        resetInCountOptions[ra.clamp(0, resetInCountOptions.length - 1)];
    final hc = (data[StringConstants.holdmode] as int?) ?? 0;
    holdCount = holdCountOptions[hc.clamp(0, holdCountOptions.length - 1)];
    final ac = (data['action'] as int?) ?? 0;
    action = actionOptions[ac.clamp(0, actionOptions.length - 1)];
    autoCtrl.text = (data['countdownAuto'] as int?)?.toString() ?? '10';
    manCtrl.text = (data['countdownMan'] as int?)?.toString() ?? '15';
    releaseCtrl.text = (data['releaseTime'] as int?)?.toString() ?? '10';
    resetDelayCtrl.text = (data[StringConstants.resetdelay] as int?)?.toString() ?? '5';
    final solarRaw = data[StringConstants.issolar];
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
            isSolar ? ColorConstants.successBackgroundLight : ColorConstants.errorBackgroundLight;

        final textColor =
            isSolar ? ColorConstants.successDark : ColorConstants.colorFfc62828;

        final icon =
            isSolar
                ? Icons.wb_sunny_rounded
                : Icons.settings_input_component_rounded;

        final label = isSolar ? StringConstants.solarMode : StringConstants.dipMode;

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
        _title(StringConstants.extOutConfig),
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
          label: StringConstants.enabled,
          value: enabled,
          items: enabledOptions,
          onChanged: (v) => setState(() => enabled = v),
        ),
        DropdownWidget(
          label: StringConstants.actuatorType,
          value: actuatorType,
          items: actuatorTypeOptions,
          onChanged: (v) => setState(() => actuatorType = v),
        ),
        DropdownWidget(
          label: StringConstants.function,
          value: function,
          items: functionOptions,
          onChanged: (v) => setState(() => function = v),
        ),
        _numberFieldWithValidation(
          label: StringConstants.countdownAutoS,
          controller: autoCtrl,
          errorMsg: _autoError,
          focusNode: autoFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.countdownManS,
          controller: manCtrl,
          errorMsg: _manError,
          focusNode: manFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.releaseTimeS,
          controller: releaseCtrl,
          errorMsg: _releaseError,
          focusNode: releaseFocusNode,
        ),
        _numberFieldWithValidation(
          label: StringConstants.resetDelayS,
          controller: resetDelayCtrl,
          errorMsg: _resetDelayError,
          focusNode: resetDelayFocusNode,
        ),
        DropdownWidget(
          label: StringConstants.resetInCount,
          value: resetInCount,
          items: resetInCountOptions,
          onChanged: (v) => setState(() => resetInCount = v),
        ),
        DropdownWidget(
          label: StringConstants.holdCount,
          value: holdCount,
          items: holdCountOptions,
          onChanged: (v) => setState(() => holdCount = v),
        ),
        DropdownWidget(
          label: StringConstants.action,
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
          children: [if (widget.embedInCreateFlow) _headerRow(), _formFields()],
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
            color: ColorConstants.primaryVariant,
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset('assets/svgs/bottomsheet_logo.svg'),
                      Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorConstants.blackMaterial.withValues(alpha: 0.06),
                            ),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        _dragHandle(),
                        _title(StringConstants.extOutMode),
                        const SizedBox(height: 4),
                        _modeBadge(),
                        const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
          color: ColorConstants.textDark,
        ),
      ),
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
        color: ColorConstants.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;
    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.all(14),
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
        borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: const BorderSide(color: ColorConstants.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          StringConstants.download,
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
          backgroundColor: ColorConstants.primary,
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
          StringConstants.apply,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }
}
