import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/module_info_controller.dart';
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
  late final ModuleInfoController controller;

  /// Module info has no external refresh trigger; the base controller still
  /// expects one, so the View owns a throwaway notifier.
  final ValueNotifier<int> _refreshTrigger = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ModuleInfoController(
        deviceId: widget.deviceId,
        refreshTrigger: _refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<ModuleInfoController>();
    _refreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return GetBuilder<ModuleInfoController>(
      init: controller,
      builder: (c) {
        final manager = c.manager;
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
                                  color: ColorConstants.blackMaterial
                                      .withValues(alpha: 0.06),
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
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
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
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    children: [
                                      ValueListenableBuilder<String>(
                                        valueListenable: manager.bleFirmwareVersion,
                                        builder: (_, version, __) =>
                                            _disabledField(
                                          'BLE Firmware Version',
                                          version.isEmpty ? '-' : version,
                                        ),
                                      ),
                                      _reactiveTile(
                                          StringConstants.moduleNo, manager.moduleNo),
                                      _reactiveTileBool(
                                        StringConstants.enabled,
                                        manager.moduleEnabled,
                                      ),
                                      _reactiveTile(
                                        StringConstants.product,
                                        manager.moduleProduct,
                                      ),
                                      _reactiveTile(
                                          StringConstants.id, manager.moduleId),
                                      _reactiveTile(
                                        StringConstants.revision,
                                        manager.moduleRevision,
                                      ),
                                      _reactiveTile(
                                        StringConstants.hardwareVersion,
                                        manager.moduleHardware,
                                      ),
                                      _reactiveTile(
                                        StringConstants.firmwareVersion,
                                        manager.moduleFirmware,
                                      ),
                                      _reactiveTile(
                                        StringConstants.manufacturingDate,
                                        manager.moduleDate,
                                      ),
                                      _reactiveTile(
                                        StringConstants.protocolNo,
                                        manager.moduleProtocol,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ColorConstants.primary,
                                  side: const BorderSide(
                                      color: ColorConstants.primary),
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
      },
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

  Widget _reactiveTile<T>(String label, ValueNotifier<T> notifier) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (_, value, __) {
        return _infoTile(label, value.toString());
      },
    );
  }

  Widget _reactiveTileBool(String label, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, value, __) {
        return _infoTile(label, value ? StringConstants.yes : StringConstants.no);
      },
    );
  }

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
