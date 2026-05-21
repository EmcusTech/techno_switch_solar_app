import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';

class TestModeRelayBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const TestModeRelayBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<TestModeRelayBottomSheet> createState() =>
      _TestModeRelayBottomSheetState();
}

class _TestModeRelayBottomSheetState extends State<TestModeRelayBottomSheet> {
  BleManager? manager;

  final List<String> yesNoOptions = ['No', 'Yes'];

  @override
  void initState() {
    super.initState();
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
    if (cached != null && manager != null) {
      applyRelayTestFlagsFromCacheMap(manager!, cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
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
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        _dragHandle(),
                        _title('Relay Test'),
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
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 16),
                              child:
                                  manager == null
                                      ? const SizedBox.shrink()
                                      : AnimatedBuilder(
                                        animation: Listenable.merge([
                                          manager!.isRelayOneSetupTest,
                                          manager!.isRelayTwoSetupTest,
                                          manager!.isRelayThreeSetupTest,
                                        ]),
                                        builder: (context, _) {
                                          return Column(
                                            children: [
                                              DropdownWidget(
                                                label: 'Relay 1 Test',
                                                value:
                                                    manager!
                                                            .isRelayOneSetupTest
                                                            .value
                                                        ? 'Yes'
                                                        : 'No',
                                                items: yesNoOptions,
                                                onChanged:
                                                    (v) => _onTestChanged(
                                                      0,
                                                      v == 'Yes',
                                                    ),
                                              ),
                                              DropdownWidget(
                                                label: 'Relay 2 Test',
                                                value:
                                                    manager!
                                                            .isRelayTwoSetupTest
                                                            .value
                                                        ? 'Yes'
                                                        : 'No',
                                                items: yesNoOptions,
                                                onChanged:
                                                    (v) => _onTestChanged(
                                                      1,
                                                      v == 'Yes',
                                                    ),
                                              ),
                                              DropdownWidget(
                                                label: 'Relay 3 Test',
                                                value:
                                                    manager!
                                                            .isRelayThreeSetupTest
                                                            .value
                                                        ? 'Yes'
                                                        : 'No',
                                                items: yesNoOptions,
                                                onChanged:
                                                    (v) => _onTestChanged(
                                                      2,
                                                      v == 'Yes',
                                                    ),
                                              ),
                                            ],
                                          );
                                        },
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTestChanged(int index, bool test) {
    final m = manager;
    if (m == null) return;
    setRelayTestOnManager(m, index, test);
    if (test) setRelayEnabledOnManager(m, index, true);
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
            manager != null
                ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  syncRelayOutputModeHexFromBleManager(manager!);
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
}
