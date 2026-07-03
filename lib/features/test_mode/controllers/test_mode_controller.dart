import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/test_mode/models/test_mode_args.dart';
import 'package:techno_switch_solar_app/features/test_mode/models/test_mode_menu_item.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class TestModeController extends GetxController {
  TestModeController({required this.args});

  final TestModeArgs args;

  TestModeUiDelegate? _ui;

  static const List<TestModeMenuItem> menuItems = [
    TestModeMenuItem(
      title: StringConstants.batteryTest,
      iconPath: AssetConstants.batteryTestIcon,
      action: TestModeMenuAction.batteryTest,
    ),
    TestModeMenuItem(
      title: StringConstants.solarPanelTest,
      iconPath: AssetConstants.solarPanelTestIcon,
      action: TestModeMenuAction.solarPanelTest,
    ),
    TestModeMenuItem(
      title: StringConstants.inverterTest,
      iconPath: AssetConstants.inverterTestIcon,
      action: TestModeMenuAction.inverterTest,
    ),
    TestModeMenuItem(
      title: StringConstants.systemTest,
      iconPath: AssetConstants.systemTestIcon,
      action: TestModeMenuAction.systemTest,
    ),
  ];

  String? get panelName => args.panelName;

  int? get siteId => args.siteId;

  bool get embedded => args.embedded;

  void attachUi(TestModeUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  Future<bool> handleWillPop() async {
    if (embedded) return false;
    return true;
  }

  Future<void> handleBackNavigation() async {
    if (embedded) return;

    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    ui.popScreen();
  }

  void onMenuItemTap(TestModeMenuAction action) {
    switch (action) {
      case TestModeMenuAction.batteryTest:
        openBatteryTest();
      case TestModeMenuAction.solarPanelTest:
        openSolarPanelTest();
      case TestModeMenuAction.inverterTest:
        openInverterTest();
      case TestModeMenuAction.systemTest:
        openSystemTest();
    }
  }

  void openBatteryTest() {
    // Plug in solar commissioning test flow when enabling the Test Mode tab.
  }

  void openSolarPanelTest() {
    // Plug in solar commissioning test flow when enabling the Test Mode tab.
  }

  void openInverterTest() {
    // Plug in solar commissioning test flow when enabling the Test Mode tab.
  }

  void openSystemTest() {
    // Plug in solar commissioning test flow when enabling the Test Mode tab.
  }
}
