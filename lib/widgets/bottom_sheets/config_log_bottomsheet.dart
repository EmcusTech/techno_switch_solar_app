import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_diff_labels.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/widgets/common/dropdown.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

enum ConfigLogPresentationStyle { bottomSheet, dialog }

class ConfigLogBottomSheet extends StatefulWidget {
  final String deviceId;
  final ValueNotifier<ConfigCompareResult?> compareResult;
  final ValueNotifier<bool> isWorking;
  final VoidCallback onDownloadAndCompare;
  final Future<void> Function() onUsePanelDataInApp;
  final VoidCallback onApplyLocalToPanel;
  final bool showDownloadAndCompareCta;

  final ConfigLogPresentationStyle presentation;

  const ConfigLogBottomSheet({
    super.key,
    required this.deviceId,
    required this.compareResult,
    required this.isWorking,
    required this.onDownloadAndCompare,
    required this.onUsePanelDataInApp,
    required this.onApplyLocalToPanel,
    this.showDownloadAndCompareCta = true,
    this.presentation = ConfigLogPresentationStyle.bottomSheet,
  });

  @override
  State<ConfigLogBottomSheet> createState() => _ConfigLogBottomSheetState();
}

class _ConfigLogBottomSheetState extends State<ConfigLogBottomSheet>
    with TickerProviderStateMixin {
  final BleManager ble = Get.find<BleManager>();
  static const Color _textPrimary = ColorConstants.textDark;
  static const Color _textMuted = ColorConstants.textMuted;
  static const Color _textTabUnselected = ColorConstants.textSubtle;
  static const Color _brandRed = ColorConstants.primary;
  static const Color _border = ColorConstants.borderMuted;
  static const Color _surfaceMuted = ColorConstants.surfaceLight;

  static final RegExp _listIndexFromPathRe = RegExp(r'^\[(\d+)\]');

  TabController? _tabController;
  final ScrollController _resultController = ScrollController();
  final ScrollController _cardController = ScrollController();
  int _selectedLBus = 1;

  @override
  void initState() {
    super.initState();

    _resultController.addListener(_syncOuterScroll);

    widget.compareResult.addListener(_onResultChanged);
    widget.isWorking.addListener(_onWorkingChanged);
    // Notifier does not fire on attach; align TabController before first build.
    _syncTabControllerFromResult(widget.compareResult.value);
    _syncSelectedLBusFromResult(widget.compareResult.value);
  }

  @override
  void dispose() {
    _resultController.removeListener(_syncOuterScroll);

    _resultController.dispose();
    _cardController.dispose();
    _tabController?.dispose();
    widget.compareResult.removeListener(_onResultChanged);
    widget.isWorking.removeListener(_onWorkingChanged);
    super.dispose();
  }

  void _syncOuterScroll() {
    if (!_resultController.hasClients || !_cardController.hasClients) {
      return;
    }

    final delta =
        _resultController.position.userScrollDirection ==
                ScrollDirection.reverse
            ? 8.0
            : _resultController.position.userScrollDirection ==
                ScrollDirection.forward
            ? -8.0
            : 0.0;

    if (delta == 0) return;

    final target = (_cardController.offset + delta).clamp(
      _cardController.position.minScrollExtent,
      _cardController.position.maxScrollExtent,
    );

    if (target != _cardController.offset) {
      _cardController.jumpTo(target);
    }
  }

  void _syncTabControllerFromResult(ConfigCompareResult? result) {
    if (result != null &&
        result.errorMessage == null &&
        !result.isAppCacheEmpty &&
        result.hasMismatch &&
        result.mismatchedSections.isNotEmpty) {
      _tabController?.dispose();
      _tabController = TabController(
        length: result.mismatchedSections.length,
        vsync: this,
      );
    } else {
      _tabController?.dispose();
      _tabController = null;
    }
  }

  void _onResultChanged() {
    _syncTabControllerFromResult(widget.compareResult.value);
    _syncSelectedLBusFromResult(widget.compareResult.value);
    if (mounted) setState(() {});
  }

  int? _listIndexFromDiffLine(String line) {
    final path = line.split(':').first.trim();
    final match = _listIndexFromPathRe.firstMatch(path);
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }

  void _syncSelectedLBusFromResult(ConfigCompareResult? result) {
    if (result == null) return;
    final lines = _lBusFieldDiffLines(
      result.diffLinesFor(PeripheralConfigSection.lBus),
    );
    for (final line in lines) {
      final index = _listIndexFromDiffLine(line);
      if (index != null) {
        _selectedLBus = index + 1;
        return;
      }
    }
  }

  List<String> _lBusFieldDiffLines(List<String> lines) {
    return lines.where((line) => _listIndexFromDiffLine(line) != null).toList();
  }

  /// True when the only mismatch is L-Bus comms fault with no field-level diffs.
  bool _isLBusCommsFaultOnlyMismatch(ConfigCompareResult result) {
    return result.lBusCommsFaultBusNumbers.isNotEmpty &&
        result.mismatchedSections.length == 1 &&
        result.mismatchedSections.single == PeripheralConfigSection.lBus &&
        _lBusFieldDiffLines(
          result.diffLinesFor(PeripheralConfigSection.lBus),
        ).isEmpty;
  }

  Widget _lBusCommsFaultBanner(List<String> busNumbers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.errorBackgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${StringConstants.lBusCommsFaultOnBusesPrefix}${busNumbers.join(", ")}',
            style: StyleConstants.black13w600Style.copyWith(
              color: _brandRed,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            StringConstants
                .enabledBusDetailMayBeIncompleteUsePerBusDownloadOnThe,
            style: StyleConstants.textDarkGray12w400Style,
          ),
        ],
      ),
    );
  }

  List<String> _filterDiffLinesForLBus(List<String> lines, int selectedBus) {
    final index = selectedBus - 1;
    return lines.where((line) {
      final listIndex = _listIndexFromDiffLine(line);
      if (listIndex == null) return true;
      return listIndex == index;
    }).toList();
  }

  Widget _lBusSelector() {
    return DropdownWidget(
      label: StringConstants.selectLBus,
      value: 'L-Bus $_selectedLBus',
      items: List.generate(31, (i) => 'L-Bus ${i + 1}'),
      dropdownListHeight: MediaQuery.sizeOf(context).height * 0.2,
      enableSearch: false,
      onChanged: (value) {
        final number = int.parse(value.split(' ').last);
        setState(() => _selectedLBus = number);
      },
    );
  }

  String _humanizeDiffPath(
    String sectionKey,
    String path, {
    bool stripListDevicePrefix = false,
  }) {
    var normalized = path;
    if (stripListDevicePrefix) {
      normalized = normalized.replaceFirst(RegExp(r'^\[\d+\]\.?'), '');
    }
    return PeripheralConfigDiffLabels.humanizeFieldPath(sectionKey, normalized);
  }

  void _onWorkingChanged() {
    if (mounted) setState(() {});
  }

  bool _tabControllerMatchesResult(ConfigCompareResult? result) {
    if (!_showMismatchTabs(result)) return _tabController == null;
    final r = result!;
    final c = _tabController;
    return c != null && c.length == r.mismatchedSections.length;
  }

  /// Re-align when [ValueNotifier] skips notification (`value ==` old) or ordering leaves us stale.
  /// Runs after this frame so we are not mutating [TabController] during build.
  void _ensureTabControllerAligned(ConfigCompareResult? result) {
    if (_tabControllerMatchesResult(result)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tabControllerMatchesResult(widget.compareResult.value)) return;
      _syncTabControllerFromResult(widget.compareResult.value);
      if (mounted) setState(() {});
    });
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: StyleConstants.black20w700Style.copyWith(color: _textPrimary),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: StyleConstants.black15w600Style.copyWith(color: _textPrimary),
    );
  }

  /// Bordered block matching sounder / relay section containers.
  Widget _sectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _tileShell({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _sectionContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel(title),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  /// Matches download/compare progress: live [ble.processDesc] from the BLE stack.
  Widget _operationProgressBanner(bool working) {
    if (!working) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: ValueListenableBuilder<String>(
          valueListenable: ble.processDesc,
          builder: (context, value, _) {
            final text = value.trim();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _brandRed.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text.isEmpty ? StringConstants.comparing : text,
                    maxLines: 1,
                    style: StyleConstants.primary13w600Style.copyWith(
                      color: _textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmApplyLocal() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_upload_rounded,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.applyToPanel,
                  style: StyleConstants.black20w700Style.copyWith(
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  UiStrings.applyToPanelConfirmMessage,
                  style: StyleConstants.textMuted14w400Style.copyWith(
                    color: _textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _brandRed,
                            side: const BorderSide(color: _brandRed),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            StringConstants.cancel,
                            style: StyleConstants.primary16w600Style,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandRed,
                            foregroundColor: ColorConstants.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            StringConstants.apply,
                            style: StyleConstants.white16w600Style,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) {
      widget.onApplyLocalToPanel();
    }
  }

  Widget _diffValueSideRow(String sideLabel, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            sideLabel,
            style: StyleConstants.black12w500Style.copyWith(
              color: _textMuted,
              height: 1.4,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: StyleConstants.textDarkGray12w400Style,
          ),
        ),
      ],
    );
  }

  Widget _diffFieldTitle(String title) {
    return Text(
      title,
      style: StyleConstants.primary13w600Style.copyWith(
        color: _textPrimary,
        height: 1.35,
      ),
    );
  }

  Widget _diffLineWidget(
    String sectionKey,
    String line, {
    bool stripListDevicePrefix = false,
  }) {
    const panelPrefix = ': panel ';
    const appSep = ' · app ';
    final panelIdx = line.indexOf(panelPrefix);
    if (panelIdx != -1) {
      final path = line.substring(0, panelIdx);
      final tail = line.substring(panelIdx + panelPrefix.length);
      final appIdx = tail.lastIndexOf(appSep);
      if (appIdx != -1) {
        final panelVal = tail.substring(0, appIdx);
        final appVal = tail.substring(appIdx + appSep.length);
        final title = _humanizeDiffPath(
          sectionKey,
          path,
          stripListDevicePrefix: stripListDevicePrefix,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diffFieldTitle(title),
            const SizedBox(height: 6),
            _diffValueSideRow(StringConstants.panel, panelVal),
            const SizedBox(height: 4),
            _diffValueSideRow(StringConstants.app, appVal),
          ],
        );
      }
    }

    final listLen = RegExp(
      r'^(.*?): list length (\d+) \(panel\) vs (\d+) \(app\)$',
    ).firstMatch(line);
    if (listLen != null) {
      final path = listLen.group(1)!;
      final panelN = listLen.group(2)!;
      final appN = listLen.group(3)!;
      final title = _humanizeDiffPath(
        sectionKey,
        path,
        stripListDevicePrefix: stripListDevicePrefix,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _diffFieldTitle(title),
          const SizedBox(height: 6),
          Text(
            StringConstants.listLengthDiffers,
            style: StyleConstants.black12w500Style.copyWith(
              color: _textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          _diffValueSideRow(
            StringConstants.panel,
            '$panelN${StringConstants.entriesSuffix}',
          ),
          _diffValueSideRow(
            StringConstants.app,
            '$appN${StringConstants.entriesSuffix}',
          ),
        ],
      );
    }

    final onlyPanel = RegExp(r'^(.*?): only on panel · (.+)$').firstMatch(line);
    if (onlyPanel != null) {
      final path = onlyPanel.group(1)!;
      final val = onlyPanel.group(2)!;
      final title = _humanizeDiffPath(
        sectionKey,
        path,
        stripListDevicePrefix: stripListDevicePrefix,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _diffFieldTitle(title),
          const SizedBox(height: 6),
          Text(
            StringConstants.onlyOnPanel2,
            style: StyleConstants.black12w500Style.copyWith(
              color: _textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(val, style: StyleConstants.textDarkGray12w400Style),
        ],
      );
    }

    final onlyApp = RegExp(r'^(.*?): only in app · (.+)$').firstMatch(line);
    if (onlyApp != null) {
      final path = onlyApp.group(1)!;
      final val = onlyApp.group(2)!;
      final title = _humanizeDiffPath(
        sectionKey,
        path,
        stripListDevicePrefix: stripListDevicePrefix,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _diffFieldTitle(title),
          const SizedBox(height: 6),
          Text(
            StringConstants.onlyInApp2,
            style: StyleConstants.black12w500Style.copyWith(
              color: _textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(val, style: StyleConstants.textDarkGray12w400Style),
        ],
      );
    }

    return SelectableText(line, style: StyleConstants.textDarkGray12w400Style);
  }

  Widget _downloadCompareButton(bool working) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandRed,
          foregroundColor: ColorConstants.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: working ? null : widget.onDownloadAndCompare,
        child: Text(
          StringConstants.downloadCompare,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }

  Widget _diffDetailCard(
    ConfigCompareResult result,
    PeripheralConfigSection s,
  ) {
    final diffLines = result.diffLinesFor(s);
    final sectionKey = s.key;
    final isLBus = s == PeripheralConfigSection.lBus;
    final lBusCommsFaults =
        isLBus ? result.lBusCommsFaultBusNumbers : const <String>[];
    final lBusFieldDiffLines =
        isLBus ? _lBusFieldDiffLines(diffLines) : diffLines;
    final hasLBusFieldDiffs = lBusFieldDiffLines.isNotEmpty;
    final hasLBusCommsFaults = lBusCommsFaults.isNotEmpty;
    final visibleDiffLines =
        isLBus
            ? _filterDiffLinesForLBus(lBusFieldDiffLines, _selectedLBus)
            : diffLines;
    final fieldDiffCount = visibleDiffLines.length;
    final summaryText = () {
      if (diffLines.isEmpty) {
        return StringConstants.panelDataDiffersFromAppCache;
      }
      if (isLBus) {
        if (hasLBusCommsFaults && !hasLBusFieldDiffs) {
          return StringConstants
              .commsFaultDuringDownloadNoFieldDifferencesVsApp;
        }
        if (hasLBusCommsFaults && hasLBusFieldDiffs) {
          return '${StringConstants.commsFaultOnSomeBusesPrefix}$fieldDiffCount'
              '${StringConstants.changesOnLBusPrefix}$_selectedLBus';
        }
        if (fieldDiffCount == 0) {
          return '${StringConstants.noDifferencesOnLBusPrefix}$_selectedLBus';
        }
        return '$fieldDiffCount${StringConstants.changesOnLBusPrefix}$_selectedLBus';
      }
      return '${diffLines.length}${StringConstants.changesVsSavedAppDataSuffix}';
    }();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summaryText,
            style: StyleConstants.black12w500Style.copyWith(color: _textMuted),
          ),
          if (isLBus && hasLBusCommsFaults) ...[
            const SizedBox(height: 12),
            _lBusCommsFaultBanner(lBusCommsFaults),
          ],
          if (isLBus && hasLBusFieldDiffs) ...[
            const SizedBox(height: 12),
            _lBusSelector(),
          ],
          if (isLBus && (hasLBusCommsFaults || hasLBusFieldDiffs))
            const SizedBox(height: 12),
          if (diffLines.isEmpty)
            Text(
              StringConstants.noFieldLevelDetailAvailable,
              style: StyleConstants.textDarkGray12w400Style,
            )
          else if (isLBus && !hasLBusFieldDiffs)
            const SizedBox.shrink()
          else if (visibleDiffLines.isEmpty)
            Text(
              isLBus
                  ? StringConstants.selectAnotherLBusToViewItsDifferences
                  : StringConstants.noFieldLevelDetailAvailable,
              style: StyleConstants.textDarkGray12w400Style,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visibleDiffLines.length; i++) ...[
                  if (i > 0) ...[
                    Divider(height: 20, thickness: 1, color: _border),
                  ],
                  _diffLineWidget(
                    sectionKey,
                    visibleDiffLines[i],
                    stripListDevicePrefix: isLBus,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _mismatchTabsSection(ConfigCompareResult result) {
    final c = _tabController;
    if (c == null || c.length != result.mismatchedSections.length) {
      // One-frame gap while post-frame realign runs; avoid a spinner that can appear stuck.
      return const SizedBox.shrink();
    }

    final sections = result.mismatchedSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text(
          StringConstants.sectionsThatDiffer,
          style: StyleConstants.black16w700Style.copyWith(color: _textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          StringConstants.swipeOrTapATabToReviewPanelVsAppDifferences,
          style: StyleConstants.textMuted13w400Style.copyWith(
            color: _textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _surfaceMuted,
          ),
          child: TabBar(
            controller: c,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.5, color: _brandRed),
            ),
            labelColor: _brandRed,
            unselectedLabelColor: _textTabUnselected,
            labelStyle: StyleConstants.black13w600Style,
            unselectedLabelStyle: StyleConstants.black13w500Style,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs:
                sections
                    .map(
                      (s) => Tab(
                        height: 46,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            s.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          child: TabBarView(
            controller: c,
            children:
                sections
                    .map(
                      (s) => SingleChildScrollView(
                        controller: _resultController,
                        physics: const BouncingScrollPhysics(),
                        child: _diffDetailCard(result, s),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _resultBlock(ConfigCompareResult result) {
    if (result.errorMessage != null) {
      return _tileShell(
        title: StringConstants.result,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorConstants.errorBackgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.errorLightPink),
            ),
            child: Text(
              result.errorMessage!,
              style: StyleConstants.black14w500Style.copyWith(
                color: _brandRed,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    if (result.isAppCacheEmpty) {
      return _tileShell(
        title: StringConstants.result,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorConstants.infoBackgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.infoBlue),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    StringConstants.noConfigurationIsSavedInTheAppForThisDevice,
                    style: StyleConstants.colorFf1565C014w500Style,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!result.hasMismatch) {
      return _tileShell(
        title: StringConstants.result,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorConstants.successBackgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.colorFfc8E6C9),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    StringConstants
                        .allConfigurationSectionsMatchTheSavedAppData,
                    style: StyleConstants.successDark14w500Style,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (result.mismatchedSections.isEmpty) {
      return _tileShell(
        title: StringConstants.result,
        children: [
          Text(
            UiStrings.configurationDiffersNoSectionDetailMessage,
            style: StyleConstants.textMuted13w400Style.copyWith(
              color: _textMuted,
              height: 1.35,
            ),
          ),
        ],
      );
    }

    return _mismatchTabsSection(result);
  }

  Future<void> _onUpdateAppPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saveFuture = widget.onUsePanelDataInApp();
    if (!mounted) return;
    Navigator.of(context).pop();
    await saveFuture;
  }

  Widget _bottomActions(ConfigCompareResult? result, bool working) {
    if (result == null || result.errorMessage != null) {
      return const SizedBox.shrink();
    }

    if (result.isAppCacheEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandRed,
                foregroundColor: ColorConstants.white,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: working ? null : _onUpdateAppPressed,
              child: Text(
                StringConstants.updateApp,
                style: StyleConstants.primary16w600Style,
              ),
            ),
          ),
        ],
      );
    }

    if (!result.hasMismatch) {
      return const SizedBox.shrink();
    }

    if (_isLBusCommsFaultOnlyMismatch(result)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandRed,
                foregroundColor: ColorConstants.white,
                disabledBackgroundColor: Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed:
                  working
                      ? null
                      : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(context).pop();
                      },
              child: Text(
                StringConstants.okay,
                style: StyleConstants.white16w600Style,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandRed,
                    side: const BorderSide(color: _brandRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: working ? null : _onUpdateAppPressed,
                  child: Text(
                    StringConstants.updateApp,
                    style: StyleConstants.primary16w600Style,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandRed,
                    foregroundColor: ColorConstants.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed:
                      working
                          ? null
                          : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _confirmApplyLocal();
                          },
                  child: Text(
                    StringConstants.updatePanel,
                    style: StyleConstants.white15w600Style,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shown when panel vs app configuration matches (no mismatch, no error).
  Widget _matchNextCta(ConfigCompareResult? result, bool working) {
    if (result == null || result.errorMessage != null || result.hasMismatch) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              foregroundColor: ColorConstants.white,
              disabledBackgroundColor: Colors.grey.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed:
                working
                    ? null
                    : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).pop();
                    },
            child: Text(
              StringConstants.next,
              style: StyleConstants.white16w600Style,
            ),
          ),
        ),
      ],
    );
  }

  bool _showMismatchTabs(ConfigCompareResult? result) {
    return result != null &&
        result.errorMessage == null &&
        !result.isAppCacheEmpty &&
        result.hasMismatch &&
        result.mismatchedSections.isNotEmpty;
  }

  /// True when the "Compare with saved setup" intro tile is shown (dashboard flow).
  bool _showsCompareIntroTile({
    required bool showCta,
    required ConfigCompareResult? result,
  }) {
    if (!showCta) return false;
    if (result == null) return true;
    return !_showMismatchTabs(result);
  }

  double _resolveMaxSheetHeight({
    required double screenH,
    required bool showCta,
    required ConfigCompareResult? result,
    required bool working,
  }) {
    final showsIntro = _showsCompareIntroTile(showCta: showCta, result: result);

    if (showsIntro && result == null) {
      return screenH * (working ? 0.58 : 0.82);
    }

    if (result != null) {
      if (_showMismatchTabs(result)) {
        return screenH * 0.85;
      }
      if (result.isAppCacheEmpty) {
        return screenH * (showsIntro ? 0.52 : 0.48);
      }
      if (result.hasMismatch) {
        return screenH * (showsIntro ? 0.50 : 0.58);
      }
      return screenH * (showsIntro ? 0.62 : 0.40);
    }

    return showCta ? screenH * (working ? 0.38 : 0.32) : screenH * 0.48;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.compareResult.value;
    final working = widget.isWorking.value;
    _ensureTabControllerAligned(result);
    final showCta = widget.showDownloadAndCompareCta;
    final isDialog = widget.presentation == ConfigLogPresentationStyle.dialog;
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;
    final compactIntroLayout = showCta && result == null;

    var maxHeight = _resolveMaxSheetHeight(
      screenH: screenH,
      showCta: showCta,
      result: result,
      working: working,
    );
    if (isDialog) {
      final isGreenMatch =
          result != null && result.errorMessage == null && !result.hasMismatch;
      maxHeight = min(maxHeight, screenH * (isGreenMatch ? 0.37 : 0.57));
    }

    final card = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: isDialog ? min(560, screenW - 40) : double.infinity,
      ),
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
                    SvgPicture.asset(AssetConstants.bottomsheetLogo),
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstants.blackMaterial.withValues(
                              alpha: 0.06,
                            ),
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
                    mainAxisSize:
                        compactIntroLayout
                            ? MainAxisSize.min
                            : MainAxisSize.max,
                    children: [
                      _dragHandle(),
                      _title(StringConstants.configLog),
                      const SizedBox(height: 16),
                      if (compactIntroLayout)
                        _buildScrollableBody(
                          showCta: showCta,
                          result: result,
                          working: working,
                        )
                      else
                        Expanded(
                          child: _buildScrollableBody(
                            showCta: showCta,
                            result: result,
                            working: working,
                          ),
                        ),
                      SizedBox(height: 8),
                      _operationProgressBanner(working),
                      _bottomActions(result, working),
                      _matchNextCta(result, working),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDialog) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: ColorConstants.transparent,
        elevation: 0,
        child: card,
      );
    }

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: card,
      ),
    );
  }

  Widget _buildScrollableBody({
    required bool showCta,
    required ConfigCompareResult? result,
    required bool working,
  }) {
    return !showCta && result != null
        ? NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _cardController,
            physics: const BouncingScrollPhysics(),
            child: _resultBlock(result),
          ),
        )
        : NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child:
              _showMismatchTabs(result)
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      result == null
                          ? Flexible(
                            flex: 0,
                            fit: FlexFit.loose,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: _tileShell(
                                title: StringConstants.compareWithSavedSetup,
                                children: [
                                  Text(
                                    UiStrings.compareWithSavedSetupMessage,
                                    style: StyleConstants.textMuted13w400Style
                                        .copyWith(
                                          color: _textMuted,
                                          height: 1.4,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  _downloadCompareButton(working),
                                ],
                              ),
                            ),
                          )
                          : Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                if (working) return;
                                widget.onDownloadAndCompare();
                              },
                              child: Icon(
                                Icons.refresh_rounded,
                                color: _brandRed,
                                size: 24,
                              ),
                            ),
                          ),
                      if (result != null) Expanded(child: _resultBlock(result)),
                    ],
                  )
                  : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tileShell(
                          title: StringConstants.compareWithSavedSetup,
                          children: [
                            Text(
                              UiStrings.compareWithSavedSetupMessage,
                              style: StyleConstants.textMuted13w400Style
                                  .copyWith(color: _textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            _downloadCompareButton(working),
                          ],
                        ),
                        if (result != null) _resultBlock(result),
                      ],
                    ),
                  ),
        );
  }
}
