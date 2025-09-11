import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ScanningAnimation extends StatefulWidget {
  const ScanningAnimation({super.key});

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipple(double scale, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1st expanding ripple
            _buildRipple(1.0 + value, (1.0 - value).clamp(0.0, 1.0)),
            _buildRipple(0.7 + value, (0.7 - value).clamp(0.0, 1.0)),
            _buildRipple(0.4 + value, (0.4 - value).clamp(0.0, 1.0)),
            _buildRipple(0.1 + value, (0.1 - value).clamp(0.0, 1.0)),
            _buildRipple(0.0 + value, (0.0 - value).clamp(0.0, 1.0)),
            _buildRipple(-0.1 + value, (-0.1 - value).clamp(0.0, 1.0)),
            _buildRipple(-0.4 + value, (-0.4 - value).clamp(0.0, 1.0)),
            _buildRipple(-0.7 + value, (-0.7 - value).clamp(0.0, 1.0)),
            _buildRipple(-1.0 + value, (-1.0 - value).clamp(0.0, 1.0)),

            // Central icon with a fixed red circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: Center(child: SvgPicture.asset('assets/svgs/logo.svg')),
            ),
          ],
        );
      },
    );
  }
}
