import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_ui_delegate.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsPageHost(controller: controller);
  }
}

class _SettingsPageHost extends StatefulWidget {
  const _SettingsPageHost({required this.controller});

  final SettingsController controller;

  @override
  State<_SettingsPageHost> createState() => _SettingsPageHostState();
}

class _SettingsPageHostState extends State<_SettingsPageHost>
    implements SettingsUiDelegate {
  SettingsController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  Future<bool?> showDisconnectConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            StringConstants.disconnectDevice,
            style: StyleConstants.black18w700Style,
          ),
          content: Text(
            StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
            style: StyleConstants.black14w400Style,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                StringConstants.cancel,
                style: StyleConstants.textGray14w600Style,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.5),
                ),
                elevation: 0,
              ),
              child: Text('Disconnect', style: StyleConstants.white14w600Style),
            ),
          ],
        );
      },
    );
  }

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
    final content = Container(
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
                          child: SvgPicture.asset(AssetConstants.arrowBackIcon),
                        ),
                      if (!_controller.embedded) const SizedBox(width: 8),
                      Text(
                        StringConstants.projectSettings,
                        style: StyleConstants.black20w700Style,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 19),
                _buildSettingsContainer(),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      extendBody: true,
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
        child: content,
      ),
    );
  }

  Widget _buildSettingsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildSettingsContent()),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller.displayPrefix,
                    style: StyleConstants.black16w700Style,
                  ),
                  Text(
                    _controller.displayId,
                    style: StyleConstants.textDisabled14w500Style,
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller.bleManager.isConnectedNotifier,
                    builder: (context, isConnected, child) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: StringConstants.status4,
                              style: StyleConstants.textDisabled14w500Style,
                            ),
                            TextSpan(
                              text:
                                  isConnected
                                      ? StringConstants.connected
                                      : StringConstants.disconnected,
                              style: StyleConstants.primary14w500Style.copyWith(
                                color:
                                    isConnected
                                        ? ColorConstants.success
                                        : ColorConstants.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in SettingsController.menuItems) ...[
            Divider(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
              thickness: 1,
            ),
            _settingTile(
              title: item.title,
              onTap: () => _controller.onMenuItemTap(item.action),
            ),
          ],
          Divider(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
            thickness: 1,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _settingTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              AssetConstants.settingsIcon,
              colorFilter: ColorFilter.mode(
                ColorConstants.textHeading.withValues(alpha: 0.72),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: StyleConstants.black16w400Style),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: ColorConstants.textSecondary.withValues(alpha: 0.47),
            ),
          ],
        ),
      ),
    );
  }
}
