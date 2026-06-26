import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class GeneralModuleBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  /// Full-screen create-site step: no sheet chrome; use [GeneralModuleBottomSheetState.commitLocal] on Next.
  final bool embedInCreateFlow;

  const GeneralModuleBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<GeneralModuleBottomSheet> createState() =>
      GeneralModuleBottomSheetState();
}

class GeneralModuleBottomSheetState extends State<GeneralModuleBottomSheet> {
  BleManager? manager;

  final TextEditingController lvlTimeoutController = TextEditingController();

  final FocusNode lvlTimeoutFocusNode = FocusNode();

  String silenceBuzzerLevel = StringConstants.accessLevel1;
  String silenceSoundersLevel = StringConstants.accessLevel2;
  String resetLevel = StringConstants.accessLevel2;
  String faultLatching = StringConstants.no;

  final List<String> buzzerOptions = [StringConstants.accessLevel1, StringConstants.accessLevel2];

  final List<String> sounderOptions = [StringConstants.accessLevel2, StringConstants.accessLevel3];

  final List<String> resetOptions = [StringConstants.accessLevel2, StringConstants.accessLevel3];

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  @override
  void initState() {
    super.initState();

    lvlTimeoutFocusNode.addListener(() {
      if (lvlTimeoutFocusNode.hasFocus) {
        debugPrint(StringConstants.lvlTimeOutFieldIsFocused);
      } else {
        debugPrint(StringConstants.lvlTimeOutFieldLostFocus);
      }
    });

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }

    _loadData();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    lvlTimeoutController.dispose();
    lvlTimeoutFocusNode.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    final cached = await PeripheralSetupCache.loadGeneralModuleSetup(
      widget.deviceId,
    );
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    lvlTimeoutController.text = (data['lvlTimeout'] as num?)?.toString() ?? '0';
    silenceBuzzerLevel =
        (data[StringConstants.silencebuzzerlevel] as String?) ?? buzzerOptions.first;
    silenceSoundersLevel =
        (data['silenceSoundersLevel'] as String?) ?? sounderOptions.first;
    resetLevel = (data['resetLevel'] as String?) ?? resetOptions.first;
    faultLatching = (data[StringConstants.silencesounderslevel] as String?) ?? yesNoOptions.first;
  }

  void _loadFromManager() {
    if (manager == null) return;
    final bp = manager!.bleProcess;
    lvlTimeoutController.text = bp.generalModuleLvlTimeOut.value.toString();
    silenceBuzzerLevel =
        bp.generalModuleSilenceBuzzerLvl.value < buzzerOptions.length
            ? buzzerOptions[bp.generalModuleSilenceBuzzerLvl.value]
            : buzzerOptions.first;
    silenceSoundersLevel =
        bp.generalModuleSilenceSounderLvl.value < sounderOptions.length
            ? sounderOptions[bp.generalModuleSilenceSounderLvl.value]
            : sounderOptions.first;
    resetLevel =
        bp.generalModuleResetLvl.value < resetOptions.length
            ? resetOptions[bp.generalModuleResetLvl.value]
            : resetOptions.first;
    faultLatching =
        bp.generalModuleFaultLatching.value < yesNoOptions.length
            ? yesNoOptions[bp.generalModuleFaultLatching.value]
            : yesNoOptions.first;
    if (mounted) setState(() {});
  }

  bool _isValidGeneralModule() {
    final lvlTimeout = int.tryParse(lvlTimeoutController.text);
    if (lvlTimeout == null || lvlTimeout < 30 || lvlTimeout > 300) {
      return false;
    }
    return true;
  }

  void _pushToManager() {
    if (manager == null) return;
    final bp = manager!.bleProcess;
    bp.generalModuleLvlTimeOut.value =
        int.tryParse(lvlTimeoutController.text) ?? 0;
    bp.generalModuleSilenceBuzzerLvl.value = buzzerOptions
        .indexOf(silenceBuzzerLevel)
        .clamp(0, buzzerOptions.length - 1);
    bp.generalModuleSilenceSounderLvl.value = sounderOptions
        .indexOf(silenceSoundersLevel)
        .clamp(0, sounderOptions.length - 1);
    bp.generalModuleResetLvl.value = resetOptions
        .indexOf(resetLevel)
        .clamp(0, resetOptions.length - 1);
    bp.generalModuleFaultLatching.value = yesNoOptions
        .indexOf(faultLatching)
        .clamp(0, yesNoOptions.length - 1);
  }

  Future<void> _saveToCache() async {
    await PeripheralSetupCache.saveGeneralModuleSetup(widget.deviceId, {
      'lvlTimeout': int.tryParse(lvlTimeoutController.text) ?? 0,
      StringConstants.silencebuzzerlevel: silenceBuzzerLevel,
      'silenceSoundersLevel': silenceSoundersLevel,
      'resetLevel': resetLevel,
      StringConstants.silencesounderslevel: faultLatching,
    });
  }

  /// Create-site Next: push BLE + cache, no password / single-section apply.
  Future<bool> commitLocal() async {
    if (!_isValidGeneralModule() || manager == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _pushToManager();
    await _saveToCache();
    widget.refreshTrigger.value++;
    return true;
  }

  Widget _fieldsColumn() {
    return Column(
      children: [
        if (widget.embedInCreateFlow) _title(StringConstants.generalModule),
        _numberField(
          StringConstants.lvlTimeOutS,
          lvlTimeoutController,
          maxLength: 3,
          focusNode: lvlTimeoutFocusNode,
        ),
        DropdownWidget(
          label: StringConstants.silenceBuzzerLevel2,
          value: silenceBuzzerLevel,
          items: buzzerOptions,
          onChanged: (v) => setState(() => silenceBuzzerLevel = v),
        ),
        DropdownWidget(
          label: StringConstants.silenceSoundersLevel2,
          value: silenceSoundersLevel,
          items: sounderOptions,
          onChanged: (v) => setState(() => silenceSoundersLevel = v),
        ),
        DropdownWidget(
          label: StringConstants.resetLevel2,
          value: resetLevel,
          items: resetOptions,
          onChanged: (v) => setState(() => resetLevel = v),
        ),
        DropdownWidget(
          label: StringConstants.faultLatching,
          value: faultLatching,
          items: yesNoOptions,
          onChanged: (v) => setState(() => faultLatching = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scroll = NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: widget.embedInCreateFlow ? 0 : 16,
          bottom: 16,
        ),
        child: _fieldsColumn(),
      ),
    );

    if (widget.embedInCreateFlow) {
      return scroll;
    }

    final maxHeight = MediaQuery.of(context).size.height * 0.75;

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
              // padding: EdgeInsets.only(
              //   left: 24,
              //   right: 24,
              //   top: 16,
              //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              // ),
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
                        _title(StringConstants.generalMode),
                        Expanded(child: scroll),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _downloadButton()),
                            const SizedBox(width: 12),
                            Expanded(child: _applyButton()),
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

  // ───────── INPUTS ─────────

  Widget _numberField(
    String label,
    TextEditingController controller, {
    int? maxLength,
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),

          if (focusNode.hasFocus)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  StringConstants.lvlTimeOutMustBeBetween30And300Seconds,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
                ),
              ),
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
        color: ColorConstants.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.borderLight),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }

  // ───────── COMMON UI ─────────

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
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
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

  Widget _applyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            _isValidGeneralModule()
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
