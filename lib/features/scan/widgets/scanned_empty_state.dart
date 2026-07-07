import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScannedEmptyState extends StatelessWidget {
  const ScannedEmptyState({super.key, required this.scanType});

  final ScanType scanType;

  @override
  Widget build(BuildContext context) {
    final isUsb = scanType == ScanType.usb;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isUsb ? Icons.usb_off : Icons.bluetooth_disabled,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isUsb ? 'USB' : StringConstants.bluetooth} Devices Found',
            style: StyleConstants.black16w600Style.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUsb
                ? StringConstants.makeSureYourSolarDevicesAreConnectedViaUSBAndPoweredOn
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
}
