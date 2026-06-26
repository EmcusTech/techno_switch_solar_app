import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class CustomVerticalTickMarkShape extends SliderTickMarkShape {
  const CustomVerticalTickMarkShape();

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return const Size(1, 9);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    final Paint paint = Paint()
      ..color = sliderTheme.inactiveTickMarkColor ?? ColorConstants.textMuted
      ..strokeWidth = 1.0;

    // Draw vertical line (9px height)
    context.canvas.drawLine(
      Offset(center.dx, center.dy - 4.5),
      Offset(center.dx, center.dy + 4.5),
      paint,
    );
  }
}