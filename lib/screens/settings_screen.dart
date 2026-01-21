import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/widgets/firmware_upgrade_bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;

  const SettingsScreen({
    super.key,
    required this.panelName,
    required this.panelVersionNo,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _SettingsContent(
        panelName: widget.panelName,
        panelVersionNo: widget.panelVersionNo,
      ),
    );
  }
}

// Create a separate widget for the EventLog content
class _SettingsContent extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  const _SettingsContent({
    required this.panelName,
    required this.panelVersionNo,
  });

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
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
            padding: EdgeInsets.only(top: 24),
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
                        'Project Settings',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 19),
                _buildSettingsContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildLogStatus()),
      ),
    );
  }

  Widget _buildLogStatus() {
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
                    widget.panelName.split('_').first,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.panelName.split('_').last,
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
                              text: isConnected ? 'Connected' : 'Disconnected',
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
              // Spacer(),
              // Transform.rotate(
              //   angle: 180 * 3.14159 / 360,
              //   child: Icon(
              //     Icons.arrow_forward_ios,
              //     size: 18,
              //     color: Color(0xFF696969),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 10),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Panel Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Zone Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Input Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Relay Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Sounder Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Extinguishing out Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'L-Bus Settings', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: 'Panel Information', onTap: () {}),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          _settingTile(
            title: 'Firmware Upgrade',
            onTap: () {
              // // Ensure UpdatesController is registered
              // if (!Get.isRegistered<UpdatesController>()) {
              //   Get.put(UpdatesController());
              // }
              // showModalBottomSheet(
              //   context: context,
              //   isScrollControlled: true,
              //   backgroundColor: Colors.transparent,
              //   isDismissible: false,
              //   enableDrag: true,
              //   builder: (context) => FirmwareUpgradeBottomSheet(),
              // );
            },
          ),
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _settingTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/svgs/settings_icon.svg',
              colorFilter: ColorFilter.mode(
                Color(0xFF1B1F26).withValues(alpha: 0.72),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFF696969).withValues(alpha: 0.47),
            ),
          ],
        ),
      ),
    );
  }
}
