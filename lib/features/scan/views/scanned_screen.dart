import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/views/scan_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/scan/widgets/scanned_results_view.dart';

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
    widget.controller.onScannedScreenDisposed(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScanController>(
      init: widget.controller,
      builder:
          (ctrl) => Scaffold(
            body: ScannedResultsView(
              controller: ctrl,
              onBack: ctrl.handleScannedBack,
            ),
          ),
    );
  }
}
