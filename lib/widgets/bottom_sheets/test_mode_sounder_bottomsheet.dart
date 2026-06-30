import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/test_mode_sounder_controller.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/widgets/dropdown.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class TestModeSounderBottomSheet extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDownload;
  final VoidCallback onApply;
  final ValueNotifier<int> refreshTrigger;

  const TestModeSounderBottomSheet({
    super.key,
    required this.deviceId,
    required this.onDownload,
    required this.onApply,
    required this.refreshTrigger,
  });

  @override
  State<TestModeSounderBottomSheet> createState() =>
      _TestModeSounderBottomSheetState();
}

class _TestModeSounderBottomSheetState
    extends State<TestModeSounderBottomSheet> {
  late final TestModeSounderController controller;

  List<String> get yesNoOptions => controller.yesNoOptions;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      TestModeSounderController(
        deviceId: widget.deviceId,
        refreshTrigger: widget.refreshTrigger,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<TestModeSounderController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TestModeSounderController>(
      init: controller,
      builder: (c) {
        final manager = c.manager;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(50),
                    ),
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
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          children: [
                            _dragHandle(),
                            _title(StringConstants.sounderTest),
                            Expanded(
                              child: NotificationListener<
                                UserScrollNotification
                              >(
                                onNotification: (notification) {
                                  if (notification.direction !=
                                      ScrollDirection.idle) {
                                    FocusScope.of(context).unfocus();
                                  }
                                  return false;
                                },
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 16),
                                  child:
                                      manager == null
                                          ? const SizedBox.shrink()
                                          : AnimatedBuilder(
                                            animation: Listenable.merge([
                                              manager.isSounderOneTest,
                                              manager.isSounderTwoTest,
                                              manager.isSounderThreeTest,
                                            ]),
                                            builder: (context, _) {
                                              return Column(
                                                children: [
                                                  DropdownWidget(
                                                    label:
                                                        StringConstants
                                                            .sounder1Test,
                                                    value:
                                                        manager
                                                                .isSounderOneTest
                                                                .value
                                                            ? StringConstants
                                                                .yes
                                                            : StringConstants
                                                                .no,
                                                    items: yesNoOptions,
                                                    onChanged:
                                                        (v) => controller
                                                            .onTestChanged(
                                                              0,
                                                              v ==
                                                                  StringConstants
                                                                      .yes,
                                                            ),
                                                  ),
                                                  DropdownWidget(
                                                    label:
                                                        StringConstants
                                                            .sounder2Test,
                                                    value:
                                                        manager
                                                                .isSounderTwoTest
                                                                .value
                                                            ? StringConstants
                                                                .yes
                                                            : StringConstants
                                                                .no,
                                                    items: yesNoOptions,
                                                    onChanged:
                                                        (v) => controller
                                                            .onTestChanged(
                                                              1,
                                                              v ==
                                                                  StringConstants
                                                                      .yes,
                                                            ),
                                                  ),
                                                  DropdownWidget(
                                                    label:
                                                        StringConstants
                                                            .sounder3Test,
                                                    value:
                                                        manager
                                                                .isSounderThreeTest
                                                                .value
                                                            ? StringConstants
                                                                .yes
                                                            : StringConstants
                                                                .no,
                                                    items: yesNoOptions,
                                                    onChanged:
                                                        (v) => controller
                                                            .onTestChanged(
                                                              2,
                                                              v ==
                                                                  StringConstants
                                                                      .yes,
                                                            ),
                                                  ),
                                                ],
                                              );
                                            },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed:
            controller.manager != null
                ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controller.applyTest();
                  widget.onApply();
                }
                : null,
        child: Text(
          StringConstants.apply,
          style: StyleConstants.white16w600Style,
        ),
      ),
    );
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
      child: Text(text, style: StyleConstants.textDark20w700Style),
    );
  }
}
