import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class SounderModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const SounderModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<SounderModeBottomSheet> createState() => _SounderModeBottomSheetState();
}

class _SounderModeBottomSheetState extends State<SounderModeBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BleManager? manager;
  final ScrollController sounderBottomSheetController = ScrollController();

  final List<String> groupOptions = ['None', 'General', 'Zone', 'Ext. Out'];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': ['Fire Snd'],
    'Zone': ['Fire Snd'],
    'Ext. Out': ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'],
  };

  final List<String> yesNoOptions = ['No', 'Yes'];

  final List<String> typeOptions = ['Normal', 'IS (MTL5525)'];

  final List<String> actionOptions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
  ];

  final List<String> extOutActionOptions = [
    'Continuous',
    'Pulsing 1s on, 1s off',
    'Pulsing 1s on, 4s off',
    'Pulsing 2s on, 500ms off',
    'Off',
  ];

  final functions = ['Ext. Snd 1', 'Ext. Snd 2', 'Man. Release Snd'];

  late List<SounderConfig> sounders;
  late List<ZoneConfig> zones;
  late List<ExtOutConfig> extOuts;

  final TextEditingController delayController = TextEditingController(
    text: '0',
  );

  final FocusNode delayFocusNode = FocusNode();

  String delayed = 'No';

  final String _delayError = "Delay must be between 0 and 600 seconds";

  bool _isDelayValid() {
    final val = int.tryParse(delayController.text);
    return val != null && val >= 0 && val <= 600;
  }

  // void _updateDelayError() {
  //   final val = int.tryParse(delayController.text);

  //   if (val == null || val < 0 || val > 600) {
  //     _delayError = 'Delay must be between 0 and 600 seconds';
  //   } else {
  //     _delayError = null;
  //   }
  // }

  @override
  void initState() {
    super.initState();

    delayFocusNode.addListener(() {
      if (delayFocusNode.hasFocus) {
        debugPrint("Delay field is focused");
      } else {
        debugPrint("Delay field lost focus");
      }
    });

    _tabController = TabController(length: 4, vsync: this);

    sounders = List.generate(3, (i) {
      final config = SounderConfig(index: i);

      if (i == 0) {
        config.group = 'General';
        config.function = 'Fire Snd';
        config.groupLocked = true;
        config.functionLocked = true;
      }

      return config;
    });

    zones = List.generate(3, (i) => ZoneConfig(index: i));

    extOuts = List.generate(3, (i) => ExtOutConfig(index: i));

    _loadData();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    _tabController.dispose();
    delayFocusNode.dispose();
    delayController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await PeripheralSetupCache.loadSounderSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    final s1 = data['s1'] as Map<String, dynamic>?;
    final s2 = data['s2'] as Map<String, dynamic>?;
    final s3 = data['s3'] as Map<String, dynamic>?;
    final z1 = data['z1'] as Map<String, dynamic>?;
    final z2 = data['z2'] as Map<String, dynamic>?;
    final z3 = data['z3'] as Map<String, dynamic>?;
    final e1 = data['e1'] as Map<String, dynamic>?;
    final e2 = data['e2'] as Map<String, dynamic>?;
    final e3 = data['e3'] as Map<String, dynamic>?;

    if (s1 != null) {
      sounders[0].enabled = (s1['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[0].test = (s1['test'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[0].type =
          (s1['normal'] as bool?) ?? true ? 'Normal' : 'IS (MTL5525)';
      sounders[0].outputController.text = (s1['outputText'] as String?) ?? '';
      sounders[0].group =
          groupOptions[((s1['group'] as int?) ?? 0).clamp(
            0,
            groupOptions.length - 1,
          )];
      sounders[0].function =
          functionOptionsMap[sounders[0].group]![((s1['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[0].group]!.length - 1)];
    }
    if (s2 != null) {
      sounders[1].enabled = (s2['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[1].test = (s2['test'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[1].type =
          (s2['normal'] as bool?) ?? true ? 'Normal' : 'IS (MTL5525)';
      sounders[1].outputController.text = (s2['outputText'] as String?) ?? '';
      sounders[1].group =
          groupOptions[((s2['group'] as int?) ?? 0).clamp(
            0,
            groupOptions.length - 1,
          )];
      sounders[1].function =
          functionOptionsMap[sounders[1].group]![((s2['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[1].group]!.length - 1)];
      sounders[1].dynamicController.text =
          (s2['functionNo'] as int?)?.toString() ?? '0';
    }
    if (s3 != null) {
      sounders[2].enabled = (s3['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[2].test = (s3['test'] as bool?) ?? false ? 'Yes' : 'No';
      sounders[2].type =
          (s3['normal'] as bool?) ?? true ? 'Normal' : 'IS (MTL5525)';
      sounders[2].outputController.text = (s3['outputText'] as String?) ?? '';
      sounders[2].group =
          groupOptions[((s3['group'] as int?) ?? 0).clamp(
            0,
            groupOptions.length - 1,
          )];
      sounders[2].function =
          functionOptionsMap[sounders[2].group]![((s3['function'] as int?) ?? 0)
              .clamp(0, functionOptionsMap[sounders[2].group]!.length - 1)];
      sounders[2].dynamicController.text =
          (s3['functionNo'] as int?)?.toString() ?? '0';
    }
    if (z1 != null) {
      zones[0].enabled = (z1['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      zones[0].test = (z1['test'] as bool?) ?? false ? 'Yes' : 'No';
      zones[0].action =
          actionOptions[((z1['action'] as int?) ?? 0).clamp(
            0,
            actionOptions.length - 1,
          )];
    }
    if (z2 != null) {
      zones[1].enabled = (z2['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      zones[1].test = (z2['test'] as bool?) ?? false ? 'Yes' : 'No';
      zones[1].action =
          actionOptions[((z2['action'] as int?) ?? 0).clamp(
            0,
            actionOptions.length - 1,
          )];
    }
    if (z3 != null) {
      zones[2].enabled = (z3['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      zones[2].test = (z3['test'] as bool?) ?? false ? 'Yes' : 'No';
      zones[2].action =
          actionOptions[((z3['action'] as int?) ?? 0).clamp(
            0,
            actionOptions.length - 1,
          )];
    }
    if (e1 != null) {
      extOuts[0].enabled = (e1['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[0].test = (e1['test'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[0].countdownAction =
          extOutActionOptions[((e1['countdownAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[0].holdAction =
          extOutActionOptions[((e1['holdAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[0].releaseAction =
          extOutActionOptions[((e1['releaseAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
    }
    if (e2 != null) {
      extOuts[1].enabled = (e2['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[1].test = (e2['test'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[1].countdownAction =
          extOutActionOptions[((e2['countdownAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[1].holdAction =
          extOutActionOptions[((e2['holdAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[1].releaseAction =
          extOutActionOptions[((e2['releaseAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
    }
    if (e3 != null) {
      extOuts[2].enabled = (e3['enabled'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[2].test = (e3['test'] as bool?) ?? false ? 'Yes' : 'No';
      extOuts[2].countdownAction =
          extOutActionOptions[((e3['countdownAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[2].holdAction =
          extOutActionOptions[((e3['holdAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
      extOuts[2].releaseAction =
          extOutActionOptions[((e3['releaseAction'] as int?) ?? 0).clamp(
            0,
            extOutActionOptions.length - 1,
          )];
    }
    final gen = data['general'] as Map<String, dynamic>?;
    if (gen != null) {
      delayController.text = (gen['delay'] as int?)?.toString() ?? '0';
    }
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    final sounderOne = sounders[0];
    final sounderTwo = sounders[1];
    final sounderThree = sounders[2];

    sounderOne.enabled = manager!.isSounderOneEnabled.value ? 'Yes' : 'No';
    sounderOne.test = manager!.isSounderOneTest.value ? 'Yes' : 'No';
    sounderOne.type =
        manager!.isSounderOneNormal.value ? 'Normal' : 'IS (MTL5525)';
    sounderTwo.enabled = manager!.isSounderTwoEnabled.value ? 'Yes' : 'No';
    sounderTwo.test = manager!.isSounderTwoTest.value ? 'Yes' : 'No';
    sounderTwo.type =
        manager!.isSounderTwoNormal.value ? 'Normal' : 'IS (MTL5525)';
    sounderThree.enabled = manager!.isSounderThreeEnabled.value ? 'Yes' : 'No';
    sounderThree.test = manager!.isSounderThreeTest.value ? 'Yes' : 'No';
    sounderThree.type =
        manager!.isSounderThreeNormal.value ? 'Normal' : 'IS (MTL5525)';
    sounderOne.outputController.text = manager!.sounderOneOutputText.value;
    sounderTwo.outputController.text = manager!.sounderTwoOutputText.value;
    sounderThree.outputController.text = manager!.sounderThreeOutputText.value;

    sounderOne.group =
        groupOptions[manager!.sounderOneRelayFunctionGroup.value];
    sounderTwo.group =
        groupOptions[manager!.sounderTwoRelayFunctionGroup.value];
    sounderThree.group =
        groupOptions[manager!.sounderThreeRelayFunctionGroup.value];
    sounderOne.function =
        functionOptionsMap[sounderOne.group]![manager!
            .sounderOneRelayFunction
            .value];
    sounderTwo.function =
        functionOptionsMap[sounderTwo.group]![manager!
            .sounderTwoRelayFunction
            .value];
    sounderThree.function =
        functionOptionsMap[sounderThree.group]![manager!
            .sounderThreeRelayFunction
            .value];

    sounderTwo.dynamicController.text =
        manager!.sounderTwoFunctionNo.value.toString();
    sounderThree.dynamicController.text =
        manager!.sounderThreeFunctionNo.value.toString();

    delayController.text = manager!.sounderGeneralDelay.value.toString();

    final zoneOne = zones[0];
    final zoneTwo = zones[1];
    final zoneThree = zones[2];

    zoneOne.enabled = manager!.isZoneOneEnabled.value ? 'Yes' : 'No';
    zoneOne.test = manager!.isZoneOneTest.value ? 'Yes' : 'No';
    zoneOne.action = actionOptions[manager!.zoneOneAction.value];
    zoneTwo.enabled = manager!.isZoneTwoEnabled.value ? 'Yes' : 'No';
    zoneTwo.test = manager!.isZoneTwoTest.value ? 'Yes' : 'No';
    zoneTwo.action = actionOptions[manager!.zoneTwoAction.value];
    zoneThree.enabled = manager!.isZoneThreeEnabled.value ? 'Yes' : 'No';
    zoneThree.test = manager!.isZoneThreeTest.value ? 'Yes' : 'No';
    zoneThree.action = actionOptions[manager!.zoneThreeAction.value];

    final extOutOne = extOuts[0];
    final extOutTwo = extOuts[1];
    final extOutThree = extOuts[2];

    extOutOne.enabled = manager!.isExtOutOneEnabled.value ? 'Yes' : 'No';
    extOutOne.test = manager!.isExtOutOneTest.value ? 'Yes' : 'No';
    extOutOne.countdownAction =
        extOutActionOptions[manager!.extoutOneCountdownAction.value];
    extOutOne.holdAction =
        extOutActionOptions[manager!.extoutOneHoldAction.value];
    extOutOne.releaseAction =
        extOutActionOptions[manager!.extoutOneReleaseAction.value];
    extOutTwo.enabled = manager!.isExtOutTwoEnabled.value ? 'Yes' : 'No';
    extOutTwo.test = manager!.isExtOutTwoTest.value ? 'Yes' : 'No';
    extOutTwo.countdownAction =
        extOutActionOptions[manager!.extoutTwoCountdownAction.value];
    extOutTwo.holdAction =
        extOutActionOptions[manager!.extoutTwoHoldAction.value];
    extOutTwo.releaseAction =
        extOutActionOptions[manager!.extoutTwoReleaseAction.value];
    extOutThree.enabled = manager!.isExtOutThreeEnabled.value ? 'Yes' : 'No';
    extOutThree.test = manager!.isExtOutThreeTest.value ? 'Yes' : 'No';
    extOutThree.countdownAction =
        extOutActionOptions[manager!.extoutThreeCountdownAction.value];
    extOutThree.holdAction =
        extOutActionOptions[manager!.extoutThreeHoldAction.value];
    extOutThree.releaseAction =
        extOutActionOptions[manager!.extoutThreeReleaseAction.value];

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

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
                _title('Sounder Mode Configuration'),

                // BODY
                Expanded(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction != ScrollDirection.idle) {
                        FocusScope.of(context).unfocus();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: sounderBottomSheetController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...List.generate(3, (i) => _sounderTile(i)),
                          const SizedBox(height: 24),
                          _advancedHeader(),
                          _advancedSection(),
                        ],
                      ),
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
      ),
    );
  }

  // ───────────────── SOUNDERS ─────────────────

  Widget _sounderTile(int index) {
    final sounder = sounders[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Sounder ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          children: [
            _disabledField('Output', 'SNDR ${index + 1}'),

            _textField(
              label: 'Output Text',
              controller: sounder.outputController,
              maxLength: 21,
            ),

            if (!sounder.groupLocked)
              DropdownWidget(
                label: 'Group',
                value: sounder.group,
                items: groupOptions,
                onChanged: (v) {
                  setState(() {
                    sounder.group = v;
                    sounder.function = functionOptionsMap[v]!.first;
                  });
                },
              ),

            if (!sounder.functionLocked)
              DropdownWidget(
                label: 'Function',
                value: sounder.function,
                items: functionOptionsMap[sounder.group]!,
                onChanged: (v) => setState(() => sounder.function = v),
              ),

            if (sounder.group == 'Zone')
              _textField(
                label: 'Zone',
                controller: sounder.dynamicController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
              ),

            if (sounder.group == 'Ext. Out')
              _textField(
                label: 'Ext. Out',
                controller: sounder.dynamicController,
                enabled: false,
              ),

            if (sounder.group != 'Ext. Out')
              DropdownWidget(
                label: 'Enabled',
                value: sounder.enabled,
                items: yesNoOptions,
                onChanged: (v) => setState(() => sounder.enabled = v),
              ),

            DropdownWidget(
              label: 'Test',
              value: sounder.test,
              items: yesNoOptions,
              onChanged: (v) => setState(() => sounder.test = v),
            ),

            DropdownWidget(
              label: 'Type',
              value: sounder.type,
              items: typeOptions,
              onChanged: (v) => setState(() => sounder.type = v),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // ───────────────── ADVANCED ─────────────────

  Widget _advancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text(
          'Advanced Configuration',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _advancedSection() {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF8F8F8),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.5, color: Color(0xFFEC1D24)),
            ),
            labelColor: const Color(0xFFEC1D24),
            unselectedLabelColor: const Color(0xFF6E6E6E),
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Zone'),
              Tab(text: 'Ext Out'),
              Tab(text: 'Delay'),
            ],
            onTap: (_) {
              sounderBottomSheetController.animateTo(
                sounderBottomSheetController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabController,
            children: [_generalTab(), _zoneTab(), _extOutTab(), _delayTab()],
          ),
        ),
      ],
    );
  }

  Widget _generalTab() {
    return Column(
      children: [
        _disabledField('Function', 'Fire Snd'),
        DropdownWidget(
          label: 'Enabled',
          value: yesNoOptions[manager!.isSounderGeneralEnabled.value ? 1 : 0],
          items: yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: 'Test',
          value: yesNoOptions[manager!.isSounderGeneralTest.value ? 1 : 0],
          items: yesNoOptions,
          onChanged: (_) {},
        ),
        DropdownWidget(
          label: 'Action',
          value: actionOptions[manager!.sounderGeneralAction.value],
          items: actionOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _zoneTile(int index) {
    final zone = zones[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Zone ${index + 1}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          children: [
            _disabledField('Function', 'Fire Snd'),
            _disabledField('Zone', '${index + 1}'),
            DropdownWidget(
              label: 'Enabled',
              value: zone.enabled,
              items: yesNoOptions,
              onChanged: (v) => setState(() => zone.enabled = v),
            ),
            DropdownWidget(
              label: 'Test',
              value: zone.test,
              items: yesNoOptions,
              onChanged: (v) => setState(() => zone.test = v),
            ),
            DropdownWidget(
              label: 'Action',
              value: zone.action,
              items: actionOptions,
              onChanged: (v) => setState(() => zone.action = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneTab() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (_, i) {
        return _zoneTile(i);
      },
    );
  }

  Widget _extOutTile(int index) {
    final extOut = extOuts[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            functions[index],
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          children: [
            _disabledField('Function', functions[index]),
            DropdownWidget(
              label: 'Enabled',
              value: extOut.enabled,
              items: yesNoOptions,
              onChanged: (v) => setState(() => extOut.enabled = v),
            ),
            DropdownWidget(
              label: 'Test',
              value: extOut.test,
              items: yesNoOptions,
              onChanged: (v) => setState(() => extOut.test = v),
            ),
            DropdownWidget(
              label: 'Countdown',
              value: extOut.countdownAction,
              items: extOutActionOptions,
              onChanged: (v) => setState(() => extOut.countdownAction = v),
            ),
            DropdownWidget(
              label: 'Hold',
              value: extOut.holdAction,
              items: extOutActionOptions,
              onChanged: (v) => setState(() => extOut.holdAction = v),
            ),
            DropdownWidget(
              label: 'Release',
              value: extOut.releaseAction,
              items: extOutActionOptions,
              onChanged: (v) => setState(() => extOut.releaseAction = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _extOutTab() {
    return ListView.builder(
      itemCount: functions.length,
      itemBuilder: (_, i) {
        return _extOutTile(i);
      },
    );
  }

  Widget _delayTab() {
    // _updateDelayError();

    return Column(
      children: [
        _textField(
          label: 'Delay (s)',
          controller: delayController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: _inputDecoration(),
          focusNode: delayFocusNode,
        ),
        if (delayFocusNode.hasFocus)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _delayError,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 14),
        DropdownWidget(
          label: 'Delayed',
          value: yesNoOptions[manager!.isSounderGeneralDelay.value ? 1 : 0],
          items: yesNoOptions,
          onChanged: (_) {},
        ),
      ],
    );
  }

  // ───────────────── UI HELPERS ─────────────────

  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: child,
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
          color: const Color(0xFF3D3D3D),
        ),
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    InputDecoration? decoration,
    Function(String)? onChanged,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
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
                                    ? const Color(0xFFEC1D24)
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            keyboardType: keyboardType,
            inputFormatters: [
              ...?inputFormatters,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            decoration: decoration ?? _inputDecoration(),
            onChanged: onChanged,
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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFEC1D24), width: 2),
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

  Widget _applyButton() {
    final isDelayValid = _isDelayValid();
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            manager != null && isDelayValid
                ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  for (int i = 0; i < 3; i++) {
                    final sounder = sounders[i];

                    bool isEnabled = sounder.enabled == 'Yes';
                    bool isTest = sounder.test == 'Yes';
                    bool isNormal = sounder.type == 'Normal';
                    String outputText = sounder.outputController.text;
                    int functionNo =
                        int.tryParse(sounder.dynamicController.text) ?? 0;
                    int groupIndex = returnIndex(sounder.group, groupOptions);
                    int functionIndex = returnIndex(
                      sounder.function,
                      functionOptionsMap[sounder.group]!,
                    );

                    final config = OutputModeConfig(
                      outputEnable:
                          isEnabled
                              ? OutputEnable.enabled
                              : OutputEnable.disabled,
                      outputMode: isTest ? OutputMode.test : OutputMode.normal,
                      supervisionMode:
                          isNormal
                              ? SupervisionMode.normal
                              : SupervisionMode.mtl5525,
                    );
                    final String hexValue = OutputModeCodec.encodeHex(config);

                    switch (i) {
                      case 0:
                        manager!.sounderOneRelayOutputMode.value = hexValue;
                        manager!.sounderOneRelayFunctionGroup.value =
                            groupIndex;
                        manager!.sounderOneRelayFunction.value = functionIndex;
                        manager!.sounderOneFunctionNo.value = functionNo;
                        manager!.sounderOneOutputText.value = outputText;
                        manager!.isSounderOneEnabled.value = isEnabled;
                        manager!.isSounderOneTest.value = isTest;
                        manager!.isSounderOneNormal.value = isNormal;
                        break;
                      case 1:
                        manager!.sounderTwoRelayOutputMode.value = hexValue;
                        manager!.sounderTwoRelayFunctionGroup.value =
                            groupIndex;
                        manager!.sounderTwoRelayFunction.value = functionIndex;
                        manager!.sounderTwoFunctionNo.value = functionNo;
                        manager!.sounderTwoOutputText.value = outputText;
                        manager!.isSounderTwoEnabled.value = isEnabled;
                        manager!.isSounderTwoTest.value = isTest;
                        manager!.isSounderTwoNormal.value = isNormal;
                        break;
                      case 2:
                        manager!.sounderThreeRelayOutputMode.value = hexValue;
                        manager!.sounderThreeRelayFunctionGroup.value =
                            groupIndex;
                        manager!.sounderThreeRelayFunction.value =
                            functionIndex;
                        manager!.sounderThreeFunctionNo.value = functionNo;
                        manager!.sounderThreeOutputText.value = outputText;
                        manager!.isSounderThreeEnabled.value = isEnabled;
                        manager!.isSounderThreeTest.value = isTest;
                        manager!.isSounderThreeNormal.value = isNormal;
                        break;
                    }
                  }

                  // apply general tab
                  final generalConfig = GeneralEquipmentModeConfig(
                    equipmentEnable:
                        manager!.isSounderGeneralEnabled.value
                            ? EquipmentEnable.enabled
                            : EquipmentEnable.disabled,
                    equipmentMode:
                        manager!.isSounderGeneralTest.value
                            ? EquipmentMode.test
                            : EquipmentMode.normal,
                    sounderDelay:
                        manager!.isSounderGeneralDelay.value
                            ? SounderDelay.enabled
                            : SounderDelay.disabled,
                  );
                  manager!.sounderGeneralMode.value =
                      GeneralEquipmentModeCodec.encodeHex(generalConfig);
                  manager!.sounderGeneralDelay.value =
                      int.tryParse(delayController.text) ?? 0;

                  // apply zone tab
                  for (int i = 0; i < 3; i++) {
                    final zone = zones[i];
                    bool isEnabled = zone.enabled == 'Yes';
                    bool isTest = zone.test == 'Yes';
                    int actionIndex = returnIndex(zone.action, actionOptions);
                    final zoneConfig = ZoneEquipmentModeConfig(
                      zoneEnable:
                          isEnabled
                              ? ZoneEquipmentEnable.enabled
                              : ZoneEquipmentEnable.disabled,
                      zoneMode:
                          isTest
                              ? ZoneEquipmentMode.test
                              : ZoneEquipmentMode.normal,
                      sounderDelay: ZoneSounderDelay.disabled,
                    );
                    final String zoneHexValue =
                        ZoneEquipmentModeCodec.encodeHex(zoneConfig);

                    switch (i) {
                      case 0:
                        manager!.sounderZoneOneMode.value = zoneHexValue;
                        manager!.isZoneOneEnabled.value = isEnabled;
                        manager!.isZoneOneTest.value = isTest;
                        manager!.zoneOneAction.value = actionIndex;
                        break;
                      case 1:
                        manager!.sounderZoneTwoMode.value = zoneHexValue;
                        manager!.isZoneTwoEnabled.value = isEnabled;
                        manager!.isZoneTwoTest.value = isTest;
                        manager!.zoneTwoAction.value = actionIndex;
                        break;
                      case 2:
                        manager!.sounderZoneThreeMode.value = zoneHexValue;
                        manager!.isZoneThreeEnabled.value = isEnabled;
                        manager!.isZoneThreeTest.value = isTest;
                        manager!.zoneThreeAction.value = actionIndex;
                        break;
                    }
                  }

                  // apply ext out tab
                  for (int i = 0; i < 3; i++) {
                    final extOut = extOuts[i];
                    bool isEnabled = extOut.enabled == 'Yes';
                    bool isTest = extOut.test == 'Yes';
                    int countdownIndex = returnIndex(
                      extOut.countdownAction,
                      extOutActionOptions,
                    );
                    int holdIndex = returnIndex(
                      extOut.holdAction,
                      extOutActionOptions,
                    );
                    int releaseIndex = returnIndex(
                      extOut.releaseAction,
                      extOutActionOptions,
                    );

                    final extOutConfig = ExtZoneEquipmentModeConfig(
                      zoneEnable:
                          isEnabled
                              ? ExtZoneEquipmentEnable.enabled
                              : ExtZoneEquipmentEnable.disabled,
                      zoneMode:
                          isTest
                              ? ExtZoneEquipmentMode.test
                              : ExtZoneEquipmentMode.normal,
                    );
                    final String extOutHexValue =
                        ExtZoneEquipmentModeCodec.encodeHex(extOutConfig);

                    switch (i) {
                      case 0:
                        manager!.sounderExtOutOneMode.value = extOutHexValue;
                        manager!.isExtOutOneEnabled.value = isEnabled;
                        manager!.isExtOutOneTest.value = isTest;
                        manager!.extoutOneCountdownAction.value =
                            countdownIndex;
                        manager!.extoutOneHoldAction.value = holdIndex;
                        manager!.extoutOneReleaseAction.value = releaseIndex;
                        break;
                      case 1:
                        manager!.sounderExtOutTwoMode.value = extOutHexValue;
                        manager!.isExtOutTwoEnabled.value = isEnabled;
                        manager!.isExtOutTwoTest.value = isTest;
                        manager!.extoutTwoCountdownAction.value =
                            countdownIndex;
                        manager!.extoutTwoHoldAction.value = holdIndex;
                        manager!.extoutTwoReleaseAction.value = releaseIndex;
                        break;
                      case 2:
                        manager!.sounderExtOutThreeMode.value = extOutHexValue;
                        manager!.isExtOutThreeEnabled.value = isEnabled;
                        manager!.isExtOutThreeTest.value = isTest;
                        manager!.extoutThreeCountdownAction.value =
                            countdownIndex;
                        manager!.extoutThreeHoldAction.value = holdIndex;
                        manager!.extoutThreeReleaseAction.value = releaseIndex;
                        break;
                    }
                  }

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
}

// ───────────────── MODEL ─────────────────

class SounderConfig {
  final int index;

  String group = 'None';
  String function = 'None';
  String enabled = 'No';
  String test = 'No';
  String type = 'Normal';

  bool groupLocked = false;
  bool functionLocked = false;

  TextEditingController outputController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();

  SounderConfig({required this.index});
}

class ZoneConfig {
  final int index;

  String enabled = 'No';
  String test = 'No';
  String action = 'Continuous';

  ZoneConfig({required this.index});
}

class ExtOutConfig {
  final int index;

  String enabled = 'No';
  String test = 'No';
  String countdownAction = 'Continuous';
  String holdAction = 'Continuous';
  String releaseAction = 'Continuous';

  ExtOutConfig({required this.index});
}
