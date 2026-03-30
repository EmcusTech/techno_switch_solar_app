import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/models/adc_input_model.dart';

class AdcValues {
  final double sounder1;
  final double sounder2;
  final double sounder3;
  final double discharge;
  final double vaux;
  final double vin;
  final double progInput;
  final double holdInput;
  final double zone1;
  final double zone2;
  final double zone3;
  final double earth;

  const AdcValues({
    required this.sounder1,
    required this.sounder2,
    required this.sounder3,
    required this.discharge,
    required this.vaux,
    required this.vin,
    required this.progInput,
    required this.holdInput,
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.earth,
  });

  factory AdcValues.fromList(List<AdcInputModel> data) {
    if (data.length < 12) {
      throw Exception("Not enough ADC values");
    }

    return AdcValues(
      sounder1: data[0].value,
      sounder2: data[1].value,
      sounder3: data[2].value,
      discharge: data[3].value,
      vaux: data[4].value,
      vin: data[5].value,
      progInput: data[6].value,
      holdInput: data[7].value,
      zone1: data[8].value,
      zone2: data[9].value,
      zone3: data[10].value,
      earth: data[11].value,
    );
  }
}
