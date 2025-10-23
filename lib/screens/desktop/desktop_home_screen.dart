import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/create_project/create_project_screen.dart';
import 'package:techno_switch_solar_app/screens/desktop/desktop_scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/site_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:intl/intl.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final SiteService _siteService = SiteService();
  List<SiteWithLogCount> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleBluetoothCleanup();
    _loadSites();
  }

  Future<void> _handleBluetoothCleanup() async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }
    AppState.reset();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _siteService.getSitesWithLogCount();
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading sites: $error');
    }
  }

  Future<void> _refreshSites() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildMenuBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSites,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConnectionAndActionCards(context),
                    SizedBox(height: 32),
                    _buildRecentSitesTable(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBar(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(width: 16),
              Center(
                child: SvgPicture.asset(
                  'assets/svgs/logo_clean.svg',
                  width: 20,
                  height: 20,
                  // colorFilter: ColorFilter.mode(
                  //   Colors.white,
                  //   BlendMode.srcIn,
                  // ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Technoswitch',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '-',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF918F8F),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Site name',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF918F8F),
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              _buildMenuButton('File'),
              _buildMenuButton('Panel'),
              _buildMenuButton('Settings'),
              _buildMenuButton('Help'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String label) {
    return TextButton(
      onPressed: () {
        // TODO: Implement menu actions
      },
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF3D3D3D),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildConnectionAndActionCards(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connection cards section (left side) - horizontal row
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: _buildConnectionCard(
                  icon: Icons.bolt,
                  iconColor: Color(0xFF2196F3),
                  iconBackgroundColor: Color(0xFFE3F2FD),
                  title: 'Connect Via USB',
                  subtitle:
                      'Connect your device to start setting up or\nmaintaining fire alarm panel',
                  buttonLabel: 'Connect Device',
                  buttonColor: Color(0xFF2196F3),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('USB connection coming soon'),
                        backgroundColor: Color(0xFF2196F3),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildConnectionCard(
                  icon: Icons.power_settings_new,
                  iconColor: Color(0xFFEC1D24),
                  iconBackgroundColor: Color(0xFFFFEBEE),
                  title: 'Tap to Connect',
                  subtitle:
                      'Connect your device to start setting\nup or maintaining fire alarm panel',
                  buttonLabel: 'Connect Device',
                  buttonColor: Color(0xFFEC1D24),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DesktopScanningScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 24),
        // Action cards section (right side) - 2x2 grid
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.add_circle_outline,
                      iconColor: Color(0xFF2196F3),
                      iconBackgroundColor: Color(0xFFE3F2FD),
                      title: 'New Site',
                      subtitle: 'Create a new setup project',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateSiteScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.motion_photos_on_outlined,
                      iconColor: Color(0xFFEC1D24),
                      iconBackgroundColor: Color(0xFFFFEBEE),
                      title: 'Live Event',
                      subtitle: 'Perform system checks',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    DesktopScanningScreen(isLiveEvent: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.download_outlined,
                      iconColor: Color(0xFF9C27B0),
                      iconBackgroundColor: Color(0xFFF3E5F5),
                      title: 'Retrieve Log',
                      subtitle: 'Download system log',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    DesktopScanningScreen(isLiveEvent: true),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.folder_open_outlined,
                      iconColor: Color(0xFF4CAF50),
                      iconBackgroundColor: Color(0xFFE8F5E9),
                      title: 'Open Site',
                      subtitle: 'Access existing project',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackgroundColor.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackgroundColor,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D3D3D),
            ),
          ),
          SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF918F8F),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF918F8F),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSitesTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sites',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D3D3D),
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE0E0E0), width: 1),
          ),
          child:
              _isLoading
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFEC1D24),
                      ),
                    ),
                  )
                  : _sites.isEmpty
                  ? _buildEmptyState()
                  : _buildSitesTable(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Color(0xFFE0E0E0),
            ),
            SizedBox(height: 16),
            Text(
              'No Sites Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first site to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF918F8F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitesTable() {
    return Table(
      columnWidths: {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          children: [
            _buildTableHeader('Project'),
            _buildTableHeader('Location'),
            _buildTableHeader('Date Created'),
            _buildTableHeader('Status'),
            _buildTableHeader('Actions'),
          ],
        ),
        // Data rows
        ..._sites.map((siteWithLogCount) {
          final site = siteWithLogCount.site;
          return TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
              ),
            ),
            children: [
              _buildTableCell(
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => SiteScreen(
                              site: site,
                              siteWithLogCount: siteWithLogCount,
                            ),
                      ),
                    );
                  },
                  child: Text(
                    site.siteName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  site.buildingName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  DateFormat('MMM dd, yyyy').format(site.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
              _buildTableCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Completed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Color(0xFF918F8F),
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: child,
    );
  }
}
