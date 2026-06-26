import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
    manager!.moduleNo.value = (data[StringConstants.moduleno] as num?)?.toInt() ?? 0;
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
                            StringConstants.moduleInfo,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.textDark,
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
                                  _reactiveTile(StringConstants.moduleNo, manager!.moduleNo),
                                  _reactiveTileBool(
                                    StringConstants.enabled,
                                    manager!.moduleEnabled,
                                  ),
                                  _reactiveTile(
                                    StringConstants.product,
                                    manager!.moduleProduct,
                                  ),
                                  _reactiveTile(StringConstants.id, manager!.moduleId),
                                  _reactiveTile(
                                    StringConstants.revision,
                                    manager!.moduleRevision,
                                  ),
                                  _reactiveTile(
                                    StringConstants.hardwareVersion,
                                    manager!.moduleHardware,
                                  ),
                                  _reactiveTile(
                                    StringConstants.firmwareVersion,
                                    manager!.moduleFirmware,
                                  ),
                                  _reactiveTile(
                                    StringConstants.manufacturingDate,
                                    manager!.moduleDate,
                                  ),
                                  _reactiveTile(
                                    StringConstants.protocolNo,
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
                              foregroundColor: ColorConstants.primary,
                              side: const BorderSide(color: ColorConstants.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: widget.onDownload,
                            child: Text(
                              StringConstants.download,
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
              color: ColorConstants.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderLight),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorConstants.textDark,
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
        return _infoTile(label, value ? StringConstants.yes : StringConstants.no);
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
              color: ColorConstants.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderLight),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorConstants.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
