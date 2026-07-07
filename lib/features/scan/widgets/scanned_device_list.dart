import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scanned_device_list_tile.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scanned_empty_state.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScannedDeviceList extends StatelessWidget {
  const ScannedDeviceList({super.key, required this.controller});

  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final scanType = controller.selectedScanType ?? ScanType.bluetooth;
    final devices = controller.discoveredDevices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Text(
            StringConstants.panelsIdentified,
            style: StyleConstants.textDark18w700Style,
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                devices.isEmpty
                    ? ScannedEmptyState(scanType: scanType)
                    : ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final rawName = controller.deviceDisplayName(device);
                        return ScannedDeviceListTile(
                          scanType: scanType,
                          displayPrefix:
                              BleNameUtils.getDisplayPrefixFromBleName(rawName),
                          displayId:
                              BleNameUtils.getDisplayIdFromBleName(rawName),
                          subtitle: controller.deviceSubtitle(device),
                          onTap: () => controller.onDiscoveredDeviceTapped(device),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
