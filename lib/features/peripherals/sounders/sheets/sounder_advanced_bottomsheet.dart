import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/peripherals/sounders/controllers/sounder_mode_controller.dart';
import 'package:Technoswitch/features/peripherals/sounders/sheets/sounder_advanced_panel.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

/// Editor for the shared sounder advanced configuration.
///
/// Values are the same sounder setup the sounder sheet sends. Ext Out
/// edits each function on its own tab.
class SounderAdvancedBottomSheet extends StatefulWidget {
  const SounderAdvancedBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  static const controllerTag = 'sounder-advanced';

  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  @override
  State<SounderAdvancedBottomSheet> createState() =>
      SounderAdvancedBottomSheetState();
}

class SounderAdvancedBottomSheetState extends State<SounderAdvancedBottomSheet>
    with SingleTickerProviderStateMixin {
  late final SounderModeController controller;
  late final TabController _tabController;
  final FocusNode delayFocusNode = FocusNode();
  final String _delayError = StringConstants.delayMustBeBetween0And600Seconds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTab);
    controller = Get.put(
      SounderModeController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
      tag: SounderAdvancedBottomSheet.controllerTag,
    );
  }

  void _onTab() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTab);
    _tabController.dispose();
    delayFocusNode.dispose();
    Get.delete<SounderModeController>(
      tag: SounderAdvancedBottomSheet.controllerTag,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SounderModeController>(
      init: controller,
      tag: SounderAdvancedBottomSheet.controllerTag,
      builder: (c) {
        final scroll = NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              FocusScope.of(context).unfocus();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics:
                PeripheralSheetChrome.flat
                    ? const ClampingScrollPhysics()
                    : const BouncingScrollPhysics(),
            padding: peripheralSheetScrollPadding(top: 0, bottom: 16),
            child: SounderAdvancedPanel(
              controller: c,
              tabController: _tabController,
              delayFocusNode: delayFocusNode,
              delayError: _delayError,
              extFunctionTabs: true,
              showHeader: false,
            ),
          ),
        );

        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: PeripheralSheetChrome.lipColor,
                borderRadius: PeripheralSheetChrome.topRadius(),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: PeripheralSheetChrome.lipPadding),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: ColorConstants.white,
                    borderRadius: PeripheralSheetChrome.topRadius(),
                  ),
                  child: Stack(
                    children: [
                      const PeripheralSheetHeaderRow(),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          children: [
                            const PeripheralSheetDragHandle(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  StringConstants.sounderAdvanced,
                                  style: StyleConstants.textDark14w700Style,
                                ),
                              ),
                            ),
                            Expanded(child: scroll),
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
        );
      },
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: const BorderSide(color: ColorConstants.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onDownload();
        },
        child: Text(
          StringConstants.download,
          style: StyleConstants.primary16w600Style,
        ),
      ),
    );
  }

  Widget _applyButton() {
    final canApply = controller.manager != null && controller.computeIsValid();
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed:
            canApply
                ? () async {
                  if (await controller.commitLocal()) {
                    widget.onApply();
                  }
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
  }
}
