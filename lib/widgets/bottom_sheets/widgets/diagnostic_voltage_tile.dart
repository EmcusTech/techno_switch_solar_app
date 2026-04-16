import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft classification for ADC-derived voltages (generic thresholds).
enum DiagnosticVoltageBand { inactive, nominal, attention }

DiagnosticVoltageBand diagnosticVoltageBandFor(double volts) {
  final a = volts.abs();
  if (a < 0.08) return DiagnosticVoltageBand.inactive;
  if (a > 42 || volts < -1) return DiagnosticVoltageBand.attention;
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
            color: _surfaceMuted,
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
                child: Container(width: 3, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                        height: 1.2,
                      ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _accentFor(DiagnosticVoltageBand band) {
    return const Color(0xFFEC1D24);
  }

  Color _valueColor(DiagnosticVoltageBand band) {
    return const Color(0xFFC05621);
  }
}
