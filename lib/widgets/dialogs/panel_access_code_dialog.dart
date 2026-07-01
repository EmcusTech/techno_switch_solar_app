import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/logs/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/widgets/common/common_numeric_keypad_widget.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

Future<bool> _showPanelAccessCodeBottomSheet({
  required BuildContext context,
  required Future<void> Function() onStartValidation,
  required bool clearSessionAccessCode,
  Duration successCloseDelay = const Duration(milliseconds: 400),
  Future<void> Function(BuildContext sheetContext)? onAccessGranted,
  bool persistSessionAccessCode = true,
}) async {
  final bleController = Get.find<BleLogController>();
  final bleProcess = bleController.bleProcess;

  // Always reset UI/BLE flags so a prior StringConstants.validating does not hide the keypad.
  bleProcess.isAccessKeyValid.value = null;
  bleProcess.processDesc.value = '';
  if (clearSessionAccessCode) {
    bleProcess.clearSessionAccessCode();
  } else {
    bleProcess.accessKey.value = '';
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: ColorConstants.transparent,
    barrierColor: ColorConstants.blackMaterial.withValues(alpha: 0.4),
    builder: (sheetContext) {
      return CommonNumericKeypadWidget(
        bleProcess: bleProcess,
        onStartValidation: onStartValidation,
        sheetContext: sheetContext,
        onAccessGranted:
            onAccessGranted == null
                ? null
                : () => onAccessGranted(sheetContext),
        successCloseDelay: successCloseDelay,
        persistSessionAccessCode: persistSessionAccessCode,
      );
    },
  );
  return result ?? false;
}

/// Shared StringConstants.enterAccessCode bottom sheet. On successful panel validation, calls
/// [BleProcess.setSessionAccessCode] and pops `true`.
Future<bool> showPanelAccessCodeGatewayDialog({
  required BuildContext context,
  required Future<void> Function() onStartValidation,
}) {
  return _showPanelAccessCodeBottomSheet(
    context: context,
    onStartValidation: onStartValidation,
    clearSessionAccessCode: true,
    successCloseDelay: const Duration(seconds: 2),
  );
}

/// Access-code bottom sheet for Retrieve Log / live-event log flows.
/// Validates via [onStartValidation] (typically [BleLogController.startLogRetrieval]),
/// then navigates to [LogRetrievalLoadingScreen].
Future<bool> showPanelAccessCodeLogRetrievalSheet({
  required BuildContext context,
  required DiscoveredDevice device,
  required bool? isLiveEvent,
  required Future<void> Function() onStartValidation,
}) {
  return _showPanelAccessCodeBottomSheet(
    context: context,
    onStartValidation: onStartValidation,
    clearSessionAccessCode: false,
    successCloseDelay: const Duration(seconds: 1),
    persistSessionAccessCode: false,
    onAccessGranted: (sheetContext) async {
      if (sheetContext.mounted) {
        Navigator.of(sheetContext, rootNavigator: true).pop(true);
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => LogRetrievalLoadingScreen(
                scanType: ScanType.bluetooth,
                selectedDevice: device,
                isLiveEvent: isLiveEvent,
              ),
        ),
      );
    },
  );
}
