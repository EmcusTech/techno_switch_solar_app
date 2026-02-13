import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';

class RelayModeBottomSheet extends StatefulWidget {
  final Function() onCall;

  const RelayModeBottomSheet({super.key, required this.onCall});

  @override
  State<RelayModeBottomSheet> createState() => _RelayModeBottomSheetState();
}

class _RelayModeBottomSheetState extends State<RelayModeBottomSheet> {
  BleManager? manager;

  final List<String> groupOptions = ['None', 'General', 'Zone', 'Ext. Out'];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      'Fault',
      'Extnl. Fault',
      'Supply Fault',
      'Extnl. Supply Fault',
      'Sounder Fault',
      'Sounder Silenced',
      'Sounder Activated',
      'Sounder Disabled',
      'Disablement',
      'Test',
      'Fire',
      'Reset',
      'Controls Enabled',
      'Supervisory',
      'Fire Snd',
    ],
    'Zone': ['Fault', 'Fire', 'Disablement', 'Fire Snd'],
    'Ext. Out': [
      'Release Initiated',
      'Ext. Agent Released',
      'Release Hold',
      'Manual Mode',
      'Manual Release',
      'Extnl. Ext. Fault',
      'Ext. Snd 1',
      'Ext. Snd 2',
      'Man. Release Snd',
    ],
  };

  final List<String> yesNoOptions = ['No', 'Yes'];

  late List<RelayConfig> relays;

  Map<int, String?> _outputTextErrors = {};
  Map<int, String?> _dynamicFieldErrors = {};

  bool _computeIsValid() {
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];
      if (relay.outputTextController.text.length > 21) return false;
      if (relay.group == 'Zone') {
        final val = int.tryParse(relay.dynamicController.text);
        if (val == null || val < 1 || val > 3) return false;
      }
    }
    return true;
  }

  void _updateValidationErrors() {
    _outputTextErrors.clear();
    _dynamicFieldErrors.clear();
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];
      if (relay.outputTextController.text.length > 21) {
        _outputTextErrors[i] =
            'Output text must be at most 21 characters (currently ${relay.outputTextController.text.length})';
      }
      if (relay.group == 'Zone') {
        final val = int.tryParse(relay.dynamicController.text);
        if (val == null || val < 1 || val > 3) {
          _dynamicFieldErrors[i] = 'Zone must be between 1 and 3';
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    relays = List.generate(3, (_) => RelayConfig());

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;

      // Relay 1
      relays[0].enabled = manager!.isRelayOneSetupEnabled.value ? 'Yes' : 'No';
      relays[0].test = manager!.isRelayOneSetupTest.value ? 'Yes' : 'No';
      relays[0].group = groupOptions[manager!.relayOneSetupGroup.value];
      relays[0].function =
          functionOptionsMap[relays[0].group]![manager!
              .relayOneSetupFunction
              .value];
      relays[0].outputTextController.text =
          manager!.relayOneSetupOutputText.value;
      relays[0].dynamicController.text =
          manager!.relayOneSetupDynamicText.value;

      // Relay 2
      relays[1].enabled = manager!.isRelayTwoSetupEnabled.value ? 'Yes' : 'No';
      relays[1].test = manager!.isRelayTwoSetupTest.value ? 'Yes' : 'No';
      relays[1].group = groupOptions[manager!.relayTwoSetupGroup.value];
      relays[1].function =
          functionOptionsMap[relays[1].group]![manager!
              .relayTwoSetupFunction
              .value];
      relays[1].outputTextController.text =
          manager!.relayTwoSetupOutputText.value;
      relays[1].dynamicController.text =
          manager!.relayTwoSetupDynamicText.value;

      // Relay 3
      relays[2].enabled =
          manager!.isRelayThreeSetupEnabled.value ? 'Yes' : 'No';
      relays[2].test = manager!.isRelayThreeSetupTest.value ? 'Yes' : 'No';
      relays[2].group = groupOptions[manager!.relayThreeSetupGroup.value];
      relays[2].function =
          functionOptionsMap[relays[2].group]![manager!
              .relayThreeSetupFunction
              .value];
      relays[2].outputTextController.text =
          manager!.relayThreeSetupOutputText.value;
      relays[2].dynamicController.text =
          manager!.relayThreeSetupDynamicText.value;
    }

    for (int i = 0; i < 3; i++) {
      if (relays[i].group == 'Ext. Out') {
        relays[i].dynamicController.text = '1';
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
              _title('Relay Mode Configuration'),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: List.generate(3, (i) => _relayTile(i)),
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

  // ───────────────── RELAY SECTION ─────────────────

  Widget _relayTile(int index) {
    final relay = relays[index];

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
            'Relay ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          children: [
            _outputTextField(relay: relay, relayIndex: index),

            _dropdown('Group', relay.group, groupOptions, (v) {
              setState(() {
                relay.group = v;
                relay.function = functionOptionsMap[v]!.first;
                if (v == 'Ext. Out') {
                  relay.dynamicController.text = '1';
                } else {
                  relay.dynamicController.clear();
                }
              });
            }),

            _dropdown(
              'Function',
              relay.function,
              functionOptionsMap[relay.group]!,
              (v) => setState(() => relay.function = v),
            ),

            if (relay.group == 'Zone')
              _zoneDynamicField(relay: relay, relayIndex: index),

            if (relay.group == 'Ext. Out')
              _extOutDynamicField(relay: relay),

            _dropdown('Enabled', relay.enabled, yesNoOptions, (v) {
              setState(() {
                relay.enabled = v;
                if (v == 'No') {
                  relay.test = 'No';
                }
              });
            }),

            _dropdown('Test', relay.test, yesNoOptions, (v) {
              setState(() {
                relay.test = v;
                if (v == 'Yes') {
                  relay.enabled = 'Yes';
                }
              });
            }),

            const SizedBox(height: 14),
          ],
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

  Widget _outputTextField({required RelayConfig relay, required int relayIndex}) {
    final errorMsg = _outputTextErrors[relayIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Output Text'),
          const SizedBox(height: 6),
          TextField(
            controller: relay.outputTextController,
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

  Widget _zoneDynamicField({
    required RelayConfig relay,
    required int relayIndex,
  }) {
    final errorMsg = _dynamicFieldErrors[relayIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Zone'),
          const SizedBox(height: 6),
          TextField(
            controller: relay.dynamicController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
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

  Widget _extOutDynamicField({required RelayConfig relay}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Ext. Out'),
          const SizedBox(height: 6),
          TextField(
            controller: relay.dynamicController,
            readOnly: true,
            enabled: false,
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

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? const Color(0xFFEC1D24) : const Color(0xFFD0D0D0);
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  int returnIndex(String value, List<String> list) {
    return list.indexOf(value);
  }

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
        onPressed: isValid
            ? () {
          for (int i = 0; i < 3; i++) {
            final relay = relays[i];

            bool isEnabled = relay.enabled == 'Yes';
            bool isTest = relay.test == 'Yes';

            final config = OutputModeConfig(
              outputEnable:
                  isEnabled ? OutputEnable.enabled : OutputEnable.disabled,
              outputMode: isTest ? OutputMode.test : OutputMode.normal,
            );

            final String hexValue = OutputModeCodec.encodeHex(config);

            int groupIndex = returnIndex(relay.group, groupOptions);
            int functionIndex = returnIndex(
              relay.function,
              functionOptionsMap[relay.group]!,
            );

            print("Relay ${i + 1} HEX → $hexValue");
            print("Group Index → $groupIndex");
            print("Function Index → $functionIndex");

            switch (i) {
              case 0:
                manager!.relayOneMode.value = hexValue;
                manager!.relayOneSetupGroup.value = groupIndex;
                manager!.relayOneSetupFunction.value = functionIndex;
                manager!.isRelayOneSetupEnabled.value = isEnabled;
                manager!.isRelayOneSetupTest.value = isTest;
                manager!.relayOneSetupOutputText.value =
                    relay.outputTextController.text;
                manager!.relayOneSetupDynamicText.value =
                    relay.dynamicController.text;
                break;

              case 1:
                manager!.relayTwoMode.value = hexValue;
                manager!.relayTwoSetupGroup.value = groupIndex;
                manager!.relayTwoSetupFunction.value = functionIndex;
                manager!.isRelayTwoSetupEnabled.value = isEnabled;
                manager!.isRelayTwoSetupTest.value = isTest;
                manager!.relayTwoSetupOutputText.value =
                    relay.outputTextController.text;
                manager!.relayTwoSetupDynamicText.value =
                    relay.dynamicController.text;
                break;

              case 2:
                manager!.relayThreeMode.value = hexValue;
                manager!.relayThreeSetupGroup.value = groupIndex;
                manager!.relayThreeSetupFunction.value = functionIndex;
                manager!.isRelayThreeSetupEnabled.value = isEnabled;
                manager!.isRelayThreeSetupTest.value = isTest;
                manager!.relayThreeSetupOutputText.value =
                    relay.outputTextController.text;
                manager!.relayThreeSetupDynamicText.value =
                    relay.dynamicController.text;
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
}

// ───────────────── MODEL ─────────────────

class RelayConfig {
  String group = 'None';
  String function = 'None';
  String enabled = 'No';
  String test = 'No';

  TextEditingController outputTextController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();
}
