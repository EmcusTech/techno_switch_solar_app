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
                      ),

                      _numberField(
                        label: "Month",
                        controller: config.monthController,
                      ),

                      _numberField(
                        label: "Day",
                        controller: config.dayController,
                      ),

                      _numberField(
                        label: "Hour",
                        controller: config.hourController,
                      ),

                      _numberField(
                        label: "Minute",
                        controller: config.minuteController,
                      ),

                      _textField(
                        label: "Company",
                        controller: config.companyController,
                      ),

                      _textField(
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
          TextField(controller: controller, decoration: _inputDecoration()),
        ],
      ),
    );
  }

  // ───────────────── NUMBER FIELD ─────────────────

  Widget _numberField({
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
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        onPressed: () {
          if (manager == null) return;
          FocusManager.instance.primaryFocus?.unfocus();

          manager!.serviceDueYear.value = int.parse(config.yearController.text);
          manager!.serviceDueMonth.value = int.parse(
            config.monthController.text,
          );
          manager!.serviceDueDay.value = int.parse(config.dayController.text);
          manager!.serviceDueHour.value = int.parse(config.hourController.text);
          manager!.serviceDueMinute.value = int.parse(
            config.minuteController.text,
          );
          manager!.serviceDueCompany.value = config.companyController.text;
          manager!.serviceDueContact.value = config.contactController.text;
          manager!.serviceDueReminder.value = config.reminder == 'On' ? 1 : 0;

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
