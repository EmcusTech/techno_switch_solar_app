import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6EBEB), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3D3D),
              ),
            ),
          ),
          _buildSettingsSection(
            'Account',
            [
              _buildSettingsItem(
                'Profile Information',
                Icons.person_outline,
                () {},
              ),
              _buildSettingsItem(
                'Notifications',
                Icons.notifications_outlined,
                () {},
              ),
            ],
          ),
          _buildSettingsSection(
            'Preferences',
            [
              _buildSettingsItem(
                'Language',
                Icons.language_outlined,
                () {},
              ),
              _buildSettingsItem(
                'Theme',
                Icons.palette_outlined,
                () {},
              ),
              _buildSettingsItem(
                'Units',
                Icons.straighten_outlined,
                () {},
              ),
            ],
          ),
          _buildSettingsSection(
            'Support',
            [
              _buildSettingsItem(
                'About',
                Icons.info_outline,
                () {},
              ),
              _buildSettingsItem(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                () {},
              ),
              _buildSettingsItem(
                'Terms of Service',
                Icons.description_outlined,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
        ),
        ...items,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF3D3D3D),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Color(0xFF3D3D3D),
            ),
          ],
        ),
      ),
    );
  }
} 