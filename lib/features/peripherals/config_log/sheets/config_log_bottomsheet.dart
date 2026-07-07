import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/features/peripherals/config_log/controllers/config_log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/widgets/common/dropdown.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

export 'package:techno_switch_solar_app/features/peripherals/config_log/controllers/config_log_controller.dart'
    show ConfigLogPresentationStyle;

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

class _ConfigLogBottomSheetState extends State<ConfigLogBottomSheet> {
  final BleManager ble = Get.find<BleManager>();
  late final ConfigLogController controller;
  final ScrollController _resultController = ScrollController();
  final ScrollController _cardController = ScrollController();

  static const Color _textPrimary = ColorConstants.textDark;
  static const Color _textMuted = ColorConstants.textMuted;
  static const Color _textTabUnselected = ColorConstants.textSubtle;
  static const Color _brandRed = ColorConstants.primary;
  static const Color _border = ColorConstants.borderMuted;
  static const Color _surfaceMuted = ColorConstants.surfaceLight;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ConfigLogController(
        compareResult: widget.compareResult,
        isWorking: widget.isWorking,
        showDownloadAndCompareCta: widget.showDownloadAndCompareCta,
        presentation: widget.presentation,
      ),
    );
    _resultController.addListener(_syncOuterScroll);
  }

  @override
  void dispose() {
    _resultController.removeListener(_syncOuterScroll);
    _resultController.dispose();
    _cardController.dispose();
    Get.delete<ConfigLogController>();
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
    ConfigLogController c,
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
        final title = c.humanizeDiffPath(
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
      final title = c.humanizeDiffPath(
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
      final title = c.humanizeDiffPath(
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
      final title = c.humanizeDiffPath(
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

  Widget _lBusSelector(ConfigLogController c) {
    return DropdownWidget(
      label: StringConstants.selectLBus,
      value: 'L-Bus ${c.selectedLBus}',
      items: List.generate(31, (i) => 'L-Bus ${i + 1}'),
      dropdownListHeight: MediaQuery.sizeOf(context).height * 0.2,
      enableSearch: false,
      onChanged: (value) {
        final number = int.parse(value.split(' ').last);
        c.setSelectedLBus(number);
      },
    );
  }

  Widget _diffDetailCard(
    ConfigLogController c,
    ConfigCompareResult result,
    PeripheralConfigSection s,
  ) {
    final diffLines = result.diffLinesFor(s);
    final sectionKey = s.key;
    final isLBus = s == PeripheralConfigSection.lBus;
    final lBusCommsFaults =
        isLBus ? result.lBusCommsFaultBusNumbers : const <String>[];
    final lBusFieldDiffLines =
        isLBus ? c.lBusFieldDiffLines(diffLines) : diffLines;
    final hasLBusFieldDiffs = lBusFieldDiffLines.isNotEmpty;
    final hasLBusCommsFaults = lBusCommsFaults.isNotEmpty;
    final visibleDiffLines =
        isLBus
            ? c.filterDiffLinesForLBus(lBusFieldDiffLines, c.selectedLBus)
            : diffLines;

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
            c.diffSummaryText(result, s),
            style: StyleConstants.black12w500Style.copyWith(color: _textMuted),
          ),
          if (isLBus && hasLBusCommsFaults) ...[
            const SizedBox(height: 12),
            _lBusCommsFaultBanner(lBusCommsFaults),
          ],
          if (isLBus && hasLBusFieldDiffs) ...[
            const SizedBox(height: 12),
            _lBusSelector(c),
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
                    c,
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

  Widget _mismatchTabsSection(
    ConfigLogController c,
    ConfigCompareResult result,
  ) {
    final tabCtrl = c.tabController;
    if (tabCtrl == null || tabCtrl.length != result.mismatchedSections.length) {
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
            controller: tabCtrl,
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
            controller: tabCtrl,
            children:
                sections
                    .map(
                      (s) => SingleChildScrollView(
                        controller: _resultController,
                        physics: const BouncingScrollPhysics(),
                        child: _diffDetailCard(c, result, s),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _resultBlock(ConfigLogController c, ConfigCompareResult result) {
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

    return _mismatchTabsSection(c, result);
  }

  Future<void> _onUpdateAppPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saveFuture = widget.onUsePanelDataInApp();
    if (!mounted) return;
    Navigator.of(context).pop();
    await saveFuture;
  }

  Widget _bottomActions(
    ConfigLogController c,
    ConfigCompareResult? result,
    bool working,
  ) {
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
                style: StyleConstants.white16w600Style,
              ),
            ),
          ),
        ],
      );
    }

    if (!result.hasMismatch) {
      return const SizedBox.shrink();
    }

    if (c.isLBusCommsFaultOnlyMismatch(result)) {
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

  Widget _buildScrollableBody({
    required ConfigLogController c,
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
            child: _resultBlock(c, result),
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
              c.showMismatchTabs(result)
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
                      if (result != null)
                        Expanded(child: _resultBlock(c, result)),
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
                        if (result != null) _resultBlock(c, result),
                      ],
                    ),
                  ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ConfigLogController>(
      init: controller,
      builder: (c) {
        final result = c.result;
        final working = c.working;
        c.ensureTabControllerAligned(result);
        final showCta = widget.showDownloadAndCompareCta;
        final isDialog =
            widget.presentation == ConfigLogPresentationStyle.dialog;
        final screenH = MediaQuery.sizeOf(context).height;
        final screenW = MediaQuery.sizeOf(context).width;
        final compactIntroLayout = showCta && result == null;

        var maxHeight = c.resolveMaxSheetHeight(
          screenH: screenH,
          result: result,
          working: working,
        );
        if (isDialog) {
          final isGreenMatch =
              result != null &&
              result.errorMessage == null &&
              !result.hasMismatch;
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
                              c: c,
                              showCta: showCta,
                              result: result,
                              working: working,
                            )
                          else
                            Expanded(
                              child: _buildScrollableBody(
                                c: c,
                                showCta: showCta,
                                result: result,
                                working: working,
                              ),
                            ),
                          const SizedBox(height: 8),
                          _operationProgressBanner(working),
                          _bottomActions(c, result, working),
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
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
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
      },
    );
  }
}
