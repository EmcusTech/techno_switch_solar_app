import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class RadioModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const RadioModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<RadioModeBottomSheet> createState() => _RadioModeBottomSheetState();
}

class _RadioModeBottomSheetState extends State<RadioModeBottomSheet> {
  BleManager? manager;

  final List<String> yesNoOptions = ['No', 'Yes'];
  final List<String> moduleOptions = ['None', 'BLUENRG-MB'];

  late RadioConfig radio;

  String? _nameError;
  String? _numberError;

  // ───────────────── VALIDATION ─────────────────

  bool _computeIsValid() {
    if (radio.nameController.text.length > 21) return false;

    if (radio.numberController.text.isEmpty) return false;

    final number = int.tryParse(radio.numberController.text);
    if (number == null) return false;

    return true;
  }

  void _updateValidationErrors() {
    _nameError = null;
    _numberError = null;

    if (radio.nameController.text.length > 21) {
      _nameError =
          'Name must be at most 21 characters (currently ${radio.nameController.text.length})';
    }

    if (radio.numberController.text.isEmpty) {
      _numberError = 'Number cannot be empty';
    } else {
      final number = int.tryParse(radio.numberController.text);
      if (number == null) {
        _numberError = 'Invalid number';
      }
    }
  }

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();
    radio = RadioConfig();
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
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await PeripheralSetupCache.loadRadioSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    radio.enabled = (data['enabled'] as bool?) == true ? 'Yes' : 'No';
    final module = (data['module'] as int?) ?? 0;
    radio.module = module == 0 ? 'None' : 'BLUENRG-MB';
    radio.nameController.text = (data['name'] as String?) ?? '';
    radio.numberController.text = (data['number'] as String?) ?? '';
    radio.advertise = (data['advertise'] as bool?) == true ? 'Yes' : 'No';
    radio.connection = (data['connection'] as bool?) == true ? 'Yes' : 'No';
    radio.service = (data['service'] as bool?) == true ? 'Yes' : 'No';
    radio.programming = (data['programming'] as bool?) == true ? 'Yes' : 'No';
    radio.boot = (data['boot'] as bool?) == true ? 'Yes' : 'No';
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;

    manager = Get.find<BleLogController>().bleManager;

    radio.enabled = manager!.isRadioSetupEnabled.value ? 'Yes' : 'No';
    radio.module = manager!.radioSetupModule.value == 0 ? 'None' : 'BLUENRG-MB';
    radio.nameController.text = manager!.radioSetupName.value;
    radio.numberController.text = manager!.radioSetupNo.value;
    radio.advertise = manager!.isRadioSetupAdvertised.value ? 'Yes' : 'No';
    radio.connection = manager!.isRadioSetupConnected.value ? 'Yes' : 'No';
    radio.service = manager!.isRadioSetupServiced.value ? 'Yes' : 'No';
    radio.programming = manager!.isRadioSetupProgrammed.value ? 'Yes' : 'No';
    radio.boot = manager!.isRadioSetupBooted.value ? 'Yes' : 'No';

    if (mounted) setState(() {});
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    _updateValidationErrors();
    final isValid = _computeIsValid();

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
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
                _title('Radio Configuration'),
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
                      child: _radioFields(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _downloadButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _applyButton(isValid)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── FIELDS ─────────────────

  Widget _radioFields() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          if (manager != null)
            ValueListenableBuilder<String>(
              valueListenable: manager!.bleFirmwareVersion,
              builder: (_, version, __) => _disabledField(
                'BLE Firmware Version',
                version.isEmpty ? '—' : version,
              ),
            )
          else
            _disabledField('BLE Firmware Version', '—'),
          _disabledField('Enabled', 'Yes'),

          DropdownWidget(
            label: 'Module',
            value: radio.module,
            items: moduleOptions,
            onChanged: (v) => setState(() => radio.module = v),
          ),

          _textField(
            label: 'Name',
            controller: radio.nameController,
            error: _nameError,
            maxLength: 21,
          ),

          _textField(
            label: 'Number',
            controller: radio.numberController,
            error: _numberError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          DropdownWidget(
            label: 'Advertise',
            value: radio.advertise,
            items: yesNoOptions,
            onChanged: (v) => setState(() => radio.advertise = v),
          ),

          DropdownWidget(
            label: 'Connection',
            value: radio.connection,
            items: yesNoOptions,
            onChanged: (v) => setState(() => radio.connection = v),
          ),

          DropdownWidget(
            label: 'Service',
            value: radio.service,
            items: yesNoOptions,
            onChanged: (v) => setState(() => radio.service = v),
          ),

          DropdownWidget(
            label: 'Programming',
            value: radio.programming,
            items: yesNoOptions,
            onChanged: (v) => setState(() => radio.programming = v),
          ),

          DropdownWidget(
            label: 'Boot',
            value: radio.boot,
            items: yesNoOptions,
            onChanged: (v) => setState(() => radio.boot = v),
          ),
        ],
      ),
    );
  }

  // ───────────────── APPLY ─────────────────

  Widget _applyButton(bool isValid) {
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
                  manager!.isRadioSetupEnabled.value = true; // Fixed to Yes
                  manager!.radioSetupModule.value = moduleOptions.indexOf(
                    radio.module,
                  );
                  manager!.radioSetupName.value = radio.nameController.text;
                  manager!.radioSetupNo.value = radio.numberController.text;
                  manager!.isRadioSetupAdvertised.value =
                      radio.advertise == 'Yes';
                  manager!.isRadioSetupConnected.value =
                      radio.connection == 'Yes';
                  manager!.isRadioSetupServiced.value = radio.service == 'Yes';
                  manager!.isRadioSetupProgrammed.value =
                      radio.programming == 'Yes';
                  manager!.isRadioSetupBooted.value = radio.boot == 'Yes';

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

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: widget.onDownload,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEC1D24),
          side: const BorderSide(color: Color(0xFFEC1D24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'Download',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ───────────────── SHARED UI ─────────────────

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? error,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: _inputDecoration(hasError: error != null),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFEC1D24),
                ),
              ),
            ),
        ],
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
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _disabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            alignment: Alignment.centerLeft,
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

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
}

// ───────────────── MODEL ─────────────────

class RadioConfig {
  String enabled = 'No';
  String module = 'None';
  String advertise = 'No';
  String connection = 'No';
  String service = 'No';
  String programming = 'No';
  String boot = 'No';

  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
}
