class CommandDataModel {
  final HeaderModel headerDataModel;
  final CommandModel commandDataModel;

  CommandDataModel({
    required this.headerDataModel,
    required this.commandDataModel,
  });
}

class HeaderModel {
  final int dummy;

  HeaderModel({required this.dummy});
}

class CommandModel {
  final int dummy;

  CommandModel({required this.dummy});
}
