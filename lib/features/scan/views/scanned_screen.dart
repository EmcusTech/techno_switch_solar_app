import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/features/scan/views/scan_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:usb_serial/usb_serial.dart';

class ScannedScreen extends GetView<ScanController> {
  const ScannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ScannedPageHost(controller: controller);
  }
}

class _ScannedPageHost extends StatefulWidget {
  const _ScannedPageHost({required this.controller});

  final ScanController controller;

  @override
  State<_ScannedPageHost> createState() => _ScannedPageHostState();
}

class _ScannedPageHostState extends State<_ScannedPageHost>
    with ScanUiDelegateMixin {
  @override
  ScanController get scanController => widget.controller;

  @override
  void initState() {
    super.initState();
    widget.controller.attachUi(this);
    widget.controller.transitioningToScanned = false;
  }

  @override
  void dispose() {
    widget.controller.detachUi();
    final isCreateWizardReturn =
        widget.controller.createProjectExpectedPanelType?.trim().isNotEmpty ==
            true &&
        widget.controller.flowMode == ScanFlowMode.scanned;
    if (isCreateWizardReturn) {
      widget.controller.restoreScanningUi();
    } else if (Get.isRegistered<ScanController>()) {
      Get.delete<ScanController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScanController>(
      init: widget.controller,
      builder: (ctrl) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstants.scaffoldGradientTop,
                  ColorConstants.white,
                ],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, ctrl),
                _buildDevicesIdentified(ctrl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ScanController ctrl) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset(AssetConstants.background1),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: () => ctrl.openScanAgain(),
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.errorIconBackground,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          AssetConstants.logo,
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            ColorConstants.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Text(
                StringConstants.tapToScanAgain,
                style: StyleConstants.textDark14w400Style,
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.blackMaterial.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: ColorConstants.textDark,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesIdentified(ScanController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              StringConstants.panelsIdentified,
              style: StyleConstants.textDark18w700Style,
            ),
          ),
          SizedBox(height: 20),
          ctrl.discoveredDevices.isEmpty
              ? _buildNoDevicesFound(ctrl)
              : _buildDevicesList(ctrl),
        ],
      ),
    );
  }

  Widget _buildNoDevicesFound(ScanController ctrl) {
    final scanType = ctrl.selectedScanType ?? ScanType.bluetooth;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            scanType == ScanType.usb
                ? Icons.usb_off
                : Icons.bluetooth_disabled,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No ${scanType == ScanType.usb ? 'USB' : StringConstants.bluetooth} Devices Found',
            style: StyleConstants.black16w600Style.copyWith(
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            scanType == ScanType.usb
                ? 'Make sure your solar devices are connected via USB and powered on.'
                : UiStrings.bluetoothPairingModeHintMessage,
            textAlign: TextAlign.center,
            style: StyleConstants.black12w400Style.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(ScanController ctrl) {
    final scanType = ctrl.selectedScanType ?? ScanType.bluetooth;
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: ctrl.discoveredDevices.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final device = ctrl.discoveredDevices[index];
        return GestureDetector(
          onTap: () async {
            if (device is DiscoveredDevice) {
              await ctrl.onDeviceSelected(device);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: ColorConstants.white,
              border: Border.all(
                color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (scanType == ScanType.usb
                              ? ColorConstants.primary
                              : Colors.blue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(AssetConstants.panelIcon),
                  ),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BleNameUtils.getDisplayPrefixFromBleName(
                            _getDeviceName(scanType, device),
                          ),
                          style: StyleConstants.textDark14w700Style,
                        ),
                        Text(
                          BleNameUtils.getDisplayIdFromBleName(
                            _getDeviceName(scanType, device),
                          ),
                          style: StyleConstants.textMuted14w700Style,
                        ),
                        Text(
                          _getDeviceInfo(scanType, device),
                          style: StyleConstants.textMuted12w400Style,
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(AssetConstants.arrowRightColoredIcon),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDeviceName(ScanType scanType, dynamic device) {
    if (scanType == ScanType.usb && device is UsbDevice) {
      return device.productName ?? StringConstants.usbSolarDevice;
    } else if (scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return device.name.isNotEmpty
          ? device.name
          : StringConstants.bleSolarDevice;
    }
    return StringConstants.unknownDevice;
  }

  String _getDeviceInfo(ScanType scanType, dynamic device) {
    if (scanType == ScanType.usb && device is UsbDevice) {
      return 'VID: ${device.vid?.toRadixString(16) ?? 'Unknown'} | PID: ${device.pid?.toRadixString(16) ?? 'Unknown'}';
    } else if (scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return 'RSSI: ${device.rssi} dBm';
    }
    return StringConstants.noInformationAvailable;
  }
}
