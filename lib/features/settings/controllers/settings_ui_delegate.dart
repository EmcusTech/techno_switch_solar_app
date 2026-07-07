abstract class SettingsUiDelegate {
  bool get isMounted;

  Future<bool?> showDisconnectConfirmDialog();

  void popScreen();
}
