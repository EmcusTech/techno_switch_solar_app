import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/app_styled_dialogs.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
  bool isAccessCodeEnabled = true;

  final List<String> accessLevelNames = [
    StringConstants.notUsed,
    StringConstants.untrainedUser,
    StringConstants.authorisedUser,
    StringConstants.commissioning,
  ];

  final TextEditingController accessLevelController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();

  String accessLevelName = StringConstants.notUsed;

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

  bool _isValidAccessCode() {
    if (accessLevelName == accessLevelNames.first) {
      return true;
    }
    final code = int.tryParse(accessCodeController.text);
    if (code == null || code < 1 || code > 99999999) return false;
    return true;
  }

  int? _findDuplicateAccessCodeSlot() {
    if (manager == null) return null;
    if (accessLevelName == accessLevelNames.first) return null;

    final enteredCode = int.tryParse(accessCodeController.text.trim());
    if (enteredCode == null) return null;

    final currentIndex = selectedCode - 1;
    final list = manager!.accessCodeSetupDataList.value;

    for (var i = 0; i < list.length; i++) {
      if (i == currentIndex) continue;

      final other = list[i];
      if (other.accessLevelName == accessLevelNames.first) continue;

      final otherCode = int.tryParse(other.accessCode.trim());
      if (otherCode == null) continue;

      if (otherCode == enteredCode) {
        return i + 1;
      }
    }

    return null;
  }

  void _showDuplicateAccessCodeDialog(int existingSlot) {
    showAppStyledOneActionDialog(
      context: context,
      title: StringConstants.duplicateAccessCode,
      message:
          'This access code is already present in Access Code $existingSlot.',
      icon: Icons.warning_amber_rounded,
    );
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

                        _title(StringConstants.accessMode),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
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
                                          StringConstants.accessCodeNo2,
                                          selectedCode.toString(),
                                        ),

                                        _textField(
                                          label: StringConstants.accessLevel4,
                                          controller: accessLevelController,
                                          enabled: false,
                                        ),

                                        DropdownWidget(
                                          label: StringConstants.accessLevelName2,
                                          value: accessLevelName,
                                          items: accessLevelNames,
                                          onChanged: (v) {
                                            setState(() {
                                              accessLevelName = v;

                                              int index = accessLevelNames
                                                  .indexOf(v);

                                              accessLevelController.text =
                                                  index.toString();

                                              if (v == accessLevelNames.first) {
                                                isAccessCodeEnabled = false;
                                                accessCodeController.clear();
                                              } else {
                                                isAccessCodeEnabled = true;
                                              }
                                            });
                                          },
                                        ),

                                        _textField(
                                          label: 'Access Code',
                                          controller: accessCodeController,
                                          isNumeric: true,
                                          maxLength: 8,
                                          onChanged: () => setState(() {}),
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
                ],
              ),
            ),
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
      dropdownListHeight: 340,
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
        border: Border.all(color: ColorConstants.borderMuted),
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
          color: ColorConstants.textDark,
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool isNumeric = false,
    int? maxLength,
    VoidCallback? onChanged,
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
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLength: maxLength,
            buildCounter:
                maxLength == null
                    ? null
                    : (
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
                            color:
                                currentLength == max
                                    ? ColorConstants.primary
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            inputFormatters: [
              if (isNumeric) FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: onChanged != null ? (_) => onChanged() : null,
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
            _isValidAccessCode()
                ? () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  final duplicateSlot = _findDuplicateAccessCodeSlot();
                  if (duplicateSlot != null) {
                    _showDuplicateAccessCodeDialog(duplicateSlot);
                    return;
                  }

                  _saveCurrentToManager();
                  widget.onApply();
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
