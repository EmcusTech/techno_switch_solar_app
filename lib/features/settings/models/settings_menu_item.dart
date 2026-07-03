enum SettingsMenuAction {
  panelSettings,
  zoneSettings,
  inputSettings,
  relaySettings,
  sounderSettings,
  extinguishingOutSettings,
  lBusSettings,
  panelInformation,
  firmwareUpgrade,
}

class SettingsMenuItem {
  const SettingsMenuItem({
    required this.title,
    required this.action,
  });

  final String title;
  final SettingsMenuAction action;
}
