import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_snapshot.dart';

/// Bottom sheet for bulk config sync: compare panel vs cached setup, then resolve mismatches.
class ConfigLogBottomSheet extends StatefulWidget {
  final String deviceId;
  final ValueNotifier<ConfigCompareResult?> compareResult;
  final ValueNotifier<bool> isWorking;
  final VoidCallback onDownloadAndCompare;
  final Future<void> Function() onUsePanelDataInApp;
  final VoidCallback onApplyLocalToPanel;

  const ConfigLogBottomSheet({
    super.key,
    required this.deviceId,
    required this.compareResult,
    required this.isWorking,
    required this.onDownloadAndCompare,
    required this.onUsePanelDataInApp,
    required this.onApplyLocalToPanel,
  });

  @override
  State<ConfigLogBottomSheet> createState() => _ConfigLogBottomSheetState();
}

class _ConfigLogBottomSheetState extends State<ConfigLogBottomSheet>
    with TickerProviderStateMixin {
  static const Color _textPrimary = Color(0xFF3D3D3D);
  static const Color _textMuted = Color(0xFF918F8F);
  static const Color _textTabUnselected = Color(0xFF6E6E6E);
  static const Color _brandRed = Color(0xFFEC1D24);
  static const Color _border = Color(0xFFDCDCDC);
  static const Color _surfaceMuted = Color(0xFFF8F8F8);

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    widget.compareResult.addListener(_onResultChanged);
    widget.isWorking.addListener(_onWorkingChanged);
    // Notifier does not fire on attach; align TabController before first build.
    _syncTabControllerFromResult(widget.compareResult.value);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    widget.compareResult.removeListener(_onResultChanged);
    widget.isWorking.removeListener(_onWorkingChanged);
    super.dispose();
  }

  void _syncTabControllerFromResult(ConfigCompareResult? result) {
    if (result != null &&
        result.errorMessage == null &&
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
    if (mounted) setState(() {});
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
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
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

  Future<void> _confirmApplyLocal() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apply saved configuration to the panel?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This will overwrite panel settings with the data stored in this app for this device.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  Widget _downloadCompareButton(bool working) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: working ? null : widget.onDownloadAndCompare,
        child:
            working
                ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
                : Text(
                  'Download & compare',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  Widget _diffDetailCard(
    ConfigCompareResult result,
    PeripheralConfigSection s,
  ) {
    final diffLines = result.diffLinesFor(s);
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
          Row(
            children: [
              Icon(
                Icons.difference_outlined,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.displayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            diffLines.isEmpty
                ? 'Panel data differs from app cache.'
                : '${diffLines.length} change(s) vs saved app data',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            diffLines.isEmpty
                ? 'No field-level detail available.'
                : diffLines.join('\n'),
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF444444),
            ),
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
          'Sections that differ',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Swipe or tap a tab to review panel vs app differences.',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
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
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
          height: MediaQuery.of(context).size.height * 0.25,
          child: TabBarView(
            controller: c,
            children:
                sections
                    .map(
                      (s) => SingleChildScrollView(
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
        title: 'Result',
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Text(
              result.errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _brandRed,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    if (!result.hasMismatch) {
      return _tileShell(
        title: 'Result',
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All configuration sections match the saved app data.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E7D32),
                      height: 1.35,
                    ),
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
        title: 'Result',
        children: [
          Text(
            'Configuration differs from saved app data, but no section detail is available.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _textMuted,
              height: 1.35,
            ),
          ),
        ],
      );
    }

    return _mismatchTabsSection(result);
  }

  Widget _bottomActions(ConfigCompareResult? result, bool working) {
    if (result == null || result.errorMessage != null || !result.hasMismatch) {
      return const SizedBox.shrink();
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
                  onPressed:
                      working
                          ? null
                          : () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await widget.onUsePanelDataInApp();
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          },
                  child: Text(
                    'Update App',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
                    foregroundColor: Colors.white,
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
                    'Update Panel',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

  bool _showMismatchTabs(ConfigCompareResult? result) {
    return result != null &&
        result.errorMessage == null &&
        result.hasMismatch &&
        result.mismatchedSections.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.compareResult.value;
    final working = widget.isWorking.value;
    _ensureTabControllerAligned(result);

    final maxHeight =
        result != null
            ? _showMismatchTabs(result)
                ? MediaQuery.of(context).size.height * 0.75
                : result.hasMismatch
                ? MediaQuery.of(context).size.height * 0.58
                : MediaQuery.of(context).size.height * 0.54
            : working
            ? MediaQuery.of(context).size.height * 0.40
            : MediaQuery.of(context).size.height * 0.35;

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
                _title('Config Log'),
                Expanded(
                  child: NotificationListener<UserScrollNotification>(
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
                                          title: 'Compare with saved setup',
                                          children: [
                                            Text(
                                              'Download the full configuration from the panel and compare it with data stored in this app for this device.',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
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
                                  Expanded(child: _resultBlock(result)),
                              ],
                            )
                            : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _tileShell(
                                    title: 'Compare with saved setup',
                                    children: [
                                      Text(
                                        'Download the full configuration from the panel and compare it with data stored in this app for this device.',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: _textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Visibility(
                                        visible: working,
                                        child: ValueListenableBuilder<String>(
                                          valueListenable: ble.processDesc,
                                          builder: (context, value, _) {
                                            return Column(
                                              children: [
                                                Text(
                                                  value,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF3D3D3D,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                              ],
                                            );
                                          },
                                        ),
                                      ),

                                      _downloadCompareButton(working),
                                    ],
                                  ),
                                  if (result != null) _resultBlock(result),
                                ],
                              ),
                            ),
                  ),
                ),
                _bottomActions(result, working),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
