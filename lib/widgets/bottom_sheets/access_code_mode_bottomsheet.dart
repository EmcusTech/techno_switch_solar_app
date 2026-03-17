import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class AccessCodesBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const AccessCodesBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<AccessCodesBottomSheet> createState() => _AccessCodesBottomSheetState();
}

class _AccessCodesBottomSheetState extends State<AccessCodesBottomSheet> {
  BleManager? manager;
  int selectedCode = 1;

  final List<String> accessLevelNames = [
    'Not Used',
    'Untrained User',
    'Authorised User',
    'Commissioning',
  ];

  final TextEditingController accessLevelController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();

  String accessLevelName = 'Not Used';

  void _onListChanged() {
    _loadFromManager();
  }

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    manager?.accessCodeSetupDataList.removeListener(_onListChanged);
    accessLevelController.dispose();
    accessCodeController.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
      manager?.accessCodeSetupDataList.addListener(_onListChanged);
    }
    final cached = await PeripheralSetupCache.loadAccessCodeSetup(
      widget.deviceId,
    );
    if (cached != null && cached.isNotEmpty) {
      final list = cached.map((e) => AccessCodeSetupData.fromJson(e)).toList();
      while (list.length < 8) {
        list.add(const AccessCodeSetupData());
      }
      manager?.accessCodeSetupDataList.value = list;
    }
    _loadFromManager();
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    final index = selectedCode - 1;
    if (index < 0 || index >= manager!.accessCodeSetupDataList.value.length) {
      return;
    }

    final data = manager!.accessCodeSetupDataList.value[index];

    if (mounted) {
      setState(() {
        accessLevelController.text = data.accessLevel.toString();
        accessLevelName =
            accessLevelNames.contains(data.accessLevelName)
                ? data.accessLevelName
                : (data.accessLevel >= 0 &&
                    data.accessLevel < accessLevelNames.length)
                ? accessLevelNames[data.accessLevel]
                : accessLevelNames.first;
        accessCodeController.text = data.accessCode;
      });
    }
  }

  void _saveCurrentToManager() {
    if (manager == null) return;
    final index = selectedCode - 1;
    if (index < 0 || index >= manager!.accessCodeSetupDataList.value.length)
      return;

    final existing = manager!.accessCodeSetupDataList.value[index];
    final levelIndex = accessLevelNames.indexOf(accessLevelName);
    final level = levelIndex >= 0 ? levelIndex : existing.accessLevel;

    final updated = existing.copyWith(
      accessLevel: level,
      accessLevelName: accessLevelName,
      accessCode: accessCodeController.text,
    );

    final list = List<AccessCodeSetupData>.from(
      manager!.accessCodeSetupDataList.value,
    );
    list[index] = updated;
    manager!.accessCodeSetupDataList.value = list;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.80),
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

              _title('Access Codes Configuration'),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _selector(),

                      const SizedBox(height: 16),

                      _sectionContainer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              _disabledField(
                                'Access Code No',
                                selectedCode.toString(),
                              ),

                              _textField(
                                label: 'Access Level',
                                controller: accessLevelController,
                                enabled: false,
                              ),

                              DropdownWidget(
                                label: 'Access Level Name',
                                value: accessLevelName,
                                items: accessLevelNames,
                                onChanged: (v) {
                                  setState(() {
                                    accessLevelName = v;

                                    int index = accessLevelNames.indexOf(v);

                                    accessLevelController.text =
                                        index.toString();
                                  });
                                },
                              ),

                              _textField(
                                label: 'Access Code',
                                controller: accessCodeController,
                              ),
                            ],
                          ),
                        ),
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

  Widget _selector() {
    return DropdownWidget(
      label: 'Select Access Code',
      value: 'Access Code $selectedCode',
      items: List.generate(8, (i) => 'Access Code ${i + 1}'),
      onChanged: (v) {
        final number = int.parse(v.split(' ').last);

        setState(() {
          _saveCurrentToManager();
          selectedCode = number;
          _loadFromManager();
        });
      },
    );
  }

  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: child,
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
          color: const Color(0xFF3D3D3D),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
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
            enabled: enabled,
            decoration: _inputDecoration(),
          ),
        ],
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
          TextField(
            enabled: false,
            controller: TextEditingController(text: value),
            decoration: _inputDecoration(),
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
        color: const Color(0xFF3D3D3D),
      ),
    );
  }

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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFEC1D24), width: 2),
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
          _saveCurrentToManager();
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
