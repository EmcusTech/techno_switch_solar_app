import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ServiceDueBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ServiceDueBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<ServiceDueBottomSheet> createState() => ServiceDueBottomSheetState();
}

class ServiceDueBottomSheetState extends State<ServiceDueBottomSheet> {
  BleManager? manager;

  final ServiceDueConfig config = ServiceDueConfig();

  final FocusNode yearFocusNode = FocusNode();
  final FocusNode monthFocusNode = FocusNode();
  final FocusNode dayFocusNode = FocusNode();
  final FocusNode hourFocusNode = FocusNode();
  final FocusNode minuteFocusNode = FocusNode();

  final List<String> reminderOptions = [StringConstants.off, StringConstants.on];

  @override
  void initState() {
    super.initState();

    yearFocusNode.addListener(() {
      if (yearFocusNode.hasFocus) {
        debugPrint(StringConstants.yearFieldIsFocused);
      } else {
        debugPrint(StringConstants.yearFieldLostFocus);
      }
    });
    monthFocusNode.addListener(() {
      if (monthFocusNode.hasFocus) {
        debugPrint(StringConstants.monthFieldIsFocused);
      } else {
        debugPrint(StringConstants.monthFieldLostFocus);
      }
    });
    dayFocusNode.addListener(() {
      hourFocusNode.addListener(() {
        if (hourFocusNode.hasFocus) {
          debugPrint(StringConstants.hourFieldIsFocused);
        } else {
          debugPrint(StringConstants.hourFieldLostFocus);
        }
      });
      minuteFocusNode.addListener(() {
        if (minuteFocusNode.hasFocus) {
          debugPrint(StringConstants.minuteFieldIsFocused);
        } else {
          debugPrint(StringConstants.minuteFieldLostFocus);
        }
      });
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
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    final cached = await PeripheralSetupCache.loadServiceDueSetup(
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
    config.yearController.text = (data['year'] as num?)?.toString() ?? '0';
    config.monthController.text = (data['month'] as num?)?.toString() ?? '0';
    config.dayController.text = (data['day'] as num?)?.toString() ?? '0';
    config.hourController.text = (data['hour'] as num?)?.toString() ?? '0';
    config.minuteController.text = (data['minute'] as num?)?.toString() ?? '0';
    config.companyController.text = (data['company'] as String?) ?? '';
    config.contactController.text = (data['contact'] as String?) ?? '';
    config.reminder = (data['reminder'] as int?) == 1 ? StringConstants.on : StringConstants.off;
  }

  void _loadFromManager() {
    if (manager == null) return;
    config.yearController.text = manager!.serviceDueYear.value.toString();
    config.monthController.text = manager!.serviceDueMonth.value.toString();
    config.dayController.text = manager!.serviceDueDay.value.toString();
    config.hourController.text = manager!.serviceDueHour.value.toString();
    config.minuteController.text = manager!.serviceDueMinute.value.toString();
    config.companyController.text = manager!.serviceDueCompany.value;
    config.contactController.text = manager!.serviceDueContact.value;
    config.reminder = manager!.serviceDueReminder.value == 0 ? StringConstants.off : StringConstants.on;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: widget.embedInCreateFlow ? 0 : 0,
        top: widget.embedInCreateFlow ? 0 : 16,
        bottom: 16,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: _formColumn(),
    );

    if (widget.embedInCreateFlow) {
      return scroll;
    }

    final maxHeight = MediaQuery.of(context).size.height * 0.80;

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
                        _title(StringConstants.serviceDueMode),
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

  // ───────────────── UI HELPERS ─────────────────

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

  // ───────────────── TEXT FIELD ─────────────────

  Widget? _relayStyleCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (!isFocused) return null;
    final max = maxLength ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$currentLength / $max',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: currentLength == max ? ColorConstants.primary : Colors.grey,
        ),
      ),
    );
  }

  Widget _contactField({
    required String label,
    required TextEditingController controller,
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
            keyboardType: TextInputType.phone,
            maxLength: 13,
            buildCounter: _relayStyleCounter,
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
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
            maxLength: 13,
            buildCounter: _relayStyleCounter,
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  void _pushServiceDueToManager() {
    final m = manager!;
    m.serviceDueYear.value = int.parse(config.yearController.text);
    m.serviceDueMonth.value = int.parse(config.monthController.text);
    m.serviceDueDay.value = int.parse(config.dayController.text);
    m.serviceDueHour.value = int.parse(config.hourController.text);
    m.serviceDueMinute.value = int.parse(config.minuteController.text);
    m.serviceDueCompany.value = config.companyController.text;
    m.serviceDueContact.value = config.contactController.text;
    m.serviceDueReminder.value = config.reminder == StringConstants.on ? 1 : 0;
  }

  Future<bool> commitLocal() async {
    if (!_isValidDateTime() || manager == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _pushServiceDueToManager();
    await PanelConfigCacheSync.saveServiceDue(
      manager!,
      widget.deviceId,
      widget.refreshTrigger,
    );
    return true;
  }

  Widget _formColumn() {
    return Column(
      children: [
        if (widget.embedInCreateFlow)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                StringConstants.serviceDueConfiguration,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textDark,
                ),
              ),
            ),
          ),
        _numberField(
          label: 'Year',
          controller: config.yearController,
          min: 0,
          max: 9999,
          errorMessage: StringConstants.yearMustBeBetween2010And9999,
          focusNode: yearFocusNode,
        ),
        _numberField(
          label: 'Month',
          controller: config.monthController,
          min: 1,
          max: 12,
          errorMessage: StringConstants.monthMustBeBetween1And12,
          focusNode: monthFocusNode,
        ),
        _numberField(
          label: 'Day',
          controller: config.dayController,
          min: 1,
          max: 31,
          errorMessage: StringConstants.dayMustBeBetween1And31,
          focusNode: dayFocusNode,
        ),
        _numberField(
          label: 'Hour',
          controller: config.hourController,
          min: 0,
          max: 23,
          errorMessage: StringConstants.hourMustBeBetween0And23,
          focusNode: hourFocusNode,
        ),
        _numberField(
          label: 'Minute',
          controller: config.minuteController,
          min: 0,
          max: 59,
          errorMessage: StringConstants.minuteMustBeBetween0And59,
          focusNode: minuteFocusNode,
        ),
        _textField(label: 'Company', controller: config.companyController),
        _contactField(label: StringConstants.contact, controller: config.contactController),
        DropdownWidget(
          label: StringConstants.reminder,
          value: config.reminder,
          items: reminderOptions,
          onChanged: (v) {
            setState(() {
              config.reminder = v;
            });
          },
        ),
      ],
    );
  }

  bool _isValidDateTime() {
    if (config.yearController.text.isEmpty ||
        config.monthController.text.isEmpty ||
        config.dayController.text.isEmpty ||
        config.hourController.text.isEmpty ||
        config.minuteController.text.isEmpty) {
      return false;
    }

    final year = int.parse(config.yearController.text);
    final month = int.parse(config.monthController.text);
    final day = int.parse(config.dayController.text);
    final hour = int.parse(config.hourController.text);
    final minute = int.parse(config.minuteController.text);

    if (year < 2010 || year > 9999) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;

    try {
      final dt = DateTime(year, month, day, hour, minute);

      if (dt.year != year || dt.month != month || dt.day != day) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // bool _isValidCompany() {
  //   final company = config.companyController.text.trim();
  //   if (company.length > 13) return false;

  //   return true;
  // }

  // bool _isValidContact() {
  //   final contact = config.contactController.text.trim();

  //   if (contact.isEmpty) return false;

  //   // length check
  //   if (contact.length > 13) return false;

  //   // digits only (extra safety, even though formatter exists)
  //   if (!RegExp(r'^\d+$').hasMatch(contact)) return false;

  //   // // optional: Indian mobile logic
  //   // if (!RegExp(rStringConstants.s69).hasMatch(contact)) return false;

  //   return true;
  // }

  // ───────────────── NUMBER FIELD ─────────────────

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    String? errorMessage,
    FocusNode? focusNode,
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
              LengthLimitingTextInputFormatter(4), // safe upper cap
              RangeInputFormatter(min: min, max: max),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 4),
          if (errorMessage != null && focusNode?.hasFocus == true)
            Text(
              errorMessage,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
            ),
        ],
      ),
    );
  }

  // ───────────────── INPUT STYLE ─────────────────

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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
      ),
    );
  }

  // ───────────────── BUTTONS ─────────────────

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
            (!_isValidDateTime())
                ? null
                : () async {
                  if (await commitLocal()) {
                    widget.onApply();
                  }
                },
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

// ───────────────── MODEL ─────────────────

class ServiceDueConfig {
  String reminder = StringConstants.off;

  final TextEditingController yearController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
}

// ───────────────── VALIDATION ─────────────────

class RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  RangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text.length < oldValue.text.length) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value >= min && value <= max) return newValue;

    final maxDigits = max.toString().length;
    if (newValue.text.length < maxDigits && value <= max) return newValue;

    return oldValue;
  }
}
