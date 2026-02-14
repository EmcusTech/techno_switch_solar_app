import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/zone_mode_util.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class ZoneBottomSheet extends StatefulWidget {
  final Function() onCall;

  const ZoneBottomSheet({super.key, required this.onCall});

  @override
  State<ZoneBottomSheet> createState() => _ZoneBottomSheetState();
}

class _ZoneBottomSheetState extends State<ZoneBottomSheet> {
  BleManager? manager;

  final List<String> typeOptions = ['Normal', 'IS (MTL 5561)'];
  final List<String> yesNoOptions = ['No', 'Yes'];
  final List<String> modeOptions = [
    'Immediate',
    'Normal',
    'Verified',
    'Confirmed',
  ];

  late List<ZoneConfig> zones;

  Map<int, String?> _zoneTextErrors = {};
  Map<int, String?> _verificationErrors = {};

  bool _computeIsValid() {
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      if (zone.zoneTextController.text.length > 21) return false;
      final mode = zone.mode;
      if (mode == 'Immediate' || mode == 'Normal') {
        if (zone.verificationTimeController.text != '0') return false;
      } else if (mode == 'Verified') {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) return false;
      } else if (mode == 'Confirmed') {
        if (zone.verificationTimeController.text != '30') return false;
      }
    }
    return true;
  }

  void _updateValidationErrors() {
    _zoneTextErrors.clear();
    _verificationErrors.clear();
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      if (zone.zoneTextController.text.length > 21) {
        _zoneTextErrors[i] =
            'Zone text must be at most 21 characters (currently ${zone.zoneTextController.text.length})';
      }
      final mode = zone.mode;
      if (mode == 'Immediate' || mode == 'Normal') {
        if (zone.verificationTimeController.text != '0') {
          _verificationErrors[i] = 'Must be 0 for Immediate/Normal mode';
        }
      } else if (mode == 'Verified') {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) {
          _verificationErrors[i] =
              'Must be between 10 and 60 for Verified mode';
        }
      } else if (mode == 'Confirmed') {
        if (zone.verificationTimeController.text != '30') {
          _verificationErrors[i] = 'Must be 30 for Confirmed mode';
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    zones = List.generate(3, (i) => ZoneConfig(zoneNumber: i + 1));

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;

      print("Zone 1 Type: ${manager!.zoneOneSetupType.value}");
      print("Zone 1 Enabled: ${manager!.isZoneOneSetupEnabled.value}");
      print("Zone 1 Test: ${manager!.isZoneOneSetupTest.value}");
      print(
        "Zone 1 Detection Mode: ${manager!.zoneOneSetupDetectionMode.value}",
      );
      print("Zone 1 Mode: ${manager!.zoneOneSetupMode.value}");
      print(
        "Zone 1 Verification Time: ${manager!.zoneOneSetupVerificationTime.value}",
      );
      print("Zone 1 Text: ${manager!.zoneOneSetupText.value}");
      print("Zone 2 Type: ${manager!.zoneTwoSetupType.value}");
      print("Zone 2 Enabled: ${manager!.isZoneTwoSetupEnabled.value}");
      print("Zone 2 Test: ${manager!.isZoneTwoSetupTest.value}");
      print(
        "Zone 2 Detection Mode: ${manager!.zoneTwoSetupDetectionMode.value}",
      );
      print("Zone 2 Mode: ${manager!.zoneTwoSetupMode.value}");
      print(
        "Zone 2 Verification Time: ${manager!.zoneTwoSetupVerificationTime.value}",
      );
      print("Zone 2 Text: ${manager!.zoneTwoSetupText.value}");
      print("Zone 3 Type: ${manager!.zoneThreeSetupType.value}");
      print("Zone 3 Enabled: ${manager!.isZoneThreeSetupEnabled.value}");
      print("Zone 3 Test: ${manager!.isZoneThreeSetupTest.value}");
      print(
        "Zone 3 Detection Mode: ${manager!.zoneThreeSetupDetectionMode.value}",
      );
      print("Zone 3 Mode: ${manager!.zoneThreeSetupMode.value}");
      print(
        "Zone 3 Verification Time: ${manager!.zoneThreeSetupVerificationTime.value}",
      );
      print("Zone 3 Text: ${manager!.zoneThreeSetupText.value}");

      // Zone 1
      zones[0].type =
          manager!.zoneOneSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
      zones[0].enabled = manager!.isZoneOneSetupEnabled.value ? 'Yes' : 'No';
      zones[0].test = manager!.isZoneOneSetupTest.value ? 'Yes' : 'No';
      final int dm1 = manager!.zoneOneSetupDetectionMode.value;
      zones[0].mode =
          (dm1 >= 0 && dm1 < modeOptions.length)
              ? modeOptions[dm1]
              : modeOptions.first;
      zones[0].verificationTimeController.text =
          manager!.zoneOneSetupVerificationTime.value;
      zones[0].zoneTextController.text = manager!.zoneOneSetupText.value;

      // Zone 2
      zones[1].type =
          manager!.zoneTwoSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
      zones[1].enabled = manager!.isZoneTwoSetupEnabled.value ? 'Yes' : 'No';
      zones[1].test = manager!.isZoneTwoSetupTest.value ? 'Yes' : 'No';
      final int dm2 = manager!.zoneTwoSetupDetectionMode.value;
      zones[1].mode =
          (dm2 >= 0 && dm2 < modeOptions.length)
              ? modeOptions[dm2]
              : modeOptions.first;
      zones[1].verificationTimeController.text =
          manager!.zoneTwoSetupVerificationTime.value;
      zones[1].zoneTextController.text = manager!.zoneTwoSetupText.value;

      // Zone 3
      zones[2].type =
          manager!.zoneThreeSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
      zones[2].enabled = manager!.isZoneThreeSetupEnabled.value ? 'Yes' : 'No';
      zones[2].test = manager!.isZoneThreeSetupTest.value ? 'Yes' : 'No';
      final int dm3 = manager!.zoneThreeSetupDetectionMode.value;
      zones[2].mode =
          (dm3 >= 0 && dm3 < modeOptions.length)
              ? modeOptions[dm3]
              : modeOptions.first;
      zones[2].verificationTimeController.text =
          manager!.zoneThreeSetupVerificationTime.value;
      zones[2].zoneTextController.text = manager!.zoneThreeSetupText.value;
    }

    for (int i = 0; i < 3; i++) {
      final z = zones[i];
      if (z.mode == 'Immediate' || z.mode == 'Normal') {
        z.verificationTimeController.text = '0';
      } else if (z.mode == 'Confirmed') {
        z.verificationTimeController.text = '30';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    _updateValidationErrors();
    final isValid = _computeIsValid();

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
              _title('Zone Configuration'),

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
                    child: Column(
                      children: List.generate(3, (i) => _zoneTile(i)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _primaryButton(isValid: isValid),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── ZONE TILE ─────────────────

  Widget _zoneTile(int index) {
    final zone = zones[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCDCDC)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,

            // backgroundColor: const Color(0xFFF8F8F8),
            // collapsedBackgroundColor: Colors.white,
            title: Text(
              'Zone ${zone.zoneNumber}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                // color: const Color(0xFFF8F8F8),
                child: Column(
                  children: [
                    _zoneTextField(zone: zone, zoneIndex: index),

                    DropdownWidget(
                      label: 'Type',
                      value: zone.type,
                      items: typeOptions,
                      onChanged: (v) => setState(() => zone.type = v),
                    ),

                    DropdownWidget(
                      label: 'Enabled',
                      value: zone.enabled,
                      items: yesNoOptions,
                      onChanged: (v) {
                        setState(() {
                          zone.enabled = v;
                          if (v == 'No') zone.test = 'No';
                        });
                      },
                    ),

                    DropdownWidget(
                      label: 'Test',
                      value: zone.test,
                      items: yesNoOptions,
                      onChanged: (v) {
                        setState(() {
                          zone.test = v;
                          if (v == 'Yes') zone.enabled = 'Yes';
                        });
                      },
                    ),

                    DropdownWidget(
                      label: 'Mode',
                      value: zone.mode,
                      items: modeOptions,
                      onChanged: (v) {
                        setState(() {
                          zone.mode = v;
                          if (v == 'Immediate' || v == 'Normal') {
                            zone.verificationTimeController.text = '0';
                          } else if (v == 'Confirmed') {
                            zone.verificationTimeController.text = '30';
                          }
                          _zoneTextErrors.remove(index);
                          _verificationErrors.remove(index);
                        });
                      },
                    ),

                    _verificationTimeField(zone: zone, zoneIndex: index),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── ZONE TEXT & VERIFICATION FIELDS ─────────────────

  Widget _zoneTextField({required ZoneConfig zone, required int zoneIndex}) {
    final errorMsg = _zoneTextErrors[zoneIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Zone Text'),
          const SizedBox(height: 6),
          TextField(
            controller: zone.zoneTextController,
            maxLength: 21,
            buildCounter: (
              context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              if (!isFocused) return null;

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "$currentLength / 21",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        currentLength == 21
                            ? const Color(0xFFEC1D24)
                            : Colors.grey,
                  ),
                ),
              );
            },
            inputFormatters: [LengthLimitingTextInputFormatter(21)],
            decoration: _inputDecoration(hasError: errorMsg != null),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEC1D24),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _verificationTimeField({
    required ZoneConfig zone,
    required int zoneIndex,
  }) {
    final isReadOnly =
        zone.mode == 'Immediate' ||
        zone.mode == 'Normal' ||
        zone.mode == 'Confirmed';
    final errorMsg = _verificationErrors[zoneIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Verification Time (s)'),
          const SizedBox(height: 6),
          TextField(
            controller: zone.verificationTimeController,
            readOnly: isReadOnly,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hasError: errorMsg != null),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEC1D24),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────── PRIMARY BUTTON ─────────────────

  Widget _primaryButton({required bool isValid}) {
    return SizedBox(
      width: double.infinity,
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
            isValid
                ? () {
                  for (int i = 0; i < 3; i++) {
                    final zone = zones[i];

                    final config = ZoneModeConfig(
                      zoneEnable:
                          zone.enabled == 'Yes'
                              ? ZoneEnable.enabled
                              : ZoneEnable.disabled,
                      zoneTestMode:
                          zone.test == 'Yes'
                              ? ZoneTestMode.test
                              : ZoneTestMode.normal,
                      zoneType:
                          typeOptions.indexOf(zone.type) == 0
                              ? ZoneType.normal
                              : ZoneType.isMtl5561,
                    );

                    final String hexValue = ZoneModeCodec.encodeHex(config);

                    switch (i) {
                      case 0:
                        manager!.zoneOneSetupText.value =
                            zone.zoneTextController.text;
                        manager!.zoneOneSetupType.value = typeOptions.indexOf(
                          zone.type,
                        );
                        manager!.isZoneOneSetupEnabled.value =
                            zone.enabled == 'Yes';
                        manager!.isZoneOneSetupTest.value = zone.test == 'Yes';
                        manager!.zoneOneSetupMode.value = hexValue;
                        manager!.zoneOneSetupVerificationTime.value =
                            zone.verificationTimeController.text;
                        manager!.zoneOneSetupDetectionMode.value = modeOptions
                            .indexOf(zone.mode);
                        break;

                      case 1:
                        manager!.zoneTwoSetupText.value =
                            zone.zoneTextController.text;
                        manager!.zoneTwoSetupType.value = typeOptions.indexOf(
                          zone.type,
                        );
                        manager!.isZoneTwoSetupEnabled.value =
                            zone.enabled == 'Yes';
                        manager!.isZoneTwoSetupTest.value = zone.test == 'Yes';
                        manager!.zoneTwoSetupMode.value = hexValue;
                        manager!.zoneTwoSetupVerificationTime.value =
                            zone.verificationTimeController.text;
                        manager!.zoneTwoSetupDetectionMode.value = modeOptions
                            .indexOf(zone.mode);
                        break;

                      case 2:
                        manager!.zoneThreeSetupText.value =
                            zone.zoneTextController.text;
                        manager!.zoneThreeSetupType.value = typeOptions.indexOf(
                          zone.type,
                        );
                        manager!.isZoneThreeSetupEnabled.value =
                            zone.enabled == 'Yes';
                        manager!.isZoneThreeSetupTest.value =
                            zone.test == 'Yes';
                        manager!.zoneThreeSetupMode.value = hexValue;
                        manager!.zoneThreeSetupVerificationTime.value =
                            zone.verificationTimeController.text;
                        manager!.zoneThreeSetupDetectionMode.value = modeOptions
                            .indexOf(zone.mode);
                        break;
                    }
                  }

                  Navigator.pop(context);
                  widget.onCall();
                }
                : null,
        child: Text(
          'Apply Configuration',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
  //             items:
  //                 items
  //                     .map(
  //                       (e) => DropdownMenuItem(
  //                         value: e,
  //                         child: Text(e, overflow: TextOverflow.ellipsis),
  //                       ),
  //                     )
  //                     .toList(),
  //             onChanged: (v) => onChanged(v!),
  //             decoration: _inputDecoration(),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? const Color(0xFFEC1D24) : const Color(0xFFD0D0D0);

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),

      // 🔥 MATCH OTHER SHEETS
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

class ZoneConfig {
  final int zoneNumber;

  String type = 'Normal';
  String enabled = 'No';
  String test = 'No';
  String mode = 'Immediate';

  TextEditingController zoneTextController = TextEditingController();
  TextEditingController verificationTimeController = TextEditingController();

  ZoneConfig({required this.zoneNumber});
}
