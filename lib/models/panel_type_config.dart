import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class PanelTypeConfig {
  final String typeName;
  final int zoneCount;
  final int sounderCount;
  final int relayCount;
  final int fireExtinguisherCount;

  const PanelTypeConfig({
    required this.typeName,
    required this.zoneCount,
    required this.sounderCount,
    required this.relayCount,
    required this.fireExtinguisherCount,
  });

  static const List<PanelTypeConfig> availablePanels = [
    // PanelTypeConfig(
    //   typeName: StringConstants.oryx202,
    //   zoneCount: 2,
    //   sounderCount: 2,
    //   relayCount: 2,
    //   fireExtinguisherCount: 0,
    // ),
    // PanelTypeConfig(
    //   typeName: StringConstants.oryx204,
    //   zoneCount: 4,
    //   sounderCount: 2,
    //   relayCount: 4,
    //   fireExtinguisherCount: 0,
    // ),
    // PanelTypeConfig(
    //   typeName: StringConstants.oryx208,
    //   zoneCount: 8,
    //   sounderCount: 2,
    //   relayCount: 8,
    //   fireExtinguisherCount: 0,
    // ),
    PanelTypeConfig(
      typeName: StringConstants.rhino103,
      zoneCount: 3,
      sounderCount: 3,
      relayCount: 3,
      fireExtinguisherCount: 1,
    ),
    // PanelTypeConfig(
    //   typeName: StringConstants.rhino203,
    //   zoneCount: 3,
    //   sounderCount: 3,
    //   relayCount: 6,
    //   fireExtinguisherCount: 1,
    // ),

    //when uncommenting, update the create project controller
    //   CreateProjectController() {
    //   _initializeControllerListeners();
    //   if (PanelTypeConfig.availablePanels.length == 1) {
    //     updatePanelType(PanelTypeConfig.availablePanels.first.typeName);
    //   }
    // }
  ];

  static PanelTypeConfig? getByTypeName(String typeName) {
    try {
      return availablePanels.firstWhere((panel) => panel.typeName == typeName);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'PanelTypeConfig(typeName: $typeName, zones: $zoneCount, sounders: $sounderCount, relays: $relayCount, fireExt: $fireExtinguisherCount)';
  }
}
