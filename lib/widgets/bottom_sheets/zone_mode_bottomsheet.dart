import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/zone_mode_util.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: List.generate(3, (i) => _zoneTile(i)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _primaryButton(),
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
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Zone ${zone.zoneNumber}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          children: [
            _textField('Zone Text', zone.zoneTextController),

            _dropdown(
              'Type',
              zone.type,
              typeOptions,
              (v) => setState(() => zone.type = v),
            ),

            _dropdown('Enabled', zone.enabled, yesNoOptions, (v) {
              setState(() {
                zone.enabled = v;
                if (v == 'No') zone.test = 'No';
              });
            }),

            _dropdown('Test', zone.test, yesNoOptions, (v) {
              setState(() {
                zone.test = v;
                if (v == 'Yes') zone.enabled = 'Yes';
              });
            }),

            _dropdown(
              'Mode',
              zone.mode,
              modeOptions,
              (v) => setState(() => zone.mode = v),
            ),

            _dynamicField(
              label: 'Verification Time (s)',
              controller: zone.verificationTimeController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // ───────────────── PRIMARY BUTTON ─────────────────

  Widget _primaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          for (int i = 0; i < 3; i++) {
            final zone = zones[i];

            final config = ZoneModeConfig(
              zoneEnable:
                  zone.enabled == 'Yes'
                      ? ZoneEnable.enabled
                      : ZoneEnable.disabled,
              zoneTestMode:
                  zone.test == 'Yes' ? ZoneTestMode.test : ZoneTestMode.normal,
              zoneType:
                  typeOptions.indexOf(zone.type) == 0
                      ? ZoneType.normal
                      : ZoneType.isMtl5561,
            );

            final String hexValue = ZoneModeCodec.encodeHex(config);

            switch (i) {
              case 0:
                manager!.zoneOneSetupText.value = zone.zoneTextController.text;
                manager!.zoneOneSetupType.value = typeOptions.indexOf(
                  zone.type,
                );
                manager!.isZoneOneSetupEnabled.value = zone.enabled == 'Yes';
                manager!.isZoneOneSetupTest.value = zone.test == 'Yes';
                manager!.zoneOneSetupMode.value = hexValue;
                manager!.zoneOneSetupVerificationTime.value =
                    zone.verificationTimeController.text;
                manager!.zoneOneSetupDetectionMode.value = modeOptions.indexOf(
                  zone.mode,
                );
                break;

              case 1:
                manager!.zoneTwoSetupText.value = zone.zoneTextController.text;
                manager!.zoneTwoSetupType.value = typeOptions.indexOf(
                  zone.type,
                );
                manager!.isZoneTwoSetupEnabled.value = zone.enabled == 'Yes';
                manager!.isZoneTwoSetupTest.value = zone.test == 'Yes';
                manager!.zoneTwoSetupMode.value = hexValue;
                manager!.zoneTwoSetupVerificationTime.value =
                    zone.verificationTimeController.text;
                manager!.zoneTwoSetupDetectionMode.value = modeOptions.indexOf(
                  zone.mode,
                );
                break;

              case 2:
                manager!.zoneThreeSetupText.value =
                    zone.zoneTextController.text;
                manager!.zoneThreeSetupType.value = typeOptions.indexOf(
                  zone.type,
                );
                manager!.isZoneThreeSetupEnabled.value = zone.enabled == 'Yes';
                manager!.isZoneThreeSetupTest.value = zone.test == 'Yes';
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
        },
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

  Widget _textField(String label, TextEditingController controller) {
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

  Widget _dynamicField({
    required String label,
    required TextEditingController controller,
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
            inputFormatters: inputFormatters,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

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
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged: (v) => onChanged(v!),
              decoration: _inputDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
