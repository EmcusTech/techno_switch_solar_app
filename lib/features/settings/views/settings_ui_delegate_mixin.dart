import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_ui_delegate.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

mixin SettingsUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SettingsUiDelegate {
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
              child: Text(
                StringConstants.disconnect,
                style: StyleConstants.white14w600Style,
              ),
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
}
