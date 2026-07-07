import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scan_shell.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scanned_device_list.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scanned_header.dart';

class ScannedResultsView extends StatelessWidget {
  const ScannedResultsView({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final ScanController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ScanShell(
      child: Column(
        children: [
          ScannedHeader(
            onScanAgain: controller.openScanAgain,
            onBack: onBack,
          ),
          Expanded(child: ScannedDeviceList(controller: controller)),
        ],
      ),
    );
  }
}
