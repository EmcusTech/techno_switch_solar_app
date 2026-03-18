import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

class PanelInfoBottomSheet extends StatefulWidget {
  final VoidCallback onDownload;
  final VoidCallback onApply;

  const PanelInfoBottomSheet({
    super.key,
    required this.onDownload,
    required this.onApply,
  });

  @override
  State<PanelInfoBottomSheet> createState() => _PanelInfoBottomSheetState();
}

class _PanelInfoBottomSheetState extends State<PanelInfoBottomSheet> {
  BleManager? manager;

  int _expandedTileCount = 0;

  /// Controllers
  final panelIdController = TextEditingController();
  final panelNameController = TextEditingController();

  final yearController = TextEditingController();
  final monthController = TextEditingController();
  final dayController = TextEditingController();
  final hourController = TextEditingController();
  final minuteController = TextEditingController();
  final secondController = TextEditingController();

  final delayController = TextEditingController();

  bool useMobileTime = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    panelIdController.dispose();
    panelNameController.dispose();
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();
    delayController.dispose();
    super.dispose();
  }

  /// ───────── TIME LOGIC ─────────

  void _startLiveTime() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      yearController.text = now.year.toString();
      monthController.text = now.month.toString().padLeft(2, '0');
      dayController.text = now.day.toString().padLeft(2, '0');
      hourController.text = now.hour.toString().padLeft(2, '0');
      minuteController.text = now.minute.toString().padLeft(2, '0');
      secondController.text = now.second.toString().padLeft(2, '0');
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                _title("Panel Information"),

                Expanded(
                  child: NotificationListener<UserScrollNotification>(
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
                        children: [
                          _panelInfoTile(),
                          _dateTimeTile(),
                          _eventReminderTile(),
                        ],
                      ),
                    ),
                  ),
                ),

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
        ),
      ),
    );
  }

  // ───────── TILES ─────────

  Widget _panelInfoTile() {
    return _tileWrapper(
      title: "Panel Info",
      children: [
        _textField("Panel ID", panelIdController),
        _textField("Panel Name", panelNameController),
      ],
    );
  }

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
        _numberField("Year", yearController),
        _numberField("Month", monthController),
        _numberField("Day", dayController),
        _numberField("Hour", hourController),
        _numberField("Minute", minuteController),
        _numberField("Second", secondController),
      ],
    );
  }

  Widget _eventReminderTile() {
    return _tileWrapper(
      title: "Event Reminder",
      children: [_numberField("Delay (s)", delayController)],
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

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          TextField(controller: controller, decoration: _inputDecoration()),
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
        onPressed: widget.onDownload,
        child: Text(
          'Download',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
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
        onPressed: widget.onApply,
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
