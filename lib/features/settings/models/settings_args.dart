class SettingsArgs {
  const SettingsArgs({
    required this.panelName,
    required this.panelVersionNo,
    this.embedded = true,
  });

  final String panelName;
  final String panelVersionNo;
  final bool embedded;
}
