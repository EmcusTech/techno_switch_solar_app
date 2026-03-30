import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

class DiagnosticInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;

  const DiagnosticInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
  });

  @override
  State<DiagnosticInfoBottomSheet> createState() =>
      _DiagnosticInfoBottomSheetState();
}

class _DiagnosticInfoBottomSheetState extends State<DiagnosticInfoBottomSheet> {
  BleManager? manager;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    if (manager == null) {
      return const SizedBox.shrink();
    }

    final p = manager!.bleProcess;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Diagnostics',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section("Sounders", [
                        _voltCard("Sounder 1", p.sounderOneAdcValue),
                        _voltCard("Sounder 2", p.sounderTwoAdcValue),
                        _voltCard("Sounder 3", p.sounderThreeAdcValue),
                      ]),

                      _section("Power", [
                        _voltCard("Vaux", p.vauxAdcValue),
                        _voltCard("Vin", p.vinAdcValue),
                        _voltCard("Discharge", p.dischargeAdcValue),
                      ]),

                      _section("Inputs", [
                        _voltCard("Prog Input", p.progInputAdcValue),
                        _voltCard("Hold Input", p.holdInputAdcValue),
                      ]),

                      _section("Zones", [
                        _voltCard("Zone 1", p.zone1AdcValue),
                        _voltCard("Zone 2", p.zone2AdcValue),
                        _voltCard("Zone 3", p.zone3AdcValue),
                      ]),

                      _section("Other", [
                        _voltCard("Earth Detection", p.earthAdcValue),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEC1D24),
                    side: const BorderSide(color: Color(0xFFEC1D24)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: widget.onDownload,
                  child: Text(
                    'Download',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voltCard(String label, ValueNotifier<double> notifier) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (_, value, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${value.toStringAsFixed(2)} V",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _getVoltageColor(value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getVoltageColor(double v) {
    return const Color(0xFFEC1D24);
  }

  Widget _section(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (_, i) => items[i],
          ),
        ],
      ),
    );
  }

  Widget _voltTile(String label, ValueNotifier<double> notifier) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (_, volts, __) {
        return _infoTile(label, '${volts.toStringAsFixed(2)} V');
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
