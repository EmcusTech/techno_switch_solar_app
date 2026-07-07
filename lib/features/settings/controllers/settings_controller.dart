import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/settings/models/settings_args.dart';
import 'package:techno_switch_solar_app/features/settings/models/settings_menu_item.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SettingsController extends GetxController {
  SettingsController({required this.args});

  final SettingsArgs args;

  SettingsUiDelegate? _ui;

  late final BleLogController bleController;
  late final BleManager bleManager;

  static const List<SettingsMenuItem> menuItems = [
    SettingsMenuItem(
      title: StringConstants.panelSettings,
      action: SettingsMenuAction.panelSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.zoneSettings,
      action: SettingsMenuAction.zoneSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.inputSettings,
      action: SettingsMenuAction.inputSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.relaySettings,
      action: SettingsMenuAction.relaySettings,
    ),
    SettingsMenuItem(
      title: StringConstants.sounderSettings,
      action: SettingsMenuAction.sounderSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.extinguishingOutSettings,
      action: SettingsMenuAction.extinguishingOutSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.lBusSettings,
      action: SettingsMenuAction.lBusSettings,
    ),
    SettingsMenuItem(
      title: StringConstants.panelInformation,
      action: SettingsMenuAction.panelInformation,
    ),
    SettingsMenuItem(
      title: StringConstants.firmwareUpgrade,
      action: SettingsMenuAction.firmwareUpgrade,
    ),
  ];

  String get panelName => args.panelName;

  String get panelVersionNo => args.panelVersionNo;

  bool get embedded => args.embedded;

  String get displayPrefix =>
      BleNameUtils.getDisplayPrefixFromBleName(args.panelName);

  String get displayId => BleNameUtils.getDisplayIdFromBleName(args.panelName);

  void attachUi(SettingsUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  @override
  void onInit() {
    super.onInit();
    bleController = Get.find<BleLogController>();
    bleManager = bleController.bleManager;
  }

  Future<bool> confirmAndDisconnect() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return false;

    final shouldDisconnect = await ui.showDisconnectConfirmDialog();
    if (shouldDisconnect == true) {
      if (bleManager.isConnected) {
        await bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  Future<bool> handleWillPop() async {
    if (embedded) return false;
    if (bleController.isConnected) {
      return confirmAndDisconnect();
    }
    return true;
  }

  Future<void> handleBackNavigation() async {
    if (embedded) return;

    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    if (bleController.isConnected) {
      final shouldPop = await confirmAndDisconnect();
      if (shouldPop && ui.isMounted) {
        ui.popScreen();
      }
    } else {
      ui.popScreen();
    }
  }

  void onMenuItemTap(SettingsMenuAction action) {
    switch (action) {
      case SettingsMenuAction.panelSettings:
        openPanelSettings();
      case SettingsMenuAction.zoneSettings:
        openZoneSettings();
      case SettingsMenuAction.inputSettings:
        openInputSettings();
      case SettingsMenuAction.relaySettings:
        openRelaySettings();
      case SettingsMenuAction.sounderSettings:
        openSounderSettings();
      case SettingsMenuAction.extinguishingOutSettings:
        openExtinguishingOutSettings();
      case SettingsMenuAction.lBusSettings:
        openLBusSettings();
      case SettingsMenuAction.panelInformation:
        openPanelInformation();
      case SettingsMenuAction.firmwareUpgrade:
        openFirmwareUpgrade();
    }
  }

  void openPanelSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openZoneSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openInputSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openRelaySettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openSounderSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openExtinguishingOutSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openLBusSettings() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openPanelInformation() {
    // Plug in navigation when enabling the Settings tab.
  }

  void openFirmwareUpgrade() {
    // Plug in navigation when enabling the Settings tab.
  }
}
