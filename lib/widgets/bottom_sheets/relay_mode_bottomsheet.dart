import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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

  final ScrollController _scrollController = ScrollController();

  final List<String> groupOptions = ['None', 'General', 'Zone', StringConstants.extOut];

  late final List<GlobalKey> _tileKeys;

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      'Fault',
      StringConstants.extnlFault,
      StringConstants.supplyFault,
      StringConstants.extnlSupplyFault,
      StringConstants.sounderFault,
      StringConstants.sounderSilenced,
      StringConstants.sounderActivated,
      StringConstants.sounderDisabled,
      StringConstants.disablement,
      StringConstants.test,
      'Fire',
      StringConstants.reset,
      StringConstants.controlsEnabled,
      StringConstants.supervisory,
      StringConstants.fireSnd,
    ],
    'Zone': ['Fault', 'Fire', StringConstants.disablement, StringConstants.fireSnd],
    StringConstants.extOut: [
      StringConstants.releaseInitiated,
      StringConstants.extAgentReleased,
      StringConstants.releaseHold,
      StringConstants.manualMode,
      StringConstants.manualRelease,
      StringConstants.extnlExtFault,
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
    ],
  };

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  late List<RelayConfig> relays;

  final Map<int, String?> _outputTextErrors = {};
  final Map<int, String?> _dynamicFieldErrors = {};

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
          _dynamicFieldErrors[i] = StringConstants.zoneMustBeBetween1And3;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _tileKeys = List.generate(3, (_) => GlobalKey());

    relays = List.generate(3, (_) => RelayConfig());

    _loadData();

    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    _scrollController.dispose();

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
      relays[i].enabled = (r['enabled'] as bool?) == true ? StringConstants.yes : StringConstants.no;
      final g = (r['group'] as int?) ?? 0;
      relays[i].group = groupOptions[g.clamp(0, groupOptions.length - 1)];
      final f = (r['function'] as int?) ?? 0;
      final opts = functionOptionsMap[relays[i].group]!;
      relays[i].function = opts[f.clamp(0, opts.length - 1)];
      relays[i].outputTextController.text = (r['outputText'] as String?) ?? '';
      relays[i].dynamicController.text = (r[StringConstants.outputtext] as String?) ?? '';
    }
    for (int i = 0; i < 3; i++) {
      if (relays[i].group == StringConstants.extOut) {
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

    relays[0].enabled = manager!.isRelayOneSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    relays[0].group = groupOptions[manager!.relayOneSetupGroup.value];
    relays[0].function =
        functionOptionsMap[relays[0].group]![manager!
            .relayOneSetupFunction
            .value];
    relays[0].outputTextController.text =
        manager!.relayOneSetupOutputText.value;
    relays[0].dynamicController.text = manager!.relayOneSetupDynamicText.value;

    relays[1].enabled = manager!.isRelayTwoSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    relays[1].group = groupOptions[manager!.relayTwoSetupGroup.value];
    relays[1].function =
        functionOptionsMap[relays[1].group]![manager!
            .relayTwoSetupFunction
            .value];
    relays[1].outputTextController.text =
        manager!.relayTwoSetupOutputText.value;
    relays[1].dynamicController.text = manager!.relayTwoSetupDynamicText.value;

    relays[2].enabled = manager!.isRelayThreeSetupEnabled.value ? StringConstants.yes : StringConstants.no;
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
      if (relays[i].group == StringConstants.extOut) {
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

      final isEnabled = relay.enabled == StringConstants.yes;
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
            StringConstants.relayModeConfiguration,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ColorConstants.textDark,
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
                controller: _scrollController,
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
                    //   left: 24,
                    // right: 24,
                    // top: 16,
                    // bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    Padding(
                      padding: EdgeInsets.only(
                        left: 24.0,
                        right: 24.0,
                        top: 16.0,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        children: [
                          _dragHandle(),
                          _title('Relay Mode'),

                          Expanded(
                            child: NotificationListener<UserScrollNotification>(
                              onNotification: (notification) {
                                if (notification.direction !=
                                    ScrollDirection.idle) {
                                  FocusScope.of(context).unfocus();
                                }
                                return false;
                              },
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: List.generate(
                                    3,
                                    (i) => _relayTile(i),
                                  ),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _relayTile(int index) {
    final relay = relays[index];

    return Container(
      color: ColorConstants.white,
      key: _tileKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorConstants.borderMuted),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: ColorConstants.transparent),
            child: ExpansionTile(
              onExpansionChanged: (expanded) async {
                setState(() {
                  _expandedTileCount += expanded ? 1 : -1;
                });

                if (expanded) {
                  await Future.delayed(const Duration(milliseconds: 250));

                  final context = _tileKeys[index].currentContext;

                  if (context != null) {
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                }
              },
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Relay ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textDark,
                ),
              ),
              children: [
                _outputTextField(relay: relay, relayIndex: index),

                DropdownWidget(
                  label: StringConstants.group,
                  value: relay.group,
                  items: groupOptions,
                  onChanged: (v) {
                    setState(() {
                      relay.group = v;
                      relay.function = functionOptionsMap[v]!.first;
                      if (v == StringConstants.extOut) {
                        relay.dynamicController.text = '1';
                      }
                    });
                  },
                ),

                DropdownWidget(
                  label: StringConstants.function,
                  value: relay.function,
                  items: functionOptionsMap[relay.group]!,
                  onChanged: (v) => setState(() => relay.function = v),
                ),

                if (relay.group == 'Zone')
                  _zoneDynamicField(relay: relay, relayIndex: index),

                if (relay.group == StringConstants.extOut)
                  _extOutDynamicField(relay: relay),

                DropdownWidget(
                  label: StringConstants.enabled,
                  value: relay.enabled,
                  items: yesNoOptions,
                  onChanged: (v) {
                    setState(() {
                      relay.enabled = v;
                      if (v == StringConstants.no && manager != null) {
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
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ColorConstants.textDark,
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
        color: ColorConstants.textDark,
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
          _label(StringConstants.outputText),
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
                            ? ColorConstants.primary
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
              color: ColorConstants.textDark,
            ),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMsg,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.primary,
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
                color: ColorConstants.primary,
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
          _label(StringConstants.extOut),
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

  InputDecoration _inputDecoration({bool hasError = false}) {
    final borderColor =
        hasError ? ColorConstants.primary : ColorConstants.borderLight;

    return InputDecoration(
      filled: true,
      fillColor: ColorConstants.surfaceLight,
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
        borderSide: const BorderSide(color: ColorConstants.primary, width: 2),
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

  Widget _applyButton({required bool isValid}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
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

class RelayConfig {
  String group = 'None';
  String function = 'None';
  String enabled = StringConstants.no;

  TextEditingController outputTextController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();
}
