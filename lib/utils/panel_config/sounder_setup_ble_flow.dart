import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/ble/controller/ble_log_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

enum SounderSetupBleFlowMode { download, apply }

Future<void> runSounderSetupDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onDownloadComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runSounderSetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: SounderSetupBleFlowMode.download,
    onDownloadComplete: onDownloadComplete,
    showDownloadSuccess: showDownloadSuccess,
  );
}

Future<void> runSounderSetupApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onApplyComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runSounderSetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: SounderSetupBleFlowMode.apply,
    onApplyComplete: onApplyComplete,
    showApplySuccess: showApplySuccess,
  );
}

Future<void> _runSounderSetupBleFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required SounderSetupBleFlowMode mode,
  Future<void> Function()? onDownloadComplete,
  Future<void> Function()? onApplyComplete,
  void Function(String message)? showDownloadSuccess,
  void Function(String message)? showApplySuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;

  if (mode == SounderSetupBleFlowMode.download) {
    bleProcess.isSounderSetupFetchDone.value = false;
    bleProcess.isSounderSetupFetchCommandActive.value = true;
    unawaited(bleController.startSounderSetupFetch());
  } else {
    bleProcess.isSounderSetupApplyDone.value = false;
    bleProcess.isSounderSetupApplyCommandActive.value = true;
    unawaited(bleController.startSounderSetupApply());
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _SounderSetupBleProgressDialog(
        bleProcess: bleProcess,
        mode: mode,
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;

          if (mode == SounderSetupBleFlowMode.download) {
            await onDownloadComplete?.call();
            if (isMounted()) {
              showDownloadSuccess?.call(StringConstants.sounder);
            }
          } else {
            await onApplyComplete?.call();
            if (isMounted()) {
              showApplySuccess?.call(StringConstants.sounder);
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

class _SounderSetupBleProgressDialog extends StatefulWidget {
  const _SounderSetupBleProgressDialog({
    required this.bleProcess,
    required this.mode,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final SounderSetupBleFlowMode mode;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_SounderSetupBleProgressDialog> createState() =>
      _SounderSetupBleProgressDialogState();
}

class _SounderSetupBleProgressDialogState
    extends State<_SounderSetupBleProgressDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.bleProcess.isSounderSetupFetchDone.addListener(_onFetchDone);
    widget.bleProcess.isSounderSetupApplyDone.addListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
  }

  @override
  void dispose() {
    widget.bleProcess.isSounderSetupFetchDone.removeListener(_onFetchDone);
    widget.bleProcess.isSounderSetupApplyDone.removeListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onFetchDone() {
    if (_finished || widget.mode != SounderSetupBleFlowMode.download) return;
    if (!widget.bleProcess.isSounderSetupFetchDone.value) return;
    _finishSucceeded();
  }

  void _onApplyDone() {
    if (_finished || widget.mode != SounderSetupBleFlowMode.apply) return;
    if (!widget.bleProcess.isSounderSetupApplyDone.value) return;
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
    return widget.mode == SounderSetupBleFlowMode.download
        ? '${StringConstants.downloadingSounder} 1/3'
        : '${StringConstants.applyingSounder} 1/3';
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
