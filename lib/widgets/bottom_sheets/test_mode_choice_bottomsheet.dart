import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// First step: user picks Sounders or Relays for test configuration.
class TestModeChoiceBottomSheet extends StatelessWidget {
  final VoidCallback onSounders;
  final VoidCallback onRelays;

  const TestModeChoiceBottomSheet({
    super.key,
    required this.onSounders,
    required this.onRelays,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: ColorConstants.primaryVariant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            // padding: EdgeInsets.only(
            //   left: 24,
            //   right: 24,
            //   top: 16,
            //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            // ),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset('assets/svgs/bottomsheet_logo.svg'),
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstants.blackMaterial.withValues(alpha: 0.06),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dragHandle(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          StringConstants.testMode,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          StringConstants.chooseWhatToTest,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: ColorConstants.textSubtle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _optionTile(title: StringConstants.sounders, onTap: onSounders),
                      const SizedBox(height: 12),
                      _optionTile(title: StringConstants.relays, onTap: onRelays),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile({required String title, required VoidCallback onTap}) {
    return Material(
      color: ColorConstants.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorConstants.borderMuted),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.textDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
