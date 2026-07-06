import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

void showPanelApplySuccessDialog(
  BuildContext context,
  BleProcess bleProcess,
  String message, {
  String? subtitle,
  VoidCallback? onDismissed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final String resolvedSubtitle =
          subtitle ??
          'The $message has been successfully applied to the device.';

      Future.delayed(const Duration(seconds: 2), () {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
          bleProcess.isExtOutApplyDone.value = false;
          bleProcess.isInputSetupApplyDone.value = false;
          bleProcess.isRelaySetupApplyDone.value = false;
          bleProcess.isZoneSetupApplyDone.value = false;
          bleProcess.isLBusSetupApplyDone.value = false;
          bleProcess.isRadioSetupApplyDone.value = false;
          bleProcess.isSounderSetupApplyDone.value = false;
          bleProcess.isServiceDueApplyDone.value = false;
          bleProcess.isAccessCodeSetupApplyDone.value = false;
          bleProcess.isPanelInfoSetupApplyDone.value = false;
          bleProcess.isGeneralModuleSetupApplyDone.value = false;
          onDismissed?.call();
        }
      });
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
                decoration: const BoxDecoration(
                  color: ColorConstants.successBackgroundLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AssetConstants.checkCircleIcon,
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$message Applied',
                style: StyleConstants.textDark20w700Style,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                resolvedSubtitle,
                style: StyleConstants.textMuted14w400Style,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showPanelDownloadSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
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
                decoration: const BoxDecoration(
                  color: ColorConstants.successBackgroundLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AssetConstants.checkCircleIcon,
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$message Downloaded',
                style: StyleConstants.textDark20w700Style,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The $message has been successfully downloaded from the device.',
                style: StyleConstants.textMuted14w400Style,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}
