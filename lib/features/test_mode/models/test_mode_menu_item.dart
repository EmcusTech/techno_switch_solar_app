enum TestModeMenuAction {
  batteryTest,
  solarPanelTest,
  inverterTest,
  systemTest,
}

class TestModeMenuItem {
  const TestModeMenuItem({
    required this.title,
    required this.iconPath,
    required this.action,
  });

  final String title;
  final String iconPath;
  final TestModeMenuAction action;
}
