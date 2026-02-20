import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

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

  int _expandedTileCount = 0;

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
    _loadFromManager();
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
    final maxHeight =
        _expandedTileCount > 0 ? screenHeight * 0.75 : screenHeight * 0.45;

    _updateValidationErrors();
    final isValid = _computeIsValid();

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
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
                      child: _radioTile(),
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

  // ───────────────── TILE ─────────────────

  Widget _radioTile() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedTileCount += expanded ? 1 : -1;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Radio Setup',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  _dropdown(
                    'Enabled',
                    radio.enabled,
                    yesNoOptions,
                    (v) => setState(() => radio.enabled = v),
                  ),

                  _dropdown(
                    'Module',
                    radio.module,
                    moduleOptions,
                    (v) => setState(() => radio.module = v),
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

                  _dropdown(
                    'Advertise',
                    radio.advertise,
                    yesNoOptions,
                    (v) => setState(() => radio.advertise = v),
                  ),

                  _dropdown(
                    'Connection',
                    radio.connection,
                    yesNoOptions,
                    (v) => setState(() => radio.connection = v),
                  ),

                  _dropdown(
                    'Service',
                    radio.service,
                    yesNoOptions,
                    (v) => setState(() => radio.service = v),
                  ),

                  _dropdown(
                    'Programming',
                    radio.programming,
                    yesNoOptions,
                    (v) => setState(() => radio.programming = v),
                  ),

                  _dropdown(
                    'Boot',
                    radio.boot,
                    yesNoOptions,
                    (v) => setState(() => radio.boot = v),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  // manager!.radioEnabled.value =
                  //     radio.enabled == 'Yes';
                  // manager!.radioModule.value =
                  //     moduleOptions.indexOf(
                  //         radio.module);
                  // manager!.radioName.value =
                  //     radio.nameController.text;
                  // manager!.radioNumber.value =
                  //     radio.numberController.text;
                  // manager!.radioAdvertise.value =
                  //     radio.advertise == 'Yes';
                  // manager!.radioConnection.value =
                  //     radio.connection == 'Yes';
                  // manager!.radioService.value =
                  //     radio.service == 'Yes';
                  // manager!.radioProgramming.value =
                  //     radio.programming == 'Yes';
                  // manager!.radioBoot.value =
                  //     radio.boot == 'Yes';

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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) => onChanged(v!),
              decoration: _inputDecoration(),
            ),
          ),
        ],
      ),
    );
  }

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
