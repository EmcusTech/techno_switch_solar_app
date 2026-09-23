import 'package:techno_switch_solar_app/utils/constants/strings/panel_values.dart';

/// Dropdown option catalogs for Zone configuration (index = wire value).
abstract final class ZoneConfigOptions {
  static const List<String> typeOptions = PanelValues.zoneTypeOptions;

  static const List<String> yesNoOptions = [
    PanelValues.noOption,
    PanelValues.yesOption,
  ];

  static const List<String> modeOptions = PanelValues.zoneModeOptions;

  static int clampIndex(int index, List<String> options) {
    if (options.isEmpty) return 0;
    return index.clamp(0, options.length - 1);
  }

  static String labelFor(List<String> options, int index) {
    return options[clampIndex(index, options)];
  }

  static int indexFor(List<String> options, String label) {
    final index = options.indexOf(label);
    return index < 0 ? 0 : index;
  }

  static String typeLabel(int value) => labelFor(typeOptions, value);

  static int typeIndex(String label) => indexFor(typeOptions, label);

  static String yesNoLabel(bool value) =>
      value ? PanelValues.yesOption : PanelValues.noOption;

  static bool yesNoValue(String label) => label == PanelValues.yesOption;

  static String modeLabel(int value) => labelFor(modeOptions, value);

  static int modeIndex(String label) => indexFor(modeOptions, label);
}
