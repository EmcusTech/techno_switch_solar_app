/// Centralized asset path constants (SVGs, Lottie JSONs, images).
///
/// Use these instead of hard-coding `'assets/...'` string literals so paths
/// live in one place and typos are caught at compile time.
class AssetConstants {
  AssetConstants._();

  // ── Base directories ──────────────────────────────────────────────
  static const String _svgDir = 'assets/svgs';
  static const String _diagnosticsDir = 'assets/svgs/diagnostics';
  static const String _jsonDir = 'assets/jsons';
  static const String _imageDir = 'assets/images';

  // ── SVGs ──────────────────────────────────────────────────────────
  static const String uploadIcon = '$_svgDir/upload_icon.svg';
  static const String dropDownRedIcon = '$_svgDir/drop_down_red_icon.svg';
  static const String background1 = '$_svgDir/background_1.svg';
  static const String background2 = '$_svgDir/background_2.svg';
  static const String background3 = '$_svgDir/background_3.svg';
  static const String splashscreenBackground1 =
      '$_svgDir/splashscreen_background_1.svg';
  static const String splashscreenBackground2 =
      '$_svgDir/splashscreen_background_2.svg';
  static const String logo = '$_svgDir/logo.svg';
  static const String bottomsheetLogo = '$_svgDir/bottomsheet_logo.svg';
  static const String logReportWatermark = '$_svgDir/log_report_watermark.svg';
  static const String panelIcon = '$_svgDir/panel_icon.svg';
  static const String arrowRightColoredIcon =
      '$_svgDir/arrow_right_colored_icon.svg';
  static const String arrowBackIcon = '$_svgDir/arrow_back_icon.svg';
  static const String settingsIcon = '$_svgDir/settings_icon.svg';
  static const String settingIcon = '$_svgDir/setting_icon.svg';
  static const String clearIcon = '$_svgDir/clear_icon.svg';
  static const String shareIcon = '$_svgDir/share_icon.svg';
  static const String shareIconRed = '$_svgDir/share_icon_red.svg';
  static const String filterIcon = '$_svgDir/filter_icon.svg';
  static const String calendarIcon = '$_svgDir/calendar_icon.svg';
  static const String listDeselectedIcon = '$_svgDir/list_deselected_icon.svg';
  static const String tableDeselectedIcon =
      '$_svgDir/table_deselected_icon.svg';
  static const String addCircleIcon = '$_svgDir/add_circle_icon.svg';
  static const String editIcon = '$_svgDir/edit_icon.svg';
  static const String homeIcon = '$_svgDir/home_icon.svg';
  static const String helpIcon = '$_svgDir/help_icon.svg';
  static const String newProjectIcon = '$_svgDir/new_project_icon.svg';
  static const String openProjectIcon = '$_svgDir/open_project_icon.svg';
  static const String maintenanceIcon = '$_svgDir/maintenance_icon.svg';
  static const String retrieveLogIcon = '$_svgDir/retrieve_log_icon.svg';
  static const String checkCircleIcon = '$_svgDir/check_circle_icon.svg';
  static const String panelTypeIcon1 = '$_svgDir/panel_type_icon_1.svg';
  static const String panelTypeIcon2 = '$_svgDir/panel_type_icon_2.svg';
  static const String panelTypeIcon3 = '$_svgDir/panel_type_icon_3.svg';
  static const String panelTypeIcon4 = '$_svgDir/panel_type_icon_4.svg';
  static const String batteryTestIcon = '$_svgDir/battery_test_icon.svg';
  static const String solarPanelTestIcon = '$_svgDir/solar_panel_test_icon.svg';
  static const String inverterTestIcon = '$_svgDir/inverter_test_icon.svg';
  static const String systemTestIcon = '$_svgDir/system_test_icon.svg';
  static const String dashboardIcon = '$_svgDir/dashboard_icon.svg';
  static const String testModeIcon = '$_svgDir/test_mode_icon.svg';
  static const String logHistoryIcon = '$_svgDir/log_history_icon.svg';
  static const String peripheralRelayIcon = '$_svgDir/peripheral_relay_icon.svg';
  static const String peripheralInputIcon = '$_svgDir/peripheral_input_icon.svg';
  static const String peripheralZonesIcon = '$_svgDir/peripheral_zones_icon.svg';
  static const String peripheralSounderIcon =
      '$_svgDir/peripheral_sounder_icon.svg';
  static const String peripheralProgHoldIcon =
      '$_svgDir/peripheral_prog_hold_icon.svg';
  static const String peripheralAuxIcon = '$_svgDir/peripheral_aux_icon.svg';
  static const String peripheralLBusIcon = '$_svgDir/peripheral_l_bus_icon.svg';
  static const String peripheralExtOutIcon =
      '$_svgDir/peripheral_ext_out_icon.svg';
  static const String panelActionEventLogIcon =
      '$_svgDir/panel_action_event_log_icon.svg';
  static const String firmwareIcon = '$_svgDir/firmware_icon.svg';
  static const String panelActionServiceDueIcon =
      '$_svgDir/panel_action_service_due_icon.svg';
  static const String panelActionAccessCodeIcon =
      '$_svgDir/panel_action_access_code_icon.svg';
  static const String panelActionPanelInfoIcon =
      '$_svgDir/panel_action_panel_info_icon.svg';
  static const String panelActionGeneralModuleIcon =
      '$_svgDir/panel_action_general_module_icon.svg';
  static const String diagnosticIcon = '$_svgDir/diagnostic_icon.svg';
  static const String walkTestIcon = '$_svgDir/walk_test_icon.svg';
  static const String panelActionConfigLogIcon =
      '$_svgDir/panel_action_config_log_icon.svg';
  static const String lockIcon = '$_svgDir/lock_icon.svg';
  static const String lockIconWhiteSvg = '$_svgDir/lock_icon_white_svg.svg';
  static const String keypadDeleteIcon = '$_svgDir/keypad_delete_icon.svg';
  static const String keypadClearIcon = '$_svgDir/keypad_clear_icon.svg';
  static const String locationIcon = '$_svgDir/location_icon.svg';
  static const String deleteIcon = '$_svgDir/delete_icon.svg';
  static const String siteCalenderIcon = '$_svgDir/site_calender_icon.svg';
  static const String detailsIcon = '$_svgDir/details_icon.svg';

  // ── Diagnostics SVGs ──────────────────────────────────────────────
  static const String diagnosticsOtherCritical =
      '$_diagnosticsDir/other_crticial_icon.svg';
  static const String diagnosticsNormal =
      '$_diagnosticsDir/diagnostics_normal_icon.svg';
  static const String diagnosticsHigh =
      '$_diagnosticsDir/diagnostics_high_icon.svg';
  static const String diagnosticsCritical =
      '$_diagnosticsDir/diagnostics_critical_icon.svg';
  static const String diagnosticsDropdown =
      '$_diagnosticsDir/diagnostics_dropdown_icon.svg';

  /// Build a diagnostics section icon path from its [prefix] (section) and
  /// [suffix] (band), e.g. `power_high` -> assets/svgs/diagnostics/power_high_icon.svg.
  static String diagnosticSectionIcon(String prefix, String suffix) =>
      '$_diagnosticsDir/${prefix}_${suffix}_icon.svg';

  // ── Lottie JSONs ──────────────────────────────────────────────────
  static const String bleConnectingJson = '$_jsonDir/ble_connecting.json';
  static const String fetchingLogJson = '$_jsonDir/fetching_log.json';
  static const String firmwareUpgradeJson = '$_jsonDir/firmware_upgrade.json';
  static const String firmwareUpgradeSuccessJson =
      '$_jsonDir/firmware_upgrade_success.json';
  static const String firmwareUpgradeFailedJson =
      '$_jsonDir/firmware_upgrade_failed.json';

  // ── Images ────────────────────────────────────────────────────────
  static const String fullLogo = '$_imageDir/full_logo.png';
  static const String panelIconImage = '$_imageDir/panel_icon.png';
}
