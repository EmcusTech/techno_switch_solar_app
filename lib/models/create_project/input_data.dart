class InputData {
  String inputText;
  String inverted;
  String test;
  String input1;
  String group;
  String function;

  InputData({
    this.inputText = 'Input 1',
    this.inverted = 'No',
    this.test = 'No',
    this.input1 = 'Enable',
    this.group = 'Group A',
    this.function = 'Function 1A',
  });

  void updateField(String label, String value) {
    switch (label) {
      case 'Input Text':
        inputText = value;
        break;
      case 'Inverted':
        inverted = value;
        break;
      case 'Test':
        test = value;
        break;
      case 'Input 1':
        input1 = value;
        break;
      case 'Group':
        group = value;
        break;
      case 'Function':
        function = value;
        break;
    }
  }
}
