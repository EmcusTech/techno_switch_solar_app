/// User-facing copy: titles, messages, buttons, labels, hints, and errors.
abstract final class UiStrings {
  // --- Shared actions ---
  static const String cancelButton = 'Cancel';
  static const String closeButton = 'Close';
  static const String continueButton = 'Continue';
  static const String nextButton = 'Next';
  static const String createButton = 'Create';
  static const String applyButton = 'Apply';
  static const String deleteButton = 'Delete';
  static const String removeButton = 'Remove';
  static const String replaceButton = 'Replace';
  static const String yesButton = 'Yes';
  static const String noButton = 'No';
  static const String updateButton = 'Update';
  static const String okayButton = 'Okay';
  static const String backButton = 'Back';
  static const String connectButton = 'Connect';
  static const String disconnectButton = 'Disconnect';
  static const String exportButton = 'Export';
  static const String verifyButton = 'Verify';
  static const String doneButton = 'Done';
  static const String downloadConfigNowButton = 'Yes';

  // --- Create site / project dialogs ---
  static const String createSiteDialogTitle = 'Create site';
  static const String createSiteConfirmMessage =
      'This will save the site and panel ID. Configuration will be stored '
      'locally and can be applied when you connect the panel later.';

  static const String applyPanelSettingsDialogTitle = 'Update panel settings';
  static const String applyPanelSettingsConfirmMessage =
      'This will update the panel settings with the values you configured '
      'in this setup.';

  static const String movePanelToSiteMessage =
      'This panel is assigned to another site. Move it to the new site you '
      'are creating, or skip and return home.';

  static const String downloadConfigNowMessage =
      'Download the full configuration from the panel now? This matches the '
      'dashboard “download all” flow and fills local caches before you edit.';

  // --- Site / panel ---
  static const String deleteSiteDialogTitle = 'Delete site?';
  static const String deleteSiteWarningMessage =
      'All logs will be deleted and panels will be unassigned.';
  static const String removePanelDialogTitle = 'Remove panel?';
  static const String unableToDeleteSiteError = 'Unable to delete site';
  static const String unableToDeletePanelError = 'Unable to delete panel';
  static const String siteInformationTitle = 'Site Information';
  static const String viewSiteDetailsButton = 'View Site Details';
  static const String noLogsYetLabel = 'No logs yet';
  static const String noPanelsYetTitle = 'No Panels Yet';
  static const String connectPanelToSiteHint =
      'Connect to a panel to associate it with this site';
  static const String createdLabel = 'Created';
  static const String panelsTitle = 'Panels';

  static String deleteSiteConfirmMessage(String siteName) =>
      'This will remove "$siteName".\n$deleteSiteWarningMessage';

  static String siteDeletedSnackBar(String siteName) =>
      'Site "$siteName" deleted';

  static String panelDeletedSnackBar(String panelName) =>
      'Panel "$panelName" deleted';

  static String siteCreatedWithLogsSaved(int logCount) =>
      'Site created successfully! $logCount logs saved.';

  static String errorDeletingSiteSnackBar(Object error) =>
      'Error deleting site: $error';

  static String errorDeletingPanelSnackBar(Object error) =>
      'Error deleting panel: $error';

  static String removePanelConfirmMessage(String panelName, String panelId) =>
      'Remove panel "$panelName" ($panelId) from this site?';

  // --- Firmware upgrade ---
  static const String firmwareUpgradeTitle = 'Firmware Upgrade';
  static const String firmwareUpdateTitle = 'Firmware Update';
  static const String essentialStepsBeforeFirmwareUpgradeTitle =
      'Essential Steps Before Firmware Upgrade';
  static const String chooseFirmwareTypeTitle = 'Choose Firmware Type';
  static const String mainPanelFirmwareLabel = 'Main Panel Firmware';
  static const String bleChipFirmwareLabel = 'BLE Chip Firmware';
  static const String upgradeMainPanelFirmwareDescription =
      'Upgrade the main panel firmware';
  static const String upgradeBleChipFirmwareDescription =
      'Upgrade the Bluetooth chip firmware';
  static const String uploadFirmwareFileTitle = 'Upload Firmware File';
  static const String tapToSelectFirmwareFileHint =
      'Tap to select firmware file';
  static const String fileDetailsTitle = 'File Details';
  static const String fileNameLabel = 'File Name';
  static const String fileSizeLabel = 'File Size';
  static const String firmwareTypeLabel = 'Firmware Type';
  static const String buildDateLabel = 'Build date';
  static const String expectedCrcLabel = 'Expected CRC';
  static const String calculatedCrcLabel = 'Calculated CRC';
  static const String statusLabel = 'Status';
  static const String validLabel = 'Valid';
  static const String invalidLabel = 'Invalid';
  static const String fileCrcValidationFailedMessage =
      'File CRC validation failed. Please select a valid firmware file.';
  static const String pleaseWaitWhileFirmwareUpgradedMessage =
      'Please wait while the firmware is being upgraded. Do not disconnect the device.';
  static const String processingMessage = 'Processing...';
  static const String failedTitle = 'Failed';
  static const String firmwareUpgradeSuccessTitle = 'Success!';
  static const String validatingFirmwareUpgradeSuccessMessage =
      'Validating firmware upgrade success...';
  static const String firmwareUpgradeCompletedSuccessfullyMessage =
      'Firmware upgrade completed successfully!';
  static const String invalidBinHardwareMismatchMessage =
      "Invalid bin file, hardware versions don't match";
  static const String firmwareAlreadyUpToDateMessage =
      'The firmware is already up to date with the current firmware version';
  static const String deviceHardwareFirmwareCouldNotBeReadMessage =
      'Device hardware and firmware versions could not be read from '
      'Bluetooth. Do you still want to update?';
  static const String crcValidationFailedMessage = 'CRC validation failed.';
  static const String noFileSelectedPleaseUploadAgainMessage =
      'No file selected. Please upload again.';
  static const String unableToDetermineUpgradeStatusError =
      'Unable to determine upgrade status';
  static const String binFileHardwareVersionLabel =
      'Bin File Hardware Version: ';
  static const String bleHardwareVersionLabel = 'BLE Hardware Version: ';

  static const String failedToReconnectToDeviceErrorPrefix =
      'Failed to reconnect to device: ';
  static const String reconnectionErrorPrefix = 'Reconnection error: ';
  static const String errorSelectingFilePrefix = 'Error selecting file: ';
  static const String errorSendingPacketsPrefix = 'Error sending packets: ';

  static String binFileHardwareVersionDetail(
    String? binHardware,
    String bleHardware,
  ) =>
      '$binFileHardwareVersionLabel$binHardware\n'
      '$bleHardwareVersionLabel$bleHardware';

  // --- Bootloader ---
  static const String deviceInBootloaderModeTitle =
      'Device is in bootloader mode';
  static const String deviceNotFoundAfterFirmwareUpgradeMessage =
      'Device not found after firmware upgrade. Please scan and connect again.';
  static const String deviceNotFoundAfterFirmwareUpgradeReconnectMessage =
      'Device not found after firmware upgrade. Please reconnect.';
  static const String bootloaderFileCorruptedDoYouWantToUpdateMessage =
      'The bootloader file on the device is corrupted. '
      'Do you want to update the firmware?';
  static const String tapOnUpdateToUpdateFirmwareMessage =
      'Tap on Update to update the firmware.';
  static const String firmwareUpgradeModeCannotUseNormallyPrefix =
      'This device is in firmware upgrade mode and cannot be used normally. ';
  static const String doYouWantToUpdateFirmwareMessage =
      'Do you want to update the firmware?';
  static const String bootloaderFileCorruptedTapToUpdateMessage =
      'The bootloader file on the device is corrupted. '
      'Tap on Update to update the firmware.';

  // --- BLE connecting ---
  static const String deviceConnectedTitle = 'Device Connected!';
  static const String pleaseWaitWhileWeConnectToPrefix =
      'Please wait while we connect to ';
  static const String deviceRestartingSearchingForPanelMessage =
      'Device is restarting. Searching for panel and establishing connection...';

  // --- Scanning ---
  static const String usbSerialDevicesTitle = 'USB/Serial Devices';
  static const String bluetoothBleDevicesTitle = 'Bluetooth (BLE) Devices';
  static const String failedToConnectErrorPrefix = 'Failed to connect: ';
  static const String couldNotCreatePdfErrorPrefix = 'Could not create PDF: ';
  static const String failedToLoadLogsErrorPrefix = 'Failed to load logs: ';

  // --- Config log ---
  static const String configLogTitle = 'Config Log';
  static const String applyToPanelDialogTitle = 'Apply to panel?';
  static const String applyToPanelConfirmMessage =
      'This will overwrite panel settings with the configuration '
      'saved in this app for this device.';
  static const String compareWithSavedSetupTitle = 'Compare with saved setup';
  static const String compareWithSavedSetupMessage =
      'Download the full configuration from the panel and compare it with '
      'data stored in this app for this device.';
  static const String resultTitle = 'Result';
  static const String comparingLabel = 'Comparing…';
  static const String listLengthDiffersLabel = 'List length differs';
  static const String onlyOnPanelLabel = 'Only on panel';
  static const String onlyInAppLabel = 'Only in app';
  static const String panelDataDiffersFromAppCacheMessage =
      'Panel data differs from app cache.';
  static const String commsFaultDuringDownloadMessage =
      'Comms fault during download (no field differences vs app)';
  static const String noFieldLevelDetailAvailableMessage =
      'No field-level detail available.';
  static const String selectAnotherLBusToViewDifferencesMessage =
      'Select another L-Bus to view its differences.';
  static const String sectionsThatDifferTitle = 'Sections that differ';
  static const String swipeOrTapTabToReviewDifferencesMessage =
      'Swipe or tap a tab to review panel vs app differences.';
  static const String allConfigurationSectionsMatchMessage =
      'All configuration sections match the saved app data.';
  static const String configurationDiffersNoSectionDetailMessage =
      'Configuration differs from saved app data, but no section detail is available.';
  static const String noConfigurationSavedInAppMessage =
      'No configuration is saved in the app for this device. '
      'Panel data was downloaded successfully. Update the app to '
      'save it locally — there is nothing in the app to send to '
      'the panel.';
  static const String enabledBusDetailMayBeIncompleteMessage =
      'Enabled-bus detail may be incomplete. Use per-bus download on the '
      'L-Bus screen if needed.';
  static const String lBusCommsFaultOnBusesPrefix =
      'L-Bus comms fault on bus(es): ';
  static const String selectLBusLabel = 'Select L-Bus';
  static const String entriesSuffix = ' entries';
  static const String commsFaultOnSomeBusesPrefix =
      'Comms fault on some buses; ';
  static const String changesOnLBusPrefix = ' change(s) on L-Bus ';
  static const String noDifferencesOnLBusPrefix = 'No differences on L-Bus ';
  static const String changesVsSavedAppDataSuffix =
      ' change(s) vs saved app data';
  static const String panelSideLabel = 'Panel';
  static const String appSideLabel = 'App';

  static const String panelIdAlreadyLinkedMessage =
      'This panel ID is already linked to a site. Use a different ID or '
      'connect to the panel instead.';

  static const String panelNotAssociatedCreateSiteMessage =
      'This panel is not associated with any site yet. Create a site to continue.';

  static const String wouldYouLikeToCreateSiteToSaveLogsMessage =
      'Would you like to create a site to save these logs? ';

  static const String stopLogRetrievalDialogTitle = 'Stop Log Retrieval';
  static const String stopLogRetrievalConfirmMessage =
      'Are you sure you want to stop the log retrieval process? '
      'This action cannot be undone.';

  static const String uploadConfigurationToPanelConfirmMessage =
      'Are you sure you want to upload this configuration to the panel?';

  static const String configurationUploadedToPanelMessage =
      'Configuration has been successfully uploaded to the panel.';

  static const String unableToConnectToPanelMessage =
      'Unable to connect to the panel. Please check your connection and try again.';

  static const String connectionLostUseConnectMessage =
      'The connection to the device was lost. Any open panels were closed. '
      'Use Connect when you are ready to reconnect.';

  // --- FAQ ---
  static const String faqHowDoICreateNewProjectQuestion =
      'How do I create a new project?';
  static const String faqHowCanIRetrieveProjectLogsQuestion =
      'How can I retrieve project logs?';
  static const String faqWhatMaintenanceTasksAvailableQuestion =
      'What maintenance tasks are available?';

  static const String faqHowDoICreateNewProjectAnswer =
      'To create a new project, tap on the "New Project" quick link on the '
      'home screen. Follow the step-by-step wizard to set up your project details.';

  static const String faqHowCanIRetrieveProjectLogsAnswer =
      'You can retrieve project logs by tapping the "Retrieve Log" quick link '
      'on the home screen. Select your project and choose the date range for '
      'the logs you need.';

  static const String faqWhatMaintenanceTasksAvailableAnswer =
      'The maintenance section provides various tools for system maintenance, '
      'including system checks, updates, and troubleshooting guides.';

  // --- Misc labels ---
  static const String panelIdLabel = 'Panel ID';
  static const String enterPanelIdDialogTitle = 'Enter panel ID';
  static const String logRetrievalsEmptyHintMessage =
      'Log retrievals will appear here when you retrieve logs for this site.';
  static const String bluetoothPairingModeHintMessage =
      'Make sure Bluetooth is enabled and solar devices are in pairing mode.';
  static const String panelInfoTitle = 'Panel Info';
  static const String siteNameLabel = 'Site Name';
  static const String enterSiteNameHint = 'Enter Site Name';
  static const String enterInstallerNameHint = 'Enter Installer Name';
  static const String enterCompanyNameHint = 'Enter Company Name';
  static const String enterSaqccRegistrationNumberHint =
      'Enter SAQCC Registration Number';
  static const String enterBuildingNameHint = 'Enter Building Name';
  static const String enterInstallerContactNumberHint =
      'Enter Installer Contact Number';
  static const String enterInstallerEmailHint = 'Enter Installer Email';
  static const String enterSiteDescriptionHint = 'Enter Site Description';
  static const String moduleNoLabel = 'Module No';
  static const String lBusDateLabel = 'Date';
  static const String noLogEntriesAvailableMessage = 'No log entries available';
}
