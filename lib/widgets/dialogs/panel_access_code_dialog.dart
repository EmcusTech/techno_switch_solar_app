import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/ble/controller/ble_log_controller.dart';
import 'package:Technoswitch/features/logs/bindings/log_binding.dart';
import 'package:Technoswitch/features/logs/models/log_flow_args.dart';
import 'package:Technoswitch/features/logs/views/log_retrieval_loading_screen.dart';
import 'package:Technoswitch/features/scan/models/scan_type.dart';
import 'package:Technoswitch/widgets/common/common_numeric_keypad_widget.dart';
import 'package:Technoswitch/widgets/common/common_windows_access_code_dialog.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

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

  if (!context.mounted) return false;

  if (Platform.isWindows) {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CommonWindowsAccessCodeDialog(
          bleProcess: bleProcess,
          onStartValidation: onStartValidation,
          sheetContext: dialogContext,
          onAccessGranted:
              onAccessGranted == null
                  ? null
                  : () => onAccessGranted(dialogContext),
          successCloseDelay: successCloseDelay,
          persistSessionAccessCode: persistSessionAccessCode,
        );
      },
    );
    return result ?? false;
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
      LogBinding(
        args: LogFlowArgs.loading(
          selectedDevice: device,
          scanType: ScanType.bluetooth,
          isLiveEvent: isLiveEvent ?? false,
        ),
      ).dependencies();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LogRetrievalLoadingScreen()),
      );
    },
  );
}
