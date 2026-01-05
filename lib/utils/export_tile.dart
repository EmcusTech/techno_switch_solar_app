import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ExportTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFFEC1D24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A3A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
