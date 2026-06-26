import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

class PanelInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;
  final bool embedInCreateFlow;

  const PanelInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  @override
  State<PanelInfoBottomSheet> createState() => PanelInfoBottomSheetState();
}

class PanelInfoBottomSheetState extends State<PanelInfoBottomSheet> {
  BleManager? manager;

  int _expandedTileCount = 0;

  final PanelInfoConfig config = PanelInfoConfig();

  bool useMobileTime = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }

    _loadData();
    widget.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.refreshTrigger.removeListener(_onRefreshTriggered);
    config.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadFromManager();
  }

  Future<void> _loadData() async {
    final cached = await PeripheralSetupCache.loadPanelInfoSetup(
      widget.deviceId,
    );
    if (cached != null) {
      _applyCachedData(cached);
      if (mounted) setState(() {});
      return;
    }
    _loadFromManager();
  }

  void _applyCachedData(Map<String, dynamic> data) {
    config.panelIdController.text =
        (data['panelId'] as num?)?.toString() ?? '0';
    config.panelNameController.text = (data['panelName'] as String?) ?? '';
    config.yearController.text = (data['year'] as num?)?.toString() ?? '0';
    config.monthController.text = (data['month'] as num?)?.toString() ?? '0';
    config.dayController.text = (data['day'] as num?)?.toString() ?? '0';
    config.hourController.text = (data['hour'] as num?)?.toString() ?? '0';
    config.minuteController.text = (data['minute'] as num?)?.toString() ?? '0';
    config.secondController.text = (data['second'] as num?)?.toString() ?? '0';
    config.delayController.text = (data['delay'] as num?)?.toString() ?? '0';
    useMobileTime = (data['useMobileTime'] as bool?) ?? true;
    if (useMobileTime) {
      _startLiveTime();
    }
  }

  void _loadFromManager() {
    if (manager == null) return;
    config.panelIdController.text = manager!.panelInfoPanelNo.value.toString();
    config.panelNameController.text = manager!.panelInfoPanelName.value;
    config.yearController.text = manager!.panelInfoYear.value.toString();
    config.monthController.text = manager!.panelInfoMonth.value
        .toString()
        .padLeft(2, '0');
    config.dayController.text = manager!.panelInfoDay.value.toString().padLeft(
      2,
      '0',
    );
    config.hourController.text = manager!.panelInfoHour.value
        .toString()
        .padLeft(2, '0');
    config.minuteController.text = manager!.panelInfoMinute.value
        .toString()
        .padLeft(2, '0');
    config.secondController.text = manager!.panelInfoSecond.value
        .toString()
        .padLeft(2, '0');
    config.delayController.text =
        manager!.panelInfoEventReminderDelay.value.toString();
    if (mounted) setState(() {});
  }

  /// ───────── TIME LOGIC ─────────

  void _startLiveTime() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();

      config.yearController.text = now.year.toString();
      config.monthController.text = now.month.toString().padLeft(2, '0');
      config.dayController.text = now.day.toString().padLeft(2, '0');
      config.hourController.text = now.hour.toString().padLeft(2, '0');
      config.minuteController.text = now.minute.toString().padLeft(2, '0');
      config.secondController.text = now.second.toString().padLeft(2, '0');
      setState(() {});
    });
  }

  void _stopLiveTime() {
    _timer?.cancel();
  }

  void _toggleMobileTime(bool value) {
    setState(() {
      useMobileTime = value;

      if (value) {
        _startLiveTime();
      } else {
        _stopLiveTime();
        _loadFromManager();
      }
    });
  }

  Widget _scrollContent() {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          FocusScope.of(context).unfocus();
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embedInCreateFlow) _title("Panel Information"),
            _panelInfoTile(),
            _dateTimeTile(),
            _eventReminderTile(),
          ],
        ),
      ),
    );
  }

  Future<bool> commitLocal() async {
    if (manager == null || !_isValidPanelInfo()) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    _pushToManager();
    await PanelConfigCacheSync.savePanelInfo(
      manager!,
      widget.deviceId,
      widget.refreshTrigger,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (widget.embedInCreateFlow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: _scrollContent())],
      );
    }

    final maxHeight =
        _expandedTileCount > 0 ? screenHeight * 0.80 : screenHeight * 0.50;

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
                          _title("Panel Info"),
                          Expanded(child: _scrollContent()),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _downloadButton()),
                              const SizedBox(width: 12),
                              Expanded(child: _applyButton()),
                            ],
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

  // ───────── TILES ─────────

  Widget _panelInfoTile() {
    return _tileWrapper(
      title: "Panel Info",
      children: [
        _textField(
          "Panel No",
          config.panelIdController,
          isNumeric: true,
          maxLength: 2,
        ),
        _textField("Panel Name", config.panelNameController, maxLength: 21),
      ],
    );
  }

  /// Clock fields are still edited and applied here; bulk Config Log compare omits
  /// them so routine time drift does not mark Panel Info as mismatched.
  Widget _dateTimeTile() {
    return _tileWrapper(
      title: "Date & Time",
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Use Mobile Date & Time",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Switch(value: useMobileTime, onChanged: _toggleMobileTime),
          ],
        ),
        _numberField("Year", config.yearController, maxLength: 4),
        _numberField("Month", config.monthController, maxLength: 2),
        _numberField("Day", config.dayController, maxLength: 2),
        _numberField("Hour", config.hourController, maxLength: 2),
        _numberField("Minute", config.minuteController, maxLength: 2),
        _numberField("Second", config.secondController, maxLength: 2),
      ],
    );
  }

  Widget _eventReminderTile() {
    return _tileWrapper(
      title: "Event Reminder",
      children: [
        _numberField("Delay (s)", config.delayController, maxLength: 3),
      ],
    );
  }

  // ───────── TILE WRAPPER ─────────

  Widget _tileWrapper({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCDCDC)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedTileCount += expanded ? 1 : -1;
              });
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D3D3D),
              ),
            ),
            children: [...children, const SizedBox(height: 14)],
          ),
        ),
      ),
    );
  }

  // ───────── INPUTS ─────────

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            maxLength: maxLength,
            buildCounter:
                maxLength == null
                    ? null
                    : (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      if (!isFocused) return null;
                      final max = maxLength ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$currentLength / $max',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                currentLength == max
                                    ? const Color(0xFFEC1D24)
                                    : Colors.grey,
                          ),
                        ),
                      );
                    },
            inputFormatters: [
              if (isNumeric) FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFEC1D24), width: 2),
      ),
    );
  }

  // ───────── COMMON UI ─────────

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
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEC1D24),
          side: const BorderSide(color: Color(0xFFEC1D24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          'Download',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  bool _isValidPanelInfo() {
    // Panel No: 1–31
    final panelNo = int.tryParse(config.panelIdController.text);
    if (panelNo == null || panelNo < 1 || panelNo > 31) return false;

    // Panel Name: max 21 chars, non-empty
    final panelName = config.panelNameController.text.trim();
    if (panelName.isEmpty) return false;
    if (panelName.length > 21) return false;

    // DateTime: year 1970–9999, month 1–12, day 1–31, hour 0–23, minute 0–59, second 0–59
    if (config.yearController.text.isEmpty ||
        config.monthController.text.isEmpty ||
        config.dayController.text.isEmpty ||
        config.hourController.text.isEmpty ||
        config.minuteController.text.isEmpty ||
        config.secondController.text.isEmpty) {
      return false;
    }

    final year = int.tryParse(config.yearController.text) ?? 0;
    final month = int.tryParse(config.monthController.text) ?? 0;
    final day = int.tryParse(config.dayController.text) ?? 0;
    final hour = int.tryParse(config.hourController.text) ?? 0;
    final minute = int.tryParse(config.minuteController.text) ?? 0;
    final second = int.tryParse(config.secondController.text) ?? 0;

    if (year < 1970 || year > 9999) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (second < 0 || second > 59) return false;

    try {
      final dt = DateTime(year, month, day, hour, minute, second);
      if (dt.year != year || dt.month != month || dt.day != day) return false;
    } catch (_) {
      return false;
    }

    // Event Reminder Delay: 10–600
    final delay = int.tryParse(config.delayController.text);
    if (delay == null || delay < 10 || delay > 600) return false;

    return true;
  }

  void _pushToManager() {
    if (manager == null) return;
    manager!.panelInfoPanelNo.value =
        int.tryParse(config.panelIdController.text) ?? 0;
    manager!.panelInfoPanelName.value = config.panelNameController.text;
    manager!.panelInfoYear.value =
        int.tryParse(config.yearController.text) ?? 0;
    manager!.panelInfoMonth.value =
        int.tryParse(config.monthController.text) ?? 0;
    manager!.panelInfoDay.value = int.tryParse(config.dayController.text) ?? 0;
    manager!.panelInfoHour.value =
        int.tryParse(config.hourController.text) ?? 0;
    manager!.panelInfoMinute.value =
        int.tryParse(config.minuteController.text) ?? 0;
    manager!.panelInfoSecond.value =
        int.tryParse(config.secondController.text) ?? 0;
    manager!.panelInfoEventReminderDelay.value =
        int.tryParse(config.delayController.text) ?? 0;
  }

  Widget _applyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1D24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            _isValidPanelInfo()
                ? () async {
                  if (await commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          'Apply',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ───────────────── MODEL ─────────────────

class PanelInfoConfig {
  final TextEditingController panelIdController = TextEditingController();
  final TextEditingController panelNameController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minuteController = TextEditingController();
  final TextEditingController secondController = TextEditingController();
  final TextEditingController delayController = TextEditingController();

  void dispose() {
    panelIdController.dispose();
    panelNameController.dispose();
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();
    delayController.dispose();
  }
}
