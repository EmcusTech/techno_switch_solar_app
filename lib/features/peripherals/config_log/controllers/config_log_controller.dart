import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_diff_labels.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';

enum ConfigLogPresentationStyle { bottomSheet, dialog }

/// Presentation and diff-view state for the Config Log bottom sheet.
///
/// Compare orchestration (download, apply, password popup) stays on the parent
/// dashboard / post-connect flow via callbacks passed into the View. This
/// controller owns tab alignment, L-Bus selection, and diff parsing helpers.
class ConfigLogController extends GetxController
    with GetSingleTickerProviderStateMixin {
  ConfigLogController({
    required this.compareResult,
    required this.isWorking,
    this.showDownloadAndCompareCta = true,
    this.presentation = ConfigLogPresentationStyle.bottomSheet,
  });

  final ValueNotifier<ConfigCompareResult?> compareResult;
  final ValueNotifier<bool> isWorking;
  final bool showDownloadAndCompareCta;
  final ConfigLogPresentationStyle presentation;

  static final RegExp _listIndexFromPathRe = RegExp(r'^\[(\d+)\]');

  TabController? tabController;
  int selectedLBus = 1;

  ConfigCompareResult? get result => compareResult.value;
  bool get working => isWorking.value;

  @override
  void onInit() {
    super.onInit();
    compareResult.addListener(_onCompareResultChanged);
    isWorking.addListener(_onWorkingChanged);
    syncTabControllerFromResult(compareResult.value);
    syncSelectedLBusFromResult(compareResult.value);
  }

  @override
  void onClose() {
    compareResult.removeListener(_onCompareResultChanged);
    isWorking.removeListener(_onWorkingChanged);
    tabController?.dispose();
    tabController = null;
    super.onClose();
  }

  void _onCompareResultChanged() {
    syncTabControllerFromResult(compareResult.value);
    syncSelectedLBusFromResult(compareResult.value);
    update();
  }

  void _onWorkingChanged() => update();

  void setSelectedLBus(int bus) {
    selectedLBus = bus;
    update();
  }

  void syncTabControllerFromResult(ConfigCompareResult? result) {
    if (showMismatchTabs(result)) {
      final length = result!.mismatchedSections.length;
      if (tabController != null && tabController!.length == length) {
        return;
      }
      tabController?.dispose();
      tabController = TabController(length: length, vsync: this);
    } else {
      tabController?.dispose();
      tabController = null;
    }
  }

  void syncSelectedLBusFromResult(ConfigCompareResult? result) {
    if (result == null) return;
    final lines = lBusFieldDiffLines(
      result.diffLinesFor(PeripheralConfigSection.lBus),
    );
    for (final line in lines) {
      final index = listIndexFromDiffLine(line);
      if (index != null) {
        selectedLBus = index + 1;
        return;
      }
    }
  }

  int? listIndexFromDiffLine(String line) {
    final path = line.split(':').first.trim();
    final match = _listIndexFromPathRe.firstMatch(path);
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }

  List<String> lBusFieldDiffLines(List<String> lines) {
    return lines.where((line) => listIndexFromDiffLine(line) != null).toList();
  }

  bool isLBusCommsFaultOnlyMismatch(ConfigCompareResult result) {
    return result.lBusCommsFaultBusNumbers.isNotEmpty &&
        result.mismatchedSections.length == 1 &&
        result.mismatchedSections.single == PeripheralConfigSection.lBus &&
        lBusFieldDiffLines(
          result.diffLinesFor(PeripheralConfigSection.lBus),
        ).isEmpty;
  }

  List<String> filterDiffLinesForLBus(List<String> lines, int selectedBus) {
    final index = selectedBus - 1;
    return lines.where((line) {
      final listIndex = listIndexFromDiffLine(line);
      if (listIndex == null) return true;
      return listIndex == index;
    }).toList();
  }

  String humanizeDiffPath(
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

  String diffSummaryText(
    ConfigCompareResult result,
    PeripheralConfigSection section,
  ) {
    final diffLines = result.diffLinesFor(section);
    final isLBus = section == PeripheralConfigSection.lBus;
    final lBusFieldDiffLines =
        isLBus ? this.lBusFieldDiffLines(diffLines) : diffLines;
    final hasLBusFieldDiffs = lBusFieldDiffLines.isNotEmpty;
    final hasLBusCommsFaults =
        isLBus ? result.lBusCommsFaultBusNumbers.isNotEmpty : false;
    final visibleDiffLines =
        isLBus
            ? filterDiffLinesForLBus(lBusFieldDiffLines, selectedLBus)
            : diffLines;
    final fieldDiffCount = visibleDiffLines.length;

    if (diffLines.isEmpty) {
      return StringConstants.panelDataDiffersFromAppCache;
    }
    if (isLBus) {
      if (hasLBusCommsFaults && !hasLBusFieldDiffs) {
        return StringConstants.commsFaultDuringDownloadNoFieldDifferencesVsApp;
      }
      if (hasLBusCommsFaults && hasLBusFieldDiffs) {
        return '${StringConstants.commsFaultOnSomeBusesPrefix}$fieldDiffCount'
            '${StringConstants.changesOnLBusPrefix}$selectedLBus';
      }
      if (fieldDiffCount == 0) {
        return '${StringConstants.noDifferencesOnLBusPrefix}$selectedLBus';
      }
      return '$fieldDiffCount${StringConstants.changesOnLBusPrefix}$selectedLBus';
    }
    return '${diffLines.length}${StringConstants.changesVsSavedAppDataSuffix}';
  }

  bool tabControllerMatchesResult(ConfigCompareResult? result) {
    if (!showMismatchTabs(result)) return tabController == null;
    final r = result!;
    final c = tabController;
    return c != null && c.length == r.mismatchedSections.length;
  }

  /// Re-align when [ValueNotifier] skips notification or ordering leaves us stale.
  void ensureTabControllerAligned(ConfigCompareResult? result) {
    if (tabControllerMatchesResult(result)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (tabControllerMatchesResult(compareResult.value)) return;
      syncTabControllerFromResult(compareResult.value);
      update();
    });
  }

  bool showMismatchTabs(ConfigCompareResult? result) {
    return result != null &&
        result.errorMessage == null &&
        !result.isAppCacheEmpty &&
        result.hasMismatch &&
        result.mismatchedSections.isNotEmpty;
  }

  bool showsCompareIntroTile({required ConfigCompareResult? result}) {
    if (!showDownloadAndCompareCta) return false;
    if (result == null) return true;
    return !showMismatchTabs(result);
  }

  double resolveMaxSheetHeight({
    required double screenH,
    required ConfigCompareResult? result,
    required bool working,
  }) {
    final showsIntro = showsCompareIntroTile(result: result);

    if (showsIntro && result == null) {
      return screenH * (working ? 0.58 : 0.82);
    }

    if (result != null) {
      if (showMismatchTabs(result)) {
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

    return showDownloadAndCompareCta
        ? screenH * (working ? 0.38 : 0.32)
        : screenH * 0.48;
  }
}
