import 'package:flutter/material.dart';

class PanelTypeOption {
  const PanelTypeOption({
    required this.typeName,
    required this.zoneCount,
    required this.sounderCount,
    required this.relayCount,
    required this.fireExtinguisherCount,
  });

  final String typeName;
  final int zoneCount;
  final int sounderCount;
  final int relayCount;
  final int fireExtinguisherCount;
}

class PanelSelectionPageModel {
  const PanelSelectionPageModel({
    required this.panelNameController,
    required this.selectedPanelType,
    required this.panelTypes,
    required this.onPanelTypeChanged,
    this.validationErrors,
  });

  final TextEditingController panelNameController;
  final String? selectedPanelType;
  final List<PanelTypeOption> panelTypes;
  final void Function(String?) onPanelTypeChanged;
  final Map<String, String>? validationErrors;
}
