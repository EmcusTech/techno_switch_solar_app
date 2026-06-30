import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

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
  final bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();
  Future<bool> _confirmAndDisconnect() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            StringConstants.disconnectDevice,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Text(
            StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                StringConstants.cancel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.5),
                ),
                elevation: 0,
              ),
              child: Text(
                'Disconnect',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDisconnect == true) {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (bleController.isConnected) {
          final shouldPop = await _confirmAndDisconnect();
          return shouldPop;
        } else {
          return true;
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset(AssetConstants.background1),
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
                          onTap: () async {
                            if (bleController.isConnected) {
                              final shouldPop = await _confirmAndDisconnect();
                              if (shouldPop && mounted) {
                                Navigator.of(context).pop();
                              }
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: SvgPicture.asset(
                            AssetConstants.arrowBackIcon,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          StringConstants.projectSettings,
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
      ),
    );
  }

  Widget _buildSettingsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
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
          Row(
            children: [
              SvgPicture.asset(
                AssetConstants.panelIcon,
                height: 62,
                width: 62,
              ),
              SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BleNameUtils.getDisplayPrefixFromBleName(widget.panelName),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    BleNameUtils.getDisplayIdFromBleName(widget.panelName),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.textDisabled,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _bleManager.isConnectedNotifier,
                    builder: (context, isConnected, child) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: StringConstants.status4,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ColorConstants.textDisabled,
                              ),
                            ),
                            TextSpan(
                              text: isConnected ? StringConstants.connected : StringConstants.disconnected,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isConnected
                                        ? ColorConstants.success
                                        : ColorConstants.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.panelSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.zoneSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.inputSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.relaySettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.sounderSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.extinguishingOutSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.lBusSettings, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.panelInformation, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          _settingTile(title: StringConstants.firmwareUpgrade, onTap: () {}),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
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
              AssetConstants.settingsIcon,
              colorFilter: ColorFilter.mode(
                ColorConstants.textHeading.withValues(alpha: 0.72),
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
              color: ColorConstants.textSecondary.withValues(alpha: 0.47),
            ),
          ],
        ),
      ),
    );
  }
}
