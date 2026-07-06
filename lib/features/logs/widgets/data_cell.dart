import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DataCells extends StatelessWidget {
  final double width;
  final String text;
  final DataType dataType;
  const DataCells({
    super.key,
    required this.width,
    required this.text,
    required this.dataType,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle();
    if (dataType == DataType.id) {
      textStyle = StyleConstants.textSecondary13boldStyle;
    } else if (dataType == DataType.dateTime) {
      textStyle = StyleConstants.textSecondary12w400Style;
    } else {
      textStyle = StyleConstants.textSecondary13w400Style;
    }
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
