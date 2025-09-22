import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/screens/log_history_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/settings_screen.dart';
import 'package:techno_switch_solar_app/screens/test_mode_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final String panelVersionNo;
  final String panelName;
  final int? siteId;
  final String? siteName;
  const ProjectDashboardScreen({
    super.key,
    required this.panelVersionNo,
    required this.panelName,
    this.siteId,
    this.siteName,
  });

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _ProjectDashboardContent(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
    ),
    SettingsScreen(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
    ),
    const TestModeScreen(),
    LogHistoryScreen(
      panelName: widget.panelName,
      panelVersionNo: widget.panelVersionNo,
      siteId: widget.siteId ?? 0,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            iconSize: 24,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/dashboard_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 0 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/setting_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 1 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/test_mode_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 2 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Test Mode',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/log_history_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 3 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Log History',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            backgroundColor: Color(0xffEC1D24),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Create a separate widget for the EventLog content
class _ProjectDashboardContent extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  const _ProjectDashboardContent({
    required this.panelName,
    required this.panelVersionNo,
  });

  @override
  State<_ProjectDashboardContent> createState() =>
      _ProjectDashboardContentState();
}

class _ProjectDashboardContentState extends State<_ProjectDashboardContent> {
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
      child: Stack(
        children: [
          SvgPicture.asset('assets/svgs/background_1.svg'),
          Padding(
            padding: EdgeInsets.only(top: 54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/arrow_back_icon.svg',
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Project Name',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 19),
                _buildDashboardContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildDashboard()),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Panel Information Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                height: 81,
                width: 81,
              ),
              SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.panelName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.panelVersionNo,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF979797),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'status : ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF979797),
                          ),
                        ),
                        TextSpan(
                          text: 'connected',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00A706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              Transform.rotate(
                angle: 180 * 3.14159 / 360,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Color(0xFF696969),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildPeripheralOverview(),
          SizedBox(height: 42),
          _buildPanelActions(),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPeripheralOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peripheral Overview',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            // color: Colors.white,
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          height: 223,
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: 'Relay(1/2)',
                iconPath: 'assets/svgs/peripheral_relay_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Input(2/2)',
                iconPath: 'assets/svgs/peripheral_input_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Zones(3/3)',
                iconPath: 'assets/svgs/peripheral_zones_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Sounder(3/3)',
                iconPath: 'assets/svgs/peripheral_sounder_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Prog/Hold(2/2)',
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Aux(2/2)',
                iconPath: 'assets/svgs/peripheral_aux_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'L-Bus(2/2)',
                iconPath: 'assets/svgs/peripheral_l_bus_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Ext Out(1/1)',
                iconPath: 'assets/svgs/peripheral_ext_out_icon.svg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _peripheralTile({
    required String peripheralName,
    required String iconPath,
  }) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFF4F4F4),
              border: Border.all(color: Color(0xFFD7D7D7)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                // height: 24,
                // width: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          peripheralName,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF696969),
          ),
        ),
      ],
    );
  }

  Widget _buildPanelActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel Actions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            // color: Colors.white,
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          height: 223,
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LogRetrievalLoadingScreen(),
                    ),
                  );
                },
                child: _peripheralTile(
                  peripheralName: 'Event Log',
                  iconPath: 'assets/svgs/panel_action_event_log_icon.svg',
                ),
              ),
              _peripheralTile(
                peripheralName: 'Service Due',
                iconPath: 'assets/svgs/panel_action_service_due_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Factory Prog',
                iconPath: 'assets/svgs/panel_action_factory_prog_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Config Log',
                iconPath: 'assets/svgs/panel_action_config_log_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Test Mode',
                iconPath: 'assets/svgs/peripheral_prog_hold_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Aux(2/2)',
                iconPath: 'assets/svgs/peripheral_aux_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'L-Bus(2/2)',
                iconPath: 'assets/svgs/peripheral_l_bus_icon.svg',
              ),
              _peripheralTile(
                peripheralName: 'Ext Out(1/1)',
                iconPath: 'assets/svgs/peripheral_ext_out_icon.svg',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
