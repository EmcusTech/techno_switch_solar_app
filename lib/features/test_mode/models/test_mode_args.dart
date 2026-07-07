class TestModeArgs {
  const TestModeArgs({
    this.panelName,
    this.siteId,
    this.embedded = true,
  });

  final String? panelName;
  final int? siteId;
  final bool embedded;
}
