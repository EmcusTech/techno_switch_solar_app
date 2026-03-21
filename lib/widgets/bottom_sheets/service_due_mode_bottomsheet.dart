import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class ServiceDueBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const ServiceDueBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<ServiceDueBottomSheet> createState() => _ServiceDueBottomSheetState();
}

class _ServiceDueBottomSheetState extends State<ServiceDueBottomSheet> {
  BleManager? manager;

  final ServiceDueConfig config = ServiceDueConfig();

  final List<String> reminderOptions = ['Off', 'On'];

  @override
  void initState() {
    super.initState();

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
    config.reminder = (data['reminder'] as int?) == 1 ? 'On' : 'Off';
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
    config.reminder = manager!.serviceDueReminder.value == 0 ? 'Off' : 'On';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.70;

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
              _title("Service Due Configuration"),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _numberField(
                        label: "Year",
                        controller: config.yearController,
                        min: 0,
                        max: 9999,
                      ),

                      _numberField(
                        label: "Month",
                        controller: config.monthController,
                        min: 1,
                        max: 12,
                      ),

                      _numberField(
                        label: "Day",
                        controller: config.dayController,
                        min: 1,
                        max: 31,
                      ),

                      _numberField(
                        label: "Hour",
                        controller: config.hourController,
                        min: 0,
                        max: 23,
                      ),

                      _numberField(
                        label: "Minute",
                        controller: config.minuteController,
                        min: 0,
                        max: 59,
                      ),

                      _textField(
                        label: "Company",
                        controller: config.companyController,
                      ),

                      _contactField(
                        label: "Contact",
                        controller: config.contactController,
                      ),

                      DropdownWidget(
                        label: 'Reminder',
                        value: config.reminder,
                        items: reminderOptions,
                        onChanged: (v) {
                          setState(() {
                            config.reminder = v;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

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

  // ───────────────── TEXT FIELD ─────────────────

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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
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
  //   // if (!RegExp(r'^[6-9]').hasMatch(contact)) return false;

  //   return true;
  // }

  // ───────────────── NUMBER FIELD ─────────────────

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4), // safe upper cap
              RangeInputFormatter(min: min, max: max),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  // ───────────────── INPUT STYLE ─────────────────

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  // ───────────────── BUTTONS ─────────────────

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

  Widget _applyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            (!_isValidDateTime())
                ? null
                : () {
                  if (manager == null) return;
                  FocusManager.instance.primaryFocus?.unfocus();

                  manager!.serviceDueYear.value = int.parse(
                    config.yearController.text,
                  );
                  manager!.serviceDueMonth.value = int.parse(
                    config.monthController.text,
                  );
                  manager!.serviceDueDay.value = int.parse(
                    config.dayController.text,
                  );
                  manager!.serviceDueHour.value = int.parse(
                    config.hourController.text,
                  );
                  manager!.serviceDueMinute.value = int.parse(
                    config.minuteController.text,
                  );
                  manager!.serviceDueCompany.value =
                      config.companyController.text;
                  manager!.serviceDueContact.value =
                      config.contactController.text;
                  manager!.serviceDueReminder.value =
                      config.reminder == 'On' ? 1 : 0;

                  widget.onApply();
                },
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

// ───────────────── MODEL ─────────────────

class ServiceDueConfig {
  String reminder = 'Off';

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
