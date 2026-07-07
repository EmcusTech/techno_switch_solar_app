class AdcInputModel {
  final int index;
  final double value;
  final int fraction;
  final int unit;
  final int count;
  final int valueType;

  const AdcInputModel({
    required this.index,
    required this.value,
    required this.fraction,
    required this.unit,
    required this.count,
    required this.valueType,
  });
}
