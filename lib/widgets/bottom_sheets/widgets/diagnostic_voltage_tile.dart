import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft classification for ADC-derived voltages (generic thresholds).
enum DiagnosticVoltageBand { critical, nominal, high }

DiagnosticVoltageBand diagnosticVoltageBandFor(double volts) {
  final a = volts.abs();
  if (a < 0.6) return DiagnosticVoltageBand.critical;
  if (a > 42 || volts < -1) return DiagnosticVoltageBand.high;
  return DiagnosticVoltageBand.nominal;
}

/// Compact read-only tile: label, numeric value, and unit.
class DiagnosticVoltageTile extends StatelessWidget {
  const DiagnosticVoltageTile({
    super.key,
    required this.label,
    required this.notifier,
    this.unit = 'V',
    this.decimals = 2,
  });

  final String label;
  final ValueNotifier<double> notifier;
  final String unit;
  final int decimals;

  static const Color _textPrimary = Color(0xFF3D3D3D);
  static const Color _textMuted = Color(0xFF918F8F);
  static const Color _border = Color(0xFFDCDCDC);
  static const Color _surfaceMuted = Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (_, value, __) {
        final band = diagnosticVoltageBandFor(value);
        final accent = _accentFor(band);

        return Container(
          decoration: BoxDecoration(
            // color: _surfaceMuted,
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
                        statusBadgeIcon(band),
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
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                    // statusBar(band: band, progress: 0.5),
                    statusBadge(band),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget statusBar({required DiagnosticVoltageBand band}) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
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

  Widget statusBadgeIcon(DiagnosticVoltageBand band) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _valueColor(band),
        borderRadius: BorderRadius.circular(5),
      ),
    );
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
      return const Color(0xFF2B8073);
    }
    if (band == DiagnosticVoltageBand.high) {
      return const Color(0xFFEDA145);
    }
    return const Color(0xFFE4626F);
  }

  Color _valueColor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return const Color(0xFF2B8073);
    }
    if (band == DiagnosticVoltageBand.high) {
      return const Color(0xFFEDA145);
    }
    return const Color(0xFFE4626F);
  }

  Color _valueBackgroundColor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return const Color(0xFFDEFFFA);
    }
    if (band == DiagnosticVoltageBand.high) {
      return const Color(0xFFFFF6EB);
    }
    return const Color(0xFFFFF3F4);
  }

  String _valueStatus(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return "Ok";
    }
    if (band == DiagnosticVoltageBand.high) {
      return "High";
    }
    return "Critical";
  }
}
