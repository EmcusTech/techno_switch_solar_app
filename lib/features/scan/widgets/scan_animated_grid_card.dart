import 'package:flutter/material.dart';

class ScanAnimatedGridCard extends StatefulWidget {
  const ScanAnimatedGridCard({
    super.key,
    required this.child,
    required this.highlight,
  });

  final Widget child;
  final bool highlight;

  @override
  State<ScanAnimatedGridCard> createState() => _ScanAnimatedGridCardState();
}

class _ScanAnimatedGridCardState extends State<ScanAnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [
            widget.child,
            if (widget.highlight) const _ScanPulseGlow(),
          ],
        ),
      ),
    );
  }
}

class _ScanPulseGlow extends StatefulWidget {
  const _ScanPulseGlow();

  @override
  State<_ScanPulseGlow> createState() => _ScanPulseGlowState();
}

class _ScanPulseGlowState extends State<_ScanPulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.25 * (1 - _controller.value),
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
