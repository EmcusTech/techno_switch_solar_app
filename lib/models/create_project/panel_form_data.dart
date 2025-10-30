class PanelFormData {
  String panelName;
  String? selectedPanelType;

  PanelFormData({this.panelName = '', this.selectedPanelType});

  PanelFormData copyWith({String? panelName, String? selectedPanelType}) {
    return PanelFormData(
      panelName: panelName ?? this.panelName,
      selectedPanelType: selectedPanelType ?? this.selectedPanelType,
    );
  }
}
