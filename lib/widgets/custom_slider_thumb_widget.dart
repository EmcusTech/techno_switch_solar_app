import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class CustomSliderThumbShape extends SliderComponentShape {
  const CustomSliderThumbShape({this.enabledThumbRadius = 15.0});

  final double enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius + 2); // +2 for border and shadow
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = ColorConstants.overlayBlack25 // #00000040
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 4), // 4px vertical offset
      enabledThumbRadius,
      shadowPaint,
    );

    // Draw main thumb
    final thumbPaint = Paint()
      ..color = sliderTheme.thumbColor ?? ColorConstants.linkBlue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = ColorConstants.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, enabledThumbRadius, borderPaint);
  }
}