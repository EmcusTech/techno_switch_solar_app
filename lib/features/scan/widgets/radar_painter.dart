import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  RadarPainter({required this.sweepAnimation}) : super(repaint: sweepAnimation);

  final Animation<double> sweepAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    const int rings = 4;
    for (int i = 1; i <= rings; i++) {
      paint.color = Colors.green.withOpacity(0.12 + i * 0.03);
      canvas.drawCircle(center, (size.width / 2) * (i / (rings + 1)), paint);
    }

    final centerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(center, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) => true;
}
