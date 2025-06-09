import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Paints a 45° black & yellow hazard stripe pattern,
/// clipped to a rounded rectangle.
class HazardStripePainter extends CustomPainter {
  final double borderRadius;

  HazardStripePainter({this.borderRadius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint blackPaint = Paint()..color = Colors.black;
    final Paint yellowPaint = Paint()..color = Color(0xFFFDD835);

    // 1) Clip to RRect for rounded corners
    final RRect clipRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    canvas.clipRRect(clipRRect);

    // 2) Fill background with black
    canvas.drawRRect(clipRRect, blackPaint);

    // 3) Compute stripe geometry
    final double diagonal = size.width + size.height;
    final double stripeWidth = size.height * math.sqrt2;      // width along rotated x
    final double stripeInterval = stripeWidth * 2;            // gap + stripe

    // 4) Rotate canvas so vertical rects become 45° stripes
    canvas.save();
    canvas.rotate(-math.pi / 4);

    // 5) Draw yellow stripes at every other interval
    for (double x = -diagonal; x < diagonal * 2; x += stripeInterval) {
      canvas.drawRect(
        Rect.fromLTWH(x, -diagonal, stripeWidth, diagonal * 3),
        yellowPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HazardStripePainter old) => false;
}
