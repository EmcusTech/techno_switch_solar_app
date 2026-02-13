import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

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

      // If needed, preload values from manager here
      // (Structure kept ready — plug your reactive values same as relay)
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

            print("Zone ${zone.zoneNumber}");
            print("Text → ${zone.zoneTextController.text}");
            print("Type → ${zone.type}");
            print("Enabled → ${zone.enabled}");
            print("Test → ${zone.test}");
            print("Mode → ${zone.mode}");
            print(
              "Verification Time → ${zone.verificationTimeController.text}",
            );

            // 👇 Store into manager same way you did in relay
            // Example:
            // manager!.zoneOneText.value = ...
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
