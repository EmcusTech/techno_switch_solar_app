import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DisconnectDeviceDialog extends StatelessWidget {
  const DisconnectDeviceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorConstants.errorIconBackground,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.link_off,
                  color: ColorConstants.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              StringConstants.disconnectDevice,
              style: StyleConstants.textDark18w700Style,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
              style: StyleConstants.textGray14w400Style,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorConstants.buttonSecondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: ColorConstants.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          StringConstants.cancel,
                          style: StyleConstants.textGray16w600Style,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Disconnect',
                          style: StyleConstants.white16w600Style,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
