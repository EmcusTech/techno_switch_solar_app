import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class ZoneBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const ZoneBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<ZoneBottomSheet> createState() => ZoneBottomSheetState();
}

class ZoneBottomSheetState extends State<ZoneBottomSheet> {
  BleManager? manager;

  int _expandedTileCount = 0;

  final ScrollController _scrollController = ScrollController();

  late final List<GlobalKey> _tileKeys;

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
    _tileKeys = List.generate(3, (_) => GlobalKey());
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
    final cached = await PeripheralSetupCache.loadZoneSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
      _normalizeVerificationTimes();
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    for (int i = 0; i < 3; i++) {
      final key = 'z${i + 1}';
      final z = data[key] as Map<String, dynamic>?;
      if (z == null) continue;
      zones[i].type = (z['type'] as int?) == 1 ? 'IS (MTL 5561)' : 'Normal';
      zones[i].enabled = (z['enabled'] as bool?) == true ? 'Yes' : 'No';
      final dm = (z['detectionMode'] as int?) ?? 0;
      zones[i].mode = modeOptions[dm.clamp(0, modeOptions.length - 1)];
      zones[i].verificationTimeController.text =
          (z['verificationTime'] as String?) ?? '0';
      zones[i].zoneTextController.text = (z['text'] as String?) ?? '';
    }
    if (manager != null) {
      applyZoneTestFlagsFromCacheMap(manager!, data);
    }
  }

  void _normalizeVerificationTimes() {
    for (int i = 0; i < 3; i++) {
      final z = zones[i];
      if (z.mode == 'Immediate' || z.mode == 'Normal') {
        z.verificationTimeController.text = '0';
      } else if (z.mode == 'Confirmed') {
        z.verificationTimeController.text = '30';
      }
    }
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    zones[0].type =
        manager!.zoneOneSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
    zones[0].enabled = manager!.isZoneOneSetupEnabled.value ? 'Yes' : 'No';
    final int dm1 = manager!.zoneOneSetupDetectionMode.value;
    zones[0].mode =
        (dm1 >= 0 && dm1 < modeOptions.length)
            ? modeOptions[dm1]
            : modeOptions.first;
    zones[0].verificationTimeController.text =
        manager!.zoneOneSetupVerificationTime.value;
    zones[0].zoneTextController.text = manager!.zoneOneSetupText.value;

    zones[1].type =
        manager!.zoneTwoSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
    zones[1].enabled = manager!.isZoneTwoSetupEnabled.value ? 'Yes' : 'No';
    final int dm2 = manager!.zoneTwoSetupDetectionMode.value;
    zones[1].mode =
        (dm2 >= 0 && dm2 < modeOptions.length)
            ? modeOptions[dm2]
            : modeOptions.first;
    zones[1].verificationTimeController.text =
        manager!.zoneTwoSetupVerificationTime.value;
    zones[1].zoneTextController.text = manager!.zoneTwoSetupText.value;

    zones[2].type =
        manager!.zoneThreeSetupType.value == 0 ? 'Normal' : 'IS (MTL 5561)';
    zones[2].enabled = manager!.isZoneThreeSetupEnabled.value ? 'Yes' : 'No';
    final int dm3 = manager!.zoneThreeSetupDetectionMode.value;
    zones[2].mode =
        (dm3 >= 0 && dm3 < modeOptions.length)
            ? modeOptions[dm3]
            : modeOptions.first;
    zones[2].verificationTimeController.text =
        manager!.zoneThreeSetupVerificationTime.value;
    zones[2].zoneTextController.text = manager!.zoneThreeSetupText.value;

    _normalizeVerificationTimes();
    if (mounted) setState(() {});
  }

  void _pushZonesToManager() {
    final m = manager!;
    final snapshotTest = [
      m.isZoneOneSetupTest.value,
      m.isZoneTwoSetupTest.value,
      m.isZoneThreeSetupTest.value,
    ];
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      final effectiveTest = zone.enabled == 'Yes' && snapshotTest[i];

      switch (i) {
        case 0:
          m.zoneOneSetupText.value = zone.zoneTextController.text;
          m.zoneOneSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneOneSetupEnabled.value = zone.enabled == 'Yes';
          m.isZoneOneSetupTest.value = effectiveTest;
          m.zoneOneSetupVerificationTime.value =
              zone.verificationTimeController.text;
          m.zoneOneSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;

        case 1:
          m.zoneTwoSetupText.value = zone.zoneTextController.text;
          m.zoneTwoSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneTwoSetupEnabled.value = zone.enabled == 'Yes';
          m.isZoneTwoSetupTest.value = effectiveTest;
          m.zoneTwoSetupVerificationTime.value =
              zone.verificationTimeController.text;
          m.zoneTwoSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;

        case 2:
          m.zoneThreeSetupText.value = zone.zoneTextController.text;
          m.zoneThreeSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneThreeSetupEnabled.value = zone.enabled == 'Yes';
          m.isZoneThreeSetupTest.value = effectiveTest;
          m.zoneThreeSetupVerificationTime.value =
              zone.verificationTimeController.text;
          m.zoneThreeSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;
      }
    }
    syncZoneModeHexFromBleManager(m);
  }

  Future<bool> commitLocal() async {
    _updateValidationErrors();
    if (!_computeIsValid() || manager == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _pushZonesToManager();
    await PanelConfigCacheSync.saveZone(
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
            'Zone Configuration',
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
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8),
                child: Column(children: List.generate(3, (i) => _zoneTile(i))),
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
              color: Color(0xFFE31C23),
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          _title('Zone Mode'),

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
                                    (i) => _zoneTile(i),
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

  // ───────────────── ZONE TILE ─────────────────

  Widget _zoneTile(int index) {
    final zone = zones[index];

    return Container(
      key: _tileKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCDCDC)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                            if (v == 'No' && manager != null) {
                              clearZoneTestOnManager(manager!, index);
                            }
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
}

// ───────────────── MODEL ─────────────────

class ZoneConfig {
  final int zoneNumber;

  String type = 'Normal';
  String enabled = 'No';
  String mode = 'Immediate';

  TextEditingController zoneTextController = TextEditingController();
  TextEditingController verificationTimeController = TextEditingController();

  ZoneConfig({required this.zoneNumber});
}
