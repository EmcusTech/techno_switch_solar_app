import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class RelayModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const RelayModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<RelayModeBottomSheet> createState() => RelayModeBottomSheetState();
}

class RelayModeBottomSheetState extends State<RelayModeBottomSheet> {
  BleManager? manager;

  int _expandedTileCount = 0;

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
    final cached = await PeripheralSetupCache.loadRelaySetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    for (int i = 0; i < 3; i++) {
      final key = 'r${i + 1}';
      final r = data[key] as Map<String, dynamic>?;
      if (r == null) continue;
      relays[i].enabled = (r['enabled'] as bool?) == true ? 'Yes' : 'No';
      final g = (r['group'] as int?) ?? 0;
      relays[i].group = groupOptions[g.clamp(0, groupOptions.length - 1)];
      final f = (r['function'] as int?) ?? 0;
      final opts = functionOptionsMap[relays[i].group]!;
      relays[i].function = opts[f.clamp(0, opts.length - 1)];
      relays[i].outputTextController.text = (r['outputText'] as String?) ?? '';
      relays[i].dynamicController.text = (r['dynamicText'] as String?) ?? '';
    }
    for (int i = 0; i < 3; i++) {
      if (relays[i].group == 'Ext. Out') {
        relays[i].dynamicController.text = '1';
      }
    }
    if (manager != null) {
      applyRelayTestFlagsFromCacheMap(manager!, data);
    }
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    relays[0].enabled = manager!.isRelayOneSetupEnabled.value ? 'Yes' : 'No';
    relays[0].group = groupOptions[manager!.relayOneSetupGroup.value];
    relays[0].function =
        functionOptionsMap[relays[0].group]![manager!
            .relayOneSetupFunction
            .value];
    relays[0].outputTextController.text =
        manager!.relayOneSetupOutputText.value;
    relays[0].dynamicController.text = manager!.relayOneSetupDynamicText.value;

    relays[1].enabled = manager!.isRelayTwoSetupEnabled.value ? 'Yes' : 'No';
    relays[1].group = groupOptions[manager!.relayTwoSetupGroup.value];
    relays[1].function =
        functionOptionsMap[relays[1].group]![manager!
            .relayTwoSetupFunction
            .value];
    relays[1].outputTextController.text =
        manager!.relayTwoSetupOutputText.value;
    relays[1].dynamicController.text = manager!.relayTwoSetupDynamicText.value;

    relays[2].enabled = manager!.isRelayThreeSetupEnabled.value ? 'Yes' : 'No';
    relays[2].group = groupOptions[manager!.relayThreeSetupGroup.value];
    relays[2].function =
        functionOptionsMap[relays[2].group]![manager!
            .relayThreeSetupFunction
            .value];
    relays[2].outputTextController.text =
        manager!.relayThreeSetupOutputText.value;
    relays[2].dynamicController.text =
        manager!.relayThreeSetupDynamicText.value;

    for (int i = 0; i < 3; i++) {
      if (relays[i].group == 'Ext. Out') {
        relays[i].dynamicController.text = '1';
      }
    }
    if (mounted) setState(() {});
  }

  void _pushRelaysToManager() {
    final m = manager!;
    final snapshotTest = [
      m.isRelayOneSetupTest.value,
      m.isRelayTwoSetupTest.value,
      m.isRelayThreeSetupTest.value,
    ];
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];

      final isEnabled = relay.enabled == 'Yes';
      final isTest = isEnabled && snapshotTest[i];

      final groupIndex = returnIndex(relay.group, groupOptions);
      final functionIndex = returnIndex(
        relay.function,
        functionOptionsMap[relay.group]!,
      );

      switch (i) {
        case 0:
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
    syncRelayOutputModeHexFromBleManager(m);
  }

  Future<bool> commitLocal() async {
    _updateValidationErrors();
    if (!_computeIsValid() || manager == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _pushRelaysToManager();
    await PanelConfigCacheSync.saveRelay(
      manager!,
      widget.deviceId,
      widget.refreshTrigger,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight =
        _expandedTileCount > 0 ? screenHeight * 0.8 : screenHeight * 0.5;
    _updateValidationErrors();
    final isValid = _computeIsValid();

    if (widget.embedInCreateFlow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Relay Mode Configuration',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 12),
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
                padding: const EdgeInsets.only(top: 8),
                child: Column(children: List.generate(3, (i) => _relayTile(i))),
              ),
            ),
          ),
        ],
      );
    }

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
                _title('Relay Mode Configuration'),

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
                        children: List.generate(3, (i) => _relayTile(i)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _downloadButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _applyButton(isValid: isValid)),
                  ],
                ),
              ],
            ),
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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedTileCount += expanded ? 1 : -1;
              });
            },
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

              DropdownWidget(
                label: 'Group',
                value: relay.group,
                items: groupOptions,
                onChanged: (v) {
                  setState(() {
                    relay.group = v;
                    relay.function = functionOptionsMap[v]!.first;
                    if (v == 'Ext. Out') {
                      relay.dynamicController.text = '1';
                    }
                  });
                },
              ),

              DropdownWidget(
                label: 'Function',
                value: relay.function,
                items: functionOptionsMap[relay.group]!,
                onChanged: (v) => setState(() => relay.function = v),
              ),

              if (relay.group == 'Zone')
                _zoneDynamicField(relay: relay, relayIndex: index),

              if (relay.group == 'Ext. Out') _extOutDynamicField(relay: relay),

              DropdownWidget(
                label: 'Enabled',
                value: relay.enabled,
                items: yesNoOptions,
                onChanged: (v) {
                  setState(() {
                    relay.enabled = v;
                    if (v == 'No' && manager != null) {
                      clearRelayTestOnManager(manager!, index);
                    }
                  });
                },
              ),

              const SizedBox(height: 14),
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

  Widget _outputTextField({
    required RelayConfig relay,
    required int relayIndex,
  }) {
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

      // 🔥 SAME 24px HORIZONTAL
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

  int returnIndex(String value, List<String> list) {
    return list.indexOf(value);
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

  Widget _applyButton({required bool isValid}) {
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
                ? () async {
                  if (await commitLocal()) {
                    widget.onApply();
                  }
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
}

// ───────────────── MODEL ─────────────────

class RelayConfig {
  String group = 'None';
  String function = 'None';
  String enabled = 'No';

  TextEditingController outputTextController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();
}
