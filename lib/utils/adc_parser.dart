import 'dart:typed_data';

import 'package:techno_switch_solar_app/models/adc_input_model.dart';

class AdcParser {
  static const int commandIndex = 12;
  static const int command = 0x09;

  static List<AdcInputModel> parse(List<int> bytes) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));

    if (bytes.length < 20) {
      throw Exception("Invalid payload");
    }

    if (bytes[commandIndex] != command) {
      throw Exception("Invalid ADC response");
    }

    final start = commandIndex - 6;

    final adcInputs = bytes[start + 7];
    final valueType = bytes[start + 9];

    final baseOffset = start + 10;

    List<AdcInputModel> results = [];

    for (int i = 0; i < adcInputs; i++) {
      final offset = baseOffset + (i * 8);

      if (offset + 8 > bytes.length) break;

      final raw = data.getUint32(offset, Endian.big);
      final value = raw / 1000000.0;

      final fraction = data.getUint8(offset + 4);
      final unit = data.getUint8(offset + 5);
      final count = data.getUint16(offset + 6, Endian.big);

      results.add(
        AdcInputModel(
          index: i,
          value: value,
          fraction: fraction,
          unit: unit,
          count: count,
          valueType: valueType,
        ),
      );
    }

    return results;
  }
}
