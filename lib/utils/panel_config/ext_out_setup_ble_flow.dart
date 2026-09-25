import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

enum ExtOutSetupBleFlowMode { download, apply }

Future<void> runExtOutSetupDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onDownloadComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runExtOutSetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: ExtOutSetupBleFlowMode.download,
    onDownloadComplete: onDownloadComplete,
    showDownloadSuccess: showDownloadSuccess,
  );
}

Future<void> runExtOutSetupApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onApplyComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runExtOutSetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: ExtOutSetupBleFlowMode.apply,
    onApplyComplete: onApplyComplete,
    showApplySuccess: showApplySuccess,
  );
}

Future<void> _runExtOutSetupBleFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required ExtOutSetupBleFlowMode mode,
  Future<void> Function()? onDownloadComplete,
  Future<void> Function()? onApplyComplete,
  void Function(String message)? showDownloadSuccess,
  void Function(String message)? showApplySuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;

  if (mode == ExtOutSetupBleFlowMode.download) {
    bleProcess.isExtOutFetchDone.value = false;
    bleProcess.isExtOutCommandFetchActive.value = true;
    unawaited(bleController.startExtOutFetch());
  } else {
    bleProcess.isExtOutApplyDone.value = false;
    bleProcess.isExtOutCommandApplyActive.value = true;
    unawaited(bleController.startExtOutApply());
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _ExtOutSetupBleProgressDialog(
        bleProcess: bleProcess,
        mode: mode,
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;

          if (mode == ExtOutSetupBleFlowMode.download) {
            await onDownloadComplete?.call();
            if (isMounted()) {
              showDownloadSuccess?.call(StringConstants.extinguishingOutput);
            }
          } else {
            await onApplyComplete?.call();
            if (isMounted()) {
              showApplySuccess?.call(StringConstants.extinguishingOutput);
            }
          }
        },
        onFailed: () {
          bleProcess.maxOtherPacketsRetriesReached.value = false;
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
        },
      );
    },
  );
}

class _ExtOutSetupBleProgressDialog extends StatefulWidget {
  const _ExtOutSetupBleProgressDialog({
    required this.bleProcess,
    required this.mode,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final ExtOutSetupBleFlowMode mode;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_ExtOutSetupBleProgressDialog> createState() =>
      _ExtOutSetupBleProgressDialogState();
}

class _ExtOutSetupBleProgressDialogState
    extends State<_ExtOutSetupBleProgressDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.bleProcess.isExtOutFetchDone.addListener(_onFetchDone);
    widget.bleProcess.isExtOutApplyDone.addListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
  }

  @override
  void dispose() {
    widget.bleProcess.isExtOutFetchDone.removeListener(_onFetchDone);
    widget.bleProcess.isExtOutApplyDone.removeListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onFetchDone() {
    if (_finished || widget.mode != ExtOutSetupBleFlowMode.download) return;
    if (!widget.bleProcess.isExtOutFetchDone.value) return;
    _finishSucceeded();
  }

  void _onApplyDone() {
    if (_finished || widget.mode != ExtOutSetupBleFlowMode.apply) return;
    if (!widget.bleProcess.isExtOutApplyDone.value) return;
    _finishSucceeded();
  }

  void _onFailed() {
    if (_finished) return;
    if (!widget.bleProcess.maxOtherPacketsRetriesReached.value) return;
    _finished = true;
    widget.onFailed();
  }

  Future<void> _finishSucceeded() async {
    if (_finished) return;
    _finished = true;
    await widget.onSucceeded();
  }

  String _statusText(bool failed, String processDesc) {
    if (failed) {
      return processDesc.isNotEmpty
          ? processDesc
          : StringConstants.deviceNotResponding;
    }
    if (processDesc.isNotEmpty) {
      return processDesc;
    }
    return widget.mode == ExtOutSetupBleFlowMode.download
        ? StringConstants.downloadExtOutSetup
        : StringConstants.applyingExtOutSetup;
  }

  @override
  Widget build(BuildContext context) {
    final bool failed = widget.bleProcess.maxOtherPacketsRetriesReached.value;

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
            if (!failed)
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorConstants.primary,
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: ColorConstants.errorIconBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: ColorConstants.errorPink,
                  size: 32,
                ),
              ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: widget.bleProcess.processDesc,
              builder: (_, processDesc, __) {
                return Text(
                  _statusText(failed, processDesc),
                  style: StyleConstants.textDark16w600Style,
                  textAlign: TextAlign.center,
                );
              },
            ),
            if (failed) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: widget.onFailed,
                  child: Text(
                    StringConstants.close,
                    style: StyleConstants.white16w600Style,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
