import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/diagnostic_voltage_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
    DiagnosticSectionType.sounder => StringConstants.generalEnabled,
    DiagnosticSectionType.power => 'power',
    DiagnosticSectionType.input => 'input',
    DiagnosticSectionType.zone => StringConstants.detectionmode,
    DiagnosticSectionType.other => 'other',
  };
  final suffix = switch (band) {
    DiagnosticVoltageBand.nominal => 'normal',
    DiagnosticVoltageBand.high => 'high',
    DiagnosticVoltageBand.critical => 'critical',
  };
  return 'assets/svgs/diagnostics/${prefix}_${suffix}_icon.svg';
}

String diagnosticSectionSubtitle(Iterable<double> voltages) {
  final voltageList = voltages.toList();
  final channelCount = voltageList.length;
  final channels = channelCount == 1 ? StringConstants.s1Channel : '$channelCount channels';

  final band = aggregateDiagnosticSectionBand(voltageList);
  var bandCount = 0;
  for (final voltage in voltageList) {
    if (diagnosticVoltageBandFor(voltage) == band) {
      bandCount++;
    }
  }
  final status = switch (band) {
    DiagnosticVoltageBand.nominal => 'All Nominal',
    DiagnosticVoltageBand.high => StringConstants.high,
    DiagnosticVoltageBand.critical => StringConstants.critical,
  };
  final bandLabel = bandCount == 1 ? '1 $status' : '$bandCount $status';
  return '$channels · $bandLabel';
}

class DiagnosticBandCounts {
  const DiagnosticBandCounts({
    required this.nominal,
    required this.high,
    required this.critical,
  });

  final int nominal;
  final int high;
  final int critical;
}

DiagnosticBandCounts countDiagnosticBands(Iterable<double> voltages) {
  var nominal = 0;
  var high = 0;
  var critical = 0;
  for (final voltage in voltages) {
    switch (diagnosticVoltageBandFor(voltage)) {
      case DiagnosticVoltageBand.nominal:
        nominal++;
      case DiagnosticVoltageBand.high:
        high++;
      case DiagnosticVoltageBand.critical:
        critical++;
    }
  }
  return DiagnosticBandCounts(nominal: nominal, high: high, critical: critical);
}

List<ValueNotifier<double>> allDiagnosticAdcNotifiers(BleProcess process) {
  return [
    process.sounderOneAdcValue,
    process.sounderTwoAdcValue,
    process.sounderThreeAdcValue,
    process.vauxAdcValue,
    process.vinAdcValue,
    process.dischargeAdcValue,
    process.progInputAdcValue,
    process.holdInputAdcValue,
    process.zone1AdcValue,
    process.zone2AdcValue,
    process.zone3AdcValue,
    process.earthAdcValue,
  ];
}

List<double> allDiagnosticAdcValues(BleProcess process) {
  return allDiagnosticAdcNotifiers(
    process,
  ).map((notifier) => notifier.value).toList();
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
  static const Color _textPrimary = ColorConstants.textDark;
  static const Color _brandRed = ColorConstants.primary;
  static const Color _border = ColorConstants.borderMuted;
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
        (data[StringConstants.sounder1] as num?)?.toDouble() ?? 0;
    process.sounderTwoAdcValue.value =
        (data[StringConstants.sounder2] as num?)?.toDouble() ?? 0;
    process.sounderThreeAdcValue.value =
        (data[StringConstants.sounder3] as num?)?.toDouble() ?? 0;
    process.dischargeAdcValue.value =
        (data['discharge'] as num?)?.toDouble() ?? 0;
    process.vauxAdcValue.value = (data['vaux'] as num?)?.toDouble() ?? 0;
    process.vinAdcValue.value = (data['vin'] as num?)?.toDouble() ?? 0;
    process.progInputAdcValue.value =
        (data[StringConstants.proginput] as num?)?.toDouble() ?? 0;
    process.holdInputAdcValue.value =
        (data['holdInput'] as num?)?.toDouble() ?? 0;
    process.zone1AdcValue.value = (data[StringConstants.zone12] as num?)?.toDouble() ?? 0;
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

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: ColorConstants.primaryVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: ColorConstants.white,
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
                                color: ColorConstants.blackMaterial.withValues(alpha: 0.06),
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
                          _title(StringConstants.liveDataIsBeingStreamedFromTheDeviceInRealTime),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              children: [
                                _diagnosticSummaryRow(p),
                                const SizedBox(height: 16),
                                _section(
                                  title: StringConstants.sounders,
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.sounder,
                                  items: [
                                    _VoltRef('SND 1', p.sounderOneAdcValue),
                                    _VoltRef(StringConstants.snd2, p.sounderTwoAdcValue),
                                    _VoltRef(StringConstants.snd3, p.sounderThreeAdcValue),
                                  ],
                                ),
                                _section(
                                  title: StringConstants.power,
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.power,
                                  items: [
                                    _VoltRef('Vaux', p.vauxAdcValue),
                                    _VoltRef(StringConstants.vin, p.vinAdcValue),
                                    _VoltRef(StringConstants.ext, p.dischargeAdcValue),
                                  ],
                                ),
                                _section(
                                  title: StringConstants.inputs,
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.input,
                                  items: [
                                    _VoltRef('Prog In', p.progInputAdcValue),
                                    _VoltRef(StringConstants.holdIn, p.holdInputAdcValue),
                                  ],
                                ),
                                _section(
                                  title: StringConstants.zones,
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.zone,
                                  items: [
                                    _VoltRef('Zone 1', p.zone1AdcValue),
                                    _VoltRef(StringConstants.zone22, p.zone2AdcValue),
                                    _VoltRef(StringConstants.zone32, p.zone3AdcValue),
                                  ],
                                ),
                                _section(
                                  title: StringConstants.other,
                                  isLive: p.isAdcSetupFetchCommandActive,
                                  diagnosticSectionType:
                                      DiagnosticSectionType.other,
                                  items: [_VoltRef(StringConstants.earth, p.earthAdcValue)],
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
                                    foregroundColor: ColorConstants.white,
                                    backgroundColor: _brandRed,
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
                                    isFetchActive ? StringConstants.stop : StringConstants.start,
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

  Widget _diagnosticSummaryRow(BleProcess process) {
    final notifiers = allDiagnosticAdcNotifiers(process);
    return AnimatedBuilder(
      animation: Listenable.merge(notifiers),
      builder: (context, _) {
        final counts = countDiagnosticBands(allDiagnosticAdcValues(process));
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _summaryChip(
                  label: StringConstants.none,
                  count: counts.nominal,
                  band: DiagnosticVoltageBand.nominal,
                  iconAsset:
                      'assets/svgs/diagnostics/diagnostics_normal_icon.svg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip(
                  label: StringConstants.high,
                  count: counts.high,
                  band: DiagnosticVoltageBand.high,
                  iconAsset:
                      'assets/svgs/diagnostics/diagnostics_high_icon.svg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip(
                  label: StringConstants.critical,
                  count: counts.critical,
                  band: DiagnosticVoltageBand.critical,
                  iconAsset:
                      'assets/svgs/diagnostics/diagnostics_critical_icon.svg',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip({
    required String label,
    required int count,
    required DiagnosticVoltageBand band,
    required String iconAsset,
  }) {
    final accent = _valueColor(band);
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.01),
            offset: const Offset(3, 6),
            blurRadius: 3,
          ),
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
            offset: const Offset(2, 3),
            blurRadius: 2,
          ),
          BoxShadow(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.09),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
          BoxShadow(color: ColorConstants.blackMaterial.withValues(alpha: 0.10), blurRadius: 1),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(height: 5, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(iconAsset),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.blueGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                              items.map((item) => item.notifier.value),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: ColorConstants.blueGray,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      // Container(
                      //   height: 14,
                      //   width: 14,
                      //   decoration: BoxDecoration(
                      //     shape: BoxShape.circle,
                      //     color: _valueColor(sectionBand),
                      //   ),
                      // ),
                      // const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/svgs/diagnostics/diagnostics_dropdown_icon.svg',
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
      return ColorConstants.teal;
    }
    if (band == DiagnosticVoltageBand.high) {
      return ColorConstants.warningAmber;
    }
    return ColorConstants.errorPink;
  }
}

class _VoltRef {
  const _VoltRef(this.label, this.notifier);

  final String label;
  final ValueNotifier<double> notifier;
}
