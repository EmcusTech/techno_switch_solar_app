import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/diagnostic_voltage_tile.dart';

class DiagnosticInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onStop;

  const DiagnosticInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onStop,
  });

  @override
  State<DiagnosticInfoBottomSheet> createState() =>
      _DiagnosticInfoBottomSheetState();
}

class _DiagnosticInfoBottomSheetState extends State<DiagnosticInfoBottomSheet> {
  static const Color _textPrimary = Color(0xFF3D3D3D);
  static const Color _brandRed = Color(0xFFEC1D24);
  static const Color _border = Color(0xFFDCDCDC);
  final ScrollController scrollController = ScrollController();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;
    if (manager == null) {
      return const SizedBox.shrink();
    }

    final p = manager!.bleProcess;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
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
                _dragHandle(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Diagnostics',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      _section(
                        title: 'Sounders',
                        items: [
                          _VoltRef('Sounder 1', p.sounderOneAdcValue),
                          _VoltRef('Sounder 2', p.sounderTwoAdcValue),
                          _VoltRef('Sounder 3', p.sounderThreeAdcValue),
                        ],
                      ),
                      _section(
                        title: 'Power',
                        items: [
                          _VoltRef('Vaux', p.vauxAdcValue),
                          _VoltRef('Vin', p.vinAdcValue),
                          _VoltRef('Discharge', p.dischargeAdcValue),
                        ],
                      ),
                      _section(
                        title: 'Inputs',
                        items: [
                          _VoltRef('Prog Input', p.progInputAdcValue),
                          _VoltRef('Hold Input', p.holdInputAdcValue),
                        ],
                      ),
                      _section(
                        title: 'Zones',
                        items: [
                          _VoltRef('Zone 1', p.zone1AdcValue),
                          _VoltRef('Zone 2', p.zone2AdcValue),
                          _VoltRef('Zone 3', p.zone3AdcValue),
                        ],
                      ),
                      _section(
                        title: 'Other',
                        items: [_VoltRef('Earth Detection', p.earthAdcValue)],
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: p.isAdcSetupFetchCommandActive,
                  builder: (context, isFetchActive, _) {
                    return SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brandRed,
                          side: const BorderSide(color: _brandRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed:
                            isFetchActive ? widget.onStop : widget.onDownload,
                        child: Text(
                          isFetchActive ? 'Stop' : 'Start',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _section({required String title, required List<_VoltRef> items}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final columns = 3;
                  final spacing = 8.0;
                  final tileW = (maxW - spacing * (columns - 1)) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: tileW,
                          child: DiagnosticVoltageTile(
                            label: item.label,
                            notifier: item.notifier,
                            unit: 'V',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoltRef {
  const _VoltRef(this.label, this.notifier);

  final String label;
  final ValueNotifier<double> notifier;
}
