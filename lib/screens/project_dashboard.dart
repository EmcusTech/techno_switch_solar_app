import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/screens/log_history_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart'
    hide ble;
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/settings_screen.dart';
import 'package:techno_switch_solar_app/screens/test_mode_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final String panelVersionNo;
  final String panelName;
  final int? siteId;
  final String? siteName;
  final DiscoveredDevice selectedDevice;
  const ProjectDashboardScreen({
    super.key,
    required this.panelVersionNo,
    required this.panelName,
    this.siteId,
    this.siteName,
    required this.selectedDevice,
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
      selectedDevice: widget.selectedDevice,
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
  final DiscoveredDevice selectedDevice;
  const _ProjectDashboardContent({
    required this.panelName,
    required this.panelVersionNo,
    required this.selectedDevice,
  });

  @override
  State<_ProjectDashboardContent> createState() =>
      _ProjectDashboardContentState();
}

class _ProjectDashboardContentState extends State<_ProjectDashboardContent> {
  // Prevent multiple navigations while dialog rebuilds
  bool _navigatingToDeviceConnecting = false;

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
                        'Project Dashboard',
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

  void showPasswordPopup({required Function() onCall}) {
    // Reset navigation guard each time the dialog opens
    _navigatingToDeviceConnecting = false;

    // Reset previous access-key validation state
    final bleProcess = Get.find<BleLogController>().bleProcess;
    bleProcess.isAccessKeyValid.value = null;
    bleProcess.accessKey.value = "";

    final TextEditingController _controller = TextEditingController();
    final ValueNotifier<String?> errorText = ValueNotifier(null);
    final accessKey = bleProcess.accessKey;
    final ValueNotifier<bool?> isAccessKeyValid = bleProcess.isAccessKeyValid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/svgs/lock_icon.svg',
                      height: 32,
                      width: 32,
                      colorFilter: ColorFilter.mode(
                        Color(0xFFEC1D24),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  'Enter 4-Digit Password',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Subtitle
                Text(
                  'Please enter the password to continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Password Input Field + CTA
                ValueListenableBuilder<bool?>(
                  valueListenable: isAccessKeyValid,
                  builder: (_, isAccessKeyValidValue, __) {
                    // Auto-close on success and navigate, but defer to next frame
                    // to avoid build-phase setState/overlay errors.
                    if (isAccessKeyValidValue == true &&
                        !_navigatingToDeviceConnecting) {
                      _navigatingToDeviceConnecting = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!mounted) return;
                        // Briefly show success before navigating
                        await Future.delayed(const Duration(seconds: 1));
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => LogRetrievalLoadingScreen(
                                  scanType: ScanType.bluetooth,
                                  selectedDevice: widget.selectedDevice,
                                ),
                          ),
                        );
                      });
                    }

                    return Column(
                      children: [
                        TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                            color: Color(0xFF3D3D3D),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (val) {
                            accessKey.value = val;
                            if (val.length == 4) {
                              errorText.value = null;
                              // reset validation state for new attempt
                              bleProcess.isAccessKeyValid.value = null;
                              // Dismiss keyboard and start validation
                              FocusScope.of(context).unfocus();
                              // Provide immediate feedback while validating
                              bleProcess.processDesc.value =
                                  "Validating access key...";
                              onCall();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '••••',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8,
                              color: Color(0xFFD0D0D0),
                            ),
                            errorText:
                                isAccessKeyValidValue == false
                                    ? "Invalid access key. Try again."
                                    : null,
                            errorStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFEC1D24),
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: Color(0xFFF8F8F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isAccessKeyValidValue == false
                                        ? Color(0xFFEC1D24)
                                        : Color(0xFFD0D0D0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isAccessKeyValidValue == false
                                        ? Color(0xFFEC1D24)
                                        : Color(0xFFD0D0D0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        // Status text during validation/success
                        Builder(
                          builder: (_) {
                            String? status;
                            if (_controller.text.length == 4 &&
                                isAccessKeyValidValue == null) {
                              status = "Validating access key...";
                            } else if (isAccessKeyValidValue == true) {
                              status = "Validation success";
                            }
                            return status == null
                                ? const SizedBox.shrink()
                                : Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D3D3D),
                                  ),
                                );
                          },
                        ),

                        SizedBox(height: 16),

                        // Cancel Button only when not validating or already successful
                        if (!(_controller.text.length == 4 &&
                                isAccessKeyValidValue == null) &&
                            isAccessKeyValidValue != true)
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Color(0xFFEFEEEE),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Color(0xFFD0D0D0),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                height: 62,
                width: 62,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.panelVersionNo,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF979797),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: ble.isConnectedNotifier,
                    builder: (context, isConnected, child) {
                      return RichText(
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
                              text: isConnected ? 'connected' : 'disconnected',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isConnected
                                        ? Color(0xFF00A706)
                                        : Color(0xFFEC1D24),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                  final bleController = Get.find<BleLogController>();
                  // If not connected, show an alert and return
                  if (!bleController.isConnected) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBDEE1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.bluetooth_disabled,
                                      color: Color(0xFFEC1D24),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Device not connected',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D3D3D),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'BLE device is not connected. Please scan and connect again.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF666666),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFEEEE),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFD0D0D0),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Close',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF666666),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEC1D24),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFEC1D24,
                                                ).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Scan Again',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    return;
                  }

                  showPasswordPopup(
                    onCall: () {
                      print("access key is valid");
                      bleController.startLogRetrieval();
                    },
                  );
                  // Get.find<BleLogController>().startLogRetrieval();
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder:
                  //         (context) => DeviceConnectingScreen(
                  //           scanType: ScanType.bluetooth,
                  //           selectedDevice: widget.selectedDevice,
                  //         ),
                  //   ),
                  // );
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
