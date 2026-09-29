import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/ble/controller/ble_log_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

enum RelaySetupBleFlowMode { download, apply }

Future<void> runRelaySetupDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onDownloadComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runRelaySetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: RelaySetupBleFlowMode.download,
    onDownloadComplete: onDownloadComplete,
    showDownloadSuccess: showDownloadSuccess,
  );
}

Future<void> runRelaySetupApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onApplyComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runRelaySetupBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: RelaySetupBleFlowMode.apply,
    onApplyComplete: onApplyComplete,
    showApplySuccess: showApplySuccess,
  );
}

Future<void> _runRelaySetupBleFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required RelaySetupBleFlowMode mode,
  Future<void> Function()? onDownloadComplete,
  Future<void> Function()? onApplyComplete,
  void Function(String message)? showDownloadSuccess,
  void Function(String message)? showApplySuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;

  if (mode == RelaySetupBleFlowMode.download) {
    bleProcess.isRelaySetupFetchDone.value = false;
    bleProcess.isRelaySetupFetchCommandActive.value = true;
    unawaited(bleController.startRelaySetupFetch());
  } else {
    bleProcess.isRelaySetupApplyDone.value = false;
    bleProcess.isRelaySetupCommandApplyActive.value = true;
    unawaited(bleController.startRelaySetupApply());
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _RelaySetupBleProgressDialog(
        bleProcess: bleProcess,
        mode: mode,
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;

          if (mode == RelaySetupBleFlowMode.download) {
            await onDownloadComplete?.call();
            if (isMounted()) {
              showDownloadSuccess?.call(StringConstants.relays);
            }
          } else {
            await onApplyComplete?.call();
            if (isMounted()) {
              showApplySuccess?.call(StringConstants.relays);
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

class _RelaySetupBleProgressDialog extends StatefulWidget {
  const _RelaySetupBleProgressDialog({
    required this.bleProcess,
    required this.mode,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final RelaySetupBleFlowMode mode;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_RelaySetupBleProgressDialog> createState() =>
      _RelaySetupBleProgressDialogState();
}

class _RelaySetupBleProgressDialogState
    extends State<_RelaySetupBleProgressDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.bleProcess.isRelaySetupFetchDone.addListener(_onFetchDone);
    widget.bleProcess.isRelaySetupApplyDone.addListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
  }

  @override
  void dispose() {
    widget.bleProcess.isRelaySetupFetchDone.removeListener(_onFetchDone);
    widget.bleProcess.isRelaySetupApplyDone.removeListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onFetchDone() {
    if (_finished || widget.mode != RelaySetupBleFlowMode.download) return;
    if (!widget.bleProcess.isRelaySetupFetchDone.value) return;
    _finishSucceeded();
  }

  void _onApplyDone() {
    if (_finished || widget.mode != RelaySetupBleFlowMode.apply) return;
    if (!widget.bleProcess.isRelaySetupApplyDone.value) return;
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
    return widget.mode == RelaySetupBleFlowMode.download
        ? '${StringConstants.downloadingRelay} 1/3'
        : '${StringConstants.applyingRelay} 1/3';
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
