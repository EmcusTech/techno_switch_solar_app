import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class InputData {
  String inputText;
  String inverted;
  String test;
  String input1;
  String group;
  String function;

  InputData({
    this.inputText = 'Input 1',
    this.inverted = StringConstants.no,
    this.test = StringConstants.no,
    this.input1 = StringConstants.enable,
    this.group = StringConstants.groupA,
    this.function = 'Function 1A',
  });

  void updateField(String label, String value) {
    switch (label) {
      case StringConstants.inputText:
        inputText = value;
        break;
      case StringConstants.inverted:
        inverted = value;
        break;
      case StringConstants.test:
        test = value;
        break;
      case 'Input 1':
        input1 = value;
        break;
      case 'Group':
        group = value;
        break;
      case StringConstants.function:
        function = value;
        break;
    }
  }
}
