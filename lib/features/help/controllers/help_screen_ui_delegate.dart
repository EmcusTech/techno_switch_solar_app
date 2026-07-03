abstract class HelpScreenUiDelegate {
  bool get isMounted;

  Future<void> launchPhone(String phoneNumber);

  Future<void> launchEmail(String email);

  Future<void> launchExternalUrl(String url);
}
