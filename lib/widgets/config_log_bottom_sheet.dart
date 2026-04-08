import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/config_log_ble_runner.dart';
import 'package:techno_switch_solar_app/utils/config_diff_display_labels.dart';
import 'package:techno_switch_solar_app/utils/config_map_diff.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_bundle.dart';
import 'package:techno_switch_solar_app/utils/peripheral_hydrate_from_bundle.dart';

class _SectionDiff {
  const _SectionDiff(this.title, this.diffs);
  final String title;
  final List<ConfigMapDiff> diffs;
}

/// Compares panel configuration (after BLE download) to app cache or factory defaults.
class ConfigLogBottomSheet extends StatefulWidget {
  const ConfigLogBottomSheet({super.key, required this.deviceId});

  final String deviceId;

  @override
  State<ConfigLogBottomSheet> createState() => _ConfigLogBottomSheetState();
}

class _ConfigLogBottomSheetState extends State<ConfigLogBottomSheet> {
  final BleLogController _ble = Get.find<BleLogController>();

  bool _loading = false;
  String? _error;
  List<_SectionDiff>? _sections;
  PeripheralConfigBundle? _baseline;

  static const Color _brandRed = Color(0xFFEC1D24);
  static const Color _textPrimary = Color(0xFF3D3D3D);
  static const Color _textMuted = Color(0xFF918F8F);
  static const Color _surfaceMuted = Color(0xFFF8F8F8);
  static const Color _borderLight = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _runCompare();
  }

  Future<void> _runCompare() async {
    setState(() {
      _loading = true;
      _error = null;
      _sections = null;
    });
    try {
      await downloadFullPanelConfiguration(_ble);
      final panel = PeripheralConfigBundle.fromBleManager(_ble.bleManager);
      final baseline = await PeripheralConfigBundle.baselineForDevice(
        widget.deviceId,
      );
      final sections = <_SectionDiff>[
        _SectionDiff(
          'Relays',
          labelSectionDiffs(
            'Relays',
            diffConfigValues(baseline.relays, panel.relays),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Inputs',
          labelSectionDiffs(
            'Inputs',
            diffConfigValues(baseline.inputs, panel.inputs),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Zones',
          labelSectionDiffs(
            'Zones',
            diffConfigValues(baseline.zones, panel.zones),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Sounders',
          labelSectionDiffs(
            'Sounders',
            diffConfigValues(baseline.sounders, panel.sounders),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Module Info',
          diffConfigValues(baseline.module, panel.module),
        ),
        _SectionDiff(
          'L-Bus',
          diffConfigValues(baseline.lBusBuses, panel.lBusBuses),
        ),
        _SectionDiff(
          'Ext Out',
          labelSectionDiffs(
            'Ext Out',
            diffConfigValues(baseline.extOut, panel.extOut),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Service Due',
          labelSectionDiffs(
            'Service Due',
            diffConfigValues(baseline.serviceDue, panel.serviceDue),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Access Code',
          labelSectionDiffs(
            'Access Code',
            diffConfigValues(baseline.accessCodes, panel.accessCodes),
            baseline,
            panel,
          ),
        ),
        _SectionDiff(
          'Panel Info',
          diffConfigValues(baseline.panelInfo, panel.panelInfo),
        ),
        _SectionDiff(
          'General',
          diffConfigValues(baseline.general, panel.general),
        ),
        _SectionDiff(
          'Diagnostics',
          diffConfigValues(
            baseline.diagnostics,
            panel.diagnostics,
            diagnosticsMode: true,
          ),
        ),
        _SectionDiff(
          'Walk Test',
          labelSectionDiffs(
            'Walk Test',
            diffConfigValues(baseline.walkTest, panel.walkTest),
            baseline,
            panel,
          ),
        ),
      ];
      if (!mounted) return;
      setState(() {
        _loading = false;
        _baseline = baseline;
        _sections = sections;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateAppFromPanel() async {
    final panel = PeripheralConfigBundle.fromBleManager(_ble.bleManager);
    await savePeripheralBundleToCache(widget.deviceId, panel);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('App configuration cache updated from the panel.'),
      ),
    );
  }

  Future<void> _pushBaselineToPanel() async {
    final b = _baseline;
    if (b == null) return;
    setState(() => _loading = true);
    try {
      hydrateBleManagerFromBundle(_ble.bleManager, b);
      await applyBaselineToPanel(_ble);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Saved configuration applied to the panel.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
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
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _description() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Compared to saved app data, or factory defaults when nothing is saved yet. '
        'Diagnostics values are live readings; applying only updates programmable sections.',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: _textMuted,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _diffLineCard(ConfigMapDiff d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.path,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saved / default',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d.local,
              style: GoogleFonts.inter(fontSize: 12, color: _textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Panel',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d.remote,
              style: GoogleFonts.inter(fontSize: 12, color: _textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionExpansionTile(_SectionDiff s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderLight),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            iconColor: _brandRed,
            collapsedIconColor: _brandRed,
            title: Text(
              s.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: _textPrimary,
              ),
            ),
            subtitle: Text(
              '${s.diffs.length} difference${s.diffs.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
            ),
            children: [for (final d in s.diffs) _diffLineCard(d)],
          ),
        ),
      ),
    );
  }

  Widget _successBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No differences. Panel matches your baseline.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBDEE1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: _brandRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brandRed));
    }
    if (_error != null) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        child: _errorBanner(_error!),
      );
    }
    if (_sections == null) {
      return const SizedBox.shrink();
    }

    final allMatch = _sections!.every((s) => s.diffs.isEmpty);

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final s in _sections!)
              if (s.diffs.isNotEmpty) _sectionExpansionTile(s),
            if (allMatch) _successBanner(),
          ],
        ),
      ),
    );
  }

  Widget _updateAppButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandRed,
          side: const BorderSide(color: _brandRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: _loading ? null : _updateAppFromPanel,
        child: Text(
          'Update App',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _updatePanelButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: _loading ? null : _pushBaselineToPanel,
        child: Text(
          'Update Panel',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return SizedBox(
      height: 44,
      child: TextButton(
        style: TextButton.styleFrom(foregroundColor: _textMuted),
        onPressed: _loading ? null : _runCompare,
        child: Text(
          'Refresh compare',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

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
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dragHandle(),
              _title('Configuration sync'),
              _description(),
              Expanded(child: _buildScrollableBody()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _updateAppButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _updatePanelButton()),
                ],
              ),
              _refreshButton(),
            ],
          ),
        ),
      ),
    );
  }
}
