import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/test_mode/models/test_mode_menu_item.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class TestModeScreen extends GetView<TestModeController> {
  const TestModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _TestModePageHost(controller: controller);
  }
}

class _TestModePageHost extends StatefulWidget {
  const _TestModePageHost({required this.controller});

  final TestModeController controller;

  @override
  State<_TestModePageHost> createState() => _TestModePageHostState();
}

class _TestModePageHostState extends State<_TestModePageHost>
    implements TestModeUiDelegate {
  TestModeController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _controller.handleWillPop();
          if (!context.mounted) return;
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
            ),
          ),
          child: Stack(
            children: [
              SvgPicture.asset(AssetConstants.background1),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          if (!_controller.embedded)
                            GestureDetector(
                              onTap: _controller.handleBackNavigation,
                              child: SvgPicture.asset(
                                AssetConstants.arrowBackIcon,
                              ),
                            ),
                          if (!_controller.embedded) const SizedBox(width: 8),
                          Text(
                            StringConstants.testMode,
                            style: StyleConstants.black20w700Style,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 19),
                    _buildTestModeContainer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestModeContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: SvgPicture.asset(AssetConstants.background2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      StringConstants.testMode,
                      style: StyleConstants.textMuted20w600Style,
                    ),
                    Text(
                      StringConstants.configuration,
                      style: StyleConstants.textBodyDark32w700Style,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < TestModeController.menuItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _buildTestModeOption(
                      TestModeController.menuItems[i],
                      () => _controller.onMenuItemTap(
                        TestModeController.menuItems[i].action,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestModeOption(TestModeMenuItem item, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.borderGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item.iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      ColorConstants.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                item.title,
                style: StyleConstants.textDark16w600Style,
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ColorConstants.textDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
