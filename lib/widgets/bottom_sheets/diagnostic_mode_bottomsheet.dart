import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    if (manager == null) return;
    final cached = await PeripheralSetupCache.loadDiagnosticSetup(
      widget.deviceId,
    );
    if (cached != null) {
      _applyCachedData(cached);
    }
  }

  void _applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    final process = manager!.bleProcess;
    process.sounderOneAdcValue.value =
        (data['sounder1'] as num?)?.toDouble() ?? 0;
    process.sounderTwoAdcValue.value =
        (data['sounder2'] as num?)?.toDouble() ?? 0;
    process.sounderThreeAdcValue.value =
        (data['sounder3'] as num?)?.toDouble() ?? 0;
    process.dischargeAdcValue.value =
        (data['discharge'] as num?)?.toDouble() ?? 0;
    process.vauxAdcValue.value = (data['vaux'] as num?)?.toDouble() ?? 0;
    process.vinAdcValue.value = (data['vin'] as num?)?.toDouble() ?? 0;
    process.progInputAdcValue.value =
        (data['progInput'] as num?)?.toDouble() ?? 0;
    process.holdInputAdcValue.value =
        (data['holdInput'] as num?)?.toDouble() ?? 0;
    process.zone1AdcValue.value = (data['zone1'] as num?)?.toDouble() ?? 0;
    process.zone2AdcValue.value = (data['zone2'] as num?)?.toDouble() ?? 0;
    process.zone3AdcValue.value = (data['zone3'] as num?)?.toDouble() ?? 0;
    process.earthAdcValue.value = (data['earth'] as num?)?.toDouble() ?? 0;
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
}
