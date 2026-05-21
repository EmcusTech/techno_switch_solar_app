import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

class ModuleInfoBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;

  const ModuleInfoBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
  });

  @override
  State<ModuleInfoBottomSheet> createState() => _ModuleInfoBottomSheetState();
}

class _ModuleInfoBottomSheetState extends State<ModuleInfoBottomSheet> {
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
    final cached = await PeripheralSetupCache.loadModuleSetup(widget.deviceId);
    if (cached != null) {
      _applyCachedData(cached);
    }
  }

  void _applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    manager!.moduleNo.value = (data['moduleNo'] as num?)?.toInt() ?? 0;
    manager!.moduleEnabled.value = (data['enabled'] as bool?) ?? false;
    manager!.moduleProduct.value = (data['product'] as String?) ?? '';
    manager!.moduleId.value = (data['id'] as num?)?.toInt() ?? 0;
    manager!.moduleRevision.value = (data['revision'] as num?)?.toInt() ?? 0;
    manager!.moduleHardware.value = (data['hardware'] as String?) ?? '';
    manager!.moduleFirmware.value = (data['firmware'] as String?) ?? '';
    manager!.moduleDate.value = (data['date'] as String?) ?? '';
    manager!.moduleProtocol.value = (data['protocol'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    if (manager == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
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
                      left: 24.0,
                      right: 24.0,
                      top: 16.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        /// Drag Handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        /// Title
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Module Info',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D3D3D),
                            ),
                          ),
                        ),

                        /// Scrollable Content
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  if (manager != null)
                                    ValueListenableBuilder<String>(
                                      valueListenable:
                                          manager!.bleFirmwareVersion,
                                      builder:
                                          (_, version, __) => _disabledField(
                                            'BLE Firmware Version',
                                            version.isEmpty ? '-' : version,
                                          ),
                                    )
                                  else
                                    _disabledField('BLE Firmware Version', '-'),
                                  _reactiveTile('Module No', manager!.moduleNo),
                                  _reactiveTileBool(
                                    'Enabled',
                                    manager!.moduleEnabled,
                                  ),
                                  _reactiveTile(
                                    'Product',
                                    manager!.moduleProduct,
                                  ),
                                  _reactiveTile('ID', manager!.moduleId),
                                  _reactiveTile(
                                    'Revision',
                                    manager!.moduleRevision,
                                  ),
                                  _reactiveTile(
                                    'Hardware Version',
                                    manager!.moduleHardware,
                                  ),
                                  _reactiveTile(
                                    'Firmware Version',
                                    manager!.moduleFirmware,
                                  ),
                                  _reactiveTile(
                                    'Manufacturing Date',
                                    manager!.moduleDate,
                                  ),
                                  _reactiveTile(
                                    'Protocol No',
                                    manager!.moduleProtocol,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Download Button
                        SizedBox(
                          height: 48,
                          width: double.infinity,
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
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _disabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- Reactive Tile (Generic) ----------
  ///
  ///

  Widget _reactiveTile<T>(String label, ValueNotifier<T> notifier) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (_, value, __) {
        return _infoTile(label, value.toString());
      },
    );
  }

  /// ---------- Reactive Tile (Bool Yes/No) ----------

  Widget _reactiveTileBool(String label, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, value, __) {
        return _infoTile(label, value ? 'Yes' : 'No');
      },
    );
  }

  /// ---------- UI Tile ----------

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D0D0)),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
