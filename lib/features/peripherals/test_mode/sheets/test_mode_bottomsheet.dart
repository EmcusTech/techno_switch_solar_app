import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/ble/ble_manager.dart';
import 'package:Technoswitch/features/peripherals/test_mode/controllers/test_mode_relay_controller.dart';
import 'package:Technoswitch/features/peripherals/test_mode/controllers/test_mode_sounder_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/common/dropdown.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

/// Sounder and relay test values on two tabs, with one Download and one Apply.
class TestModeBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> sounderRefreshTrigger;
  final ValueNotifier<int> relayRefreshTrigger;

  const TestModeBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.sounderRefreshTrigger,
    required this.relayRefreshTrigger,
  });

  @override
  State<TestModeBottomSheet> createState() => _TestModeBottomSheetState();
}

class _TestModeBottomSheetState extends State<TestModeBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TestModeSounderController sounderController;
  late final TestModeRelayController relayController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    sounderController = Get.put(
      TestModeSounderController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.sounderRefreshTrigger,
      ),
    );
    relayController = Get.put(
      TestModeRelayController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.relayRefreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<TestModeSounderController>();
    Get.delete<TestModeRelayController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestModeSounderController>(
      init: sounderController,
      builder: (sounders) {
        return GetBuilder<TestModeRelayController>(
          init: relayController,
          builder: (relays) {
            final canApply =
                sounders.manager != null && relays.manager != null;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: PeripheralSheetChrome.lipColor,
                    borderRadius: PeripheralSheetChrome.topRadius(),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: PeripheralSheetChrome.lipPadding,
                    ),
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: ColorConstants.white,
                        borderRadius: PeripheralSheetChrome.topRadius(),
                      ),
                      child: Stack(
                        children: [
                          const PeripheralSheetHeaderRow(),
                          Padding(
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 16,
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const PeripheralSheetDragHandle(),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    StringConstants.testMode,
                                    style: StyleConstants.textDark20w700Style,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(child: _tabs(sounders, relays)),
                                const SizedBox(height: 12),
                                _actions(canApply),
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
          },
        );
      },
    );
  }

  Widget _tabs(
    TestModeSounderController sounders,
    TestModeRelayController relays,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 48,
            width: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.surfaceLight,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5,
                  color: ColorConstants.primary,
                ),
              ),
              labelColor: ColorConstants.primary,
              unselectedLabelColor: ColorConstants.textSubtle,
              labelStyle: StyleConstants.black13w600Style,
              unselectedLabelStyle: StyleConstants.black13w500Style,
              tabs: const [
                Tab(text: StringConstants.sounders),
                Tab(text: StringConstants.relays),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _testList(
                manager: sounders.manager,
                tests:
                    sounders.manager == null
                        ? const []
                        : [
                          _TestRow(
                            StringConstants.sounder1Test,
                            sounders.manager!.isSounderOneTest,
                            (test) => sounders.onTestChanged(0, test),
                          ),
                          _TestRow(
                            StringConstants.sounder2Test,
                            sounders.manager!.isSounderTwoTest,
                            (test) => sounders.onTestChanged(1, test),
                          ),
                          _TestRow(
                            StringConstants.sounder3Test,
                            sounders.manager!.isSounderThreeTest,
                            (test) => sounders.onTestChanged(2, test),
                          ),
                        ],
                options: sounders.yesNoOptions,
              ),
              _testList(
                manager: relays.manager,
                tests:
                    relays.manager == null
                        ? const []
                        : [
                          _TestRow(
                            StringConstants.relay1Test,
                            relays.manager!.isRelayOneSetupTest,
                            (test) => relays.onTestChanged(0, test),
                          ),
                          _TestRow(
                            StringConstants.relay2Test,
                            relays.manager!.isRelayTwoSetupTest,
                            (test) => relays.onTestChanged(1, test),
                          ),
                          _TestRow(
                            StringConstants.relay3Test,
                            relays.manager!.isRelayThreeSetupTest,
                            (test) => relays.onTestChanged(2, test),
                          ),
                        ],
                options: relays.yesNoOptions,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _testList({
    required BleManager? manager,
    required List<_TestRow> tests,
    required List<String> options,
  }) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: peripheralSheetScrollPadding(top: 4),
        child:
            manager == null
                ? const SizedBox.shrink()
                : AnimatedBuilder(
                  animation: Listenable.merge([
                    for (final row in tests) row.flag,
                  ]),
                  builder: (context, _) {
                    return peripheralSheetFieldGrid([
                      for (final row in tests)
                        DropdownWidget(
                          label: row.label,
                          value:
                              row.flag.value
                                  ? StringConstants.yes
                                  : StringConstants.no,
                          items: options,
                          onChanged:
                              (value) =>
                                  row.onChanged(value == StringConstants.yes),
                        ),
                    ]);
                  },
                ),
      ),
    );
  }

  Widget _actions(bool canApply) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primary,
                side: const BorderSide(color: ColorConstants.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onDownload();
              },
              child: Text(
                StringConstants.download,
                style: StyleConstants.primary16w600Style,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  canApply
                      ? () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        sounderController.applyTest();
                        relayController.applyTest();
                        widget.onApply();
                      }
                      : null,
              child: Text(
                StringConstants.apply,
                style: StyleConstants.white16w600Style,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TestRow {
  const _TestRow(this.label, this.flag, this.onChanged);

  final String label;
  final ValueNotifier<bool> flag;
  final ValueChanged<bool> onChanged;
}
