import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/diagnostic_voltage_tile.dart';

enum DiagnosticSectionType { sounder, power, input, zone, other }

DiagnosticVoltageBand aggregateDiagnosticSectionBand(
  Iterable<double> voltages,
) {
  final bands = voltages.map(diagnosticVoltageBandFor);
  if (bands.any((b) => b == DiagnosticVoltageBand.critical)) {
    return DiagnosticVoltageBand.critical;
  }
  if (bands.any((b) => b == DiagnosticVoltageBand.high)) {
    return DiagnosticVoltageBand.high;
  }
  return DiagnosticVoltageBand.nominal;
}

String diagnosticSectionIconAsset(
  DiagnosticSectionType type,
  DiagnosticVoltageBand band,
) {
  if (type == DiagnosticSectionType.other &&
      band == DiagnosticVoltageBand.critical) {
    return 'assets/svgs/diagnostics/other_crticial_icon.svg';
  }

  final prefix = switch (type) {
    DiagnosticSectionType.sounder => 'sounder',
    DiagnosticSectionType.power => 'power',
    DiagnosticSectionType.input => 'input',
    DiagnosticSectionType.zone => 'zone',
    DiagnosticSectionType.other => 'other',
  };
  final suffix = switch (band) {
    DiagnosticVoltageBand.nominal => 'normal',
    DiagnosticVoltageBand.high => 'high',
    DiagnosticVoltageBand.critical => 'critical',
  };
  return 'assets/svgs/diagnostics/${prefix}_${suffix}_icon.svg';
}

String diagnosticSectionSubtitle(int channelCount, DiagnosticVoltageBand band) {
  final channels = channelCount == 1 ? '1 channel' : '$channelCount channels';
  final status = switch (band) {
    DiagnosticVoltageBand.nominal => 'All Nominal',
    DiagnosticVoltageBand.high => 'High',
    DiagnosticVoltageBand.critical => 'Critical',
  };
  return '$channels · $status';
}

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
              color: Color(0xFFE31C23),
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                ),
                // padding: EdgeInsets.only(
                //   left: 24,
                //   right: 24,
                //   top: 16,
                //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                // ),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset('assets/svgs/bottomsheet_logo.svg'),
                        Padding(
                          padding: const EdgeInsets.only(right: 32.0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        children: [
                          _dragHandle(),
                          _title('Diagnostics'),

                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              children: [
                                _section(
                                  title: 'Sounders',
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.sounder,
                                  items: [
                                    _VoltRef('SND 1', p.sounderOneAdcValue),
                                    _VoltRef('SND 2', p.sounderTwoAdcValue),
                                    _VoltRef('SND 3', p.sounderThreeAdcValue),
                                  ],
                                ),
                                _section(
                                  title: 'Power',
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.power,
                                  items: [
                                    _VoltRef('Vaux', p.vauxAdcValue),
                                    _VoltRef('Vin', p.vinAdcValue),
                                    _VoltRef('EXT', p.dischargeAdcValue),
                                  ],
                                ),
                                _section(
                                  title: 'Inputs',
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.input,
                                  items: [
                                    _VoltRef('Prog In', p.progInputAdcValue),
                                    _VoltRef('Hold In', p.holdInputAdcValue),
                                  ],
                                ),
                                _section(
                                  title: 'Zones',
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.zone,
                                  items: [
                                    _VoltRef('Zone 1', p.zone1AdcValue),
                                    _VoltRef('Zone 2', p.zone2AdcValue),
                                    _VoltRef('Zone 3', p.zone3AdcValue),
                                  ],
                                ),
                                _section(
                                  title: 'Other',
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.other,
                                  items: [_VoltRef('Earth', p.earthAdcValue)],
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
                                    foregroundColor:
                                        isFetchActive
                                            ? Colors.white
                                            : _brandRed,
                                    backgroundColor:
                                        isFetchActive ? _brandRed : null,
                                    side: const BorderSide(color: _brandRed),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed:
                                      isFetchActive
                                          ? widget.onStop
                                          : widget.onDownload,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
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

  Widget _section({
    required String title,
    required ValueListenable<bool> isLive,
    required List<_VoltRef> items,
    required DiagnosticSectionType diagnosticSectionType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 2,
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  items.map((item) => item.notifier).toList(),
                ),
                builder: (context, _) {
                  final sectionBand = aggregateDiagnosticSectionBand(
                    items.map((item) => item.notifier.value),
                  );

                  return Row(
                    children: [
                      SvgPicture.asset(
                        diagnosticSectionIconAsset(
                          diagnosticSectionType,
                          sectionBand,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
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
                          Text(
                            diagnosticSectionSubtitle(
                              items.length,
                              sectionBand,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff678196),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _valueColor(sectionBand),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // const SizedBox(height: 6),
            Divider(color: _border),
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 2,
                bottom: 8,
              ),
              child: LayoutBuilder(
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
                            isLive: isLive,
                            unit: 'V',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _valueColor(DiagnosticVoltageBand band) {
    if (band == DiagnosticVoltageBand.nominal) {
      return const Color(0xFF2B8073);
    }
    if (band == DiagnosticVoltageBand.high) {
      return const Color(0xFFEDA145);
    }
    return const Color(0xFFE4626F);
  }
}

class _VoltRef {
  const _VoltRef(this.label, this.notifier);

  final String label;
  final ValueNotifier<double> notifier;
}
