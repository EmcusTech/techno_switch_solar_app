import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

enum DiagnosticVoltageBand { critical, nominal, high }

DiagnosticVoltageBand diagnosticVoltageBandFor(double volts) {
  final a = volts.abs();
  if (a < 0.6) return DiagnosticVoltageBand.critical;
  if (a > 42 || volts < -1) return DiagnosticVoltageBand.high;
  return DiagnosticVoltageBand.nominal;
}

class DiagnosticVoltageTile extends StatelessWidget {
  const DiagnosticVoltageTile({
    super.key,
    required this.label,
    required this.notifier,
    required this.isLive,
    this.unit = 'V',
    this.decimals = 2,
  });

  final String label;
  final ValueNotifier<double> notifier;
  final ValueListenable<bool> isLive;
  final String unit;
  final int decimals;

  static const Color _textMuted = ColorConstants.textMuted;
  static const Color _border = ColorConstants.borderMuted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLive,
      builder: (_, live, __) {
        return ValueListenableBuilder<double>(
          valueListenable: notifier,
          builder: (_, value, __) {
            final band = diagnosticVoltageBandFor(value);
            final accent = _accentFor(band);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 5, color: accent),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _textMuted,
                                height: 1.2,
                              ),
                            ),
                            Spacer(),
                            statusBadgeIcon(band, isLive: live),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value.toStringAsFixed(decimals),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _valueColor(band),
                                height: 1.1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              unit,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _textMuted,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        statusBadge(band),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget statusBar({required DiagnosticVoltageBand band}) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorConstants.progressTrack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor:
              band == DiagnosticVoltageBand.nominal
                  ? 0.3
                  : band == DiagnosticVoltageBand.high
                  ? 0.7
                  : 1.0,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: _accentFor(band),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget statusBadgeIcon(DiagnosticVoltageBand band, {required bool isLive}) {
    return _DiagnosticStatusDot(color: _valueColor(band), isLive: isLive);
  }

  Widget statusBadge(DiagnosticVoltageBand band) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _valueBackgroundColor(band),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _valueColor(band)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Center(
          child: Text(
            _valueStatus(band),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _valueColor(band),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return ColorConstants.teal;
    }
    if (band == DiagnosticVoltageBand.high) {
      return ColorConstants.warningAmber;
    }
    return ColorConstants.errorPink;
  }

  Color _valueColor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return ColorConstants.teal;
    }
    if (band == DiagnosticVoltageBand.high) {
      return ColorConstants.warningAmber;
    }
    return ColorConstants.errorPink;
  }

  Color _valueBackgroundColor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return ColorConstants.colorFfdefffa;
    }
    if (band == DiagnosticVoltageBand.high) {
      return ColorConstants.colorFffff6Eb;
    }
    return ColorConstants.colorFffff3F4;
  }

  String _valueStatus(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return StringConstants.ok2;
    }
    if (band == DiagnosticVoltageBand.high) {
      return StringConstants.high;
    }
    return StringConstants.critical;
  }
}

class _DiagnosticStatusDot extends StatefulWidget {
  const _DiagnosticStatusDot({required this.color, required this.isLive});

  final Color color;
  final bool isLive;

  @override
  State<_DiagnosticStatusDot> createState() => _DiagnosticStatusDotState();
}

class _DiagnosticStatusDotState extends State<_DiagnosticStatusDot>
    with SingleTickerProviderStateMixin {
  static const double _size = 10;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_DiagnosticStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !oldWidget.isLive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLive && oldWidget.isLive) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(_size / 2),
      ),
    );

    if (!widget.isLive) return dot;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 1.0 + 0.25 * t;
        final opacity = 0.55 + 0.45 * t;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: dot),
        );
      },
    );
  }
}
