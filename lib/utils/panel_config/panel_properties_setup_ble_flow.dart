import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

enum PanelPropertiesBleFlowMode { download, apply }

Future<void> runPanelPropertiesDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required String successMessage,
  required String progressLabel,
  required void Function() markActive,
  required Future<void> Function() start,
  required Future<void> Function() onDownloadComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runPanelPropertiesBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    mode: PanelPropertiesBleFlowMode.download,
    successMessage: successMessage,
    progressLabel: progressLabel,
    markActive: markActive,
    start: start,
    onDownloadComplete: onDownloadComplete,
    showDownloadSuccess: showDownloadSuccess,
  );
}

Future<void> runPanelPropertiesApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required String successMessage,
  required String progressLabel,
  required void Function() markActive,
  required Future<void> Function() start,
  required Future<void> Function() onApplyComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runPanelPropertiesBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    mode: PanelPropertiesBleFlowMode.apply,
    successMessage: successMessage,
    progressLabel: progressLabel,
    markActive: markActive,
    start: start,
    onApplyComplete: onApplyComplete,
    showApplySuccess: showApplySuccess,
  );
}

Future<void> _runPanelPropertiesBleFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required PanelPropertiesBleFlowMode mode,
  required String successMessage,
  required String progressLabel,
  required void Function() markActive,
  required Future<void> Function() start,
  Future<void> Function()? onDownloadComplete,
  Future<void> Function()? onApplyComplete,
  void Function(String message)? showDownloadSuccess,
  void Function(String message)? showApplySuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;

  if (mode == PanelPropertiesBleFlowMode.download) {
    bleProcess.isPanelPropertiesFetchDone.value = false;
  } else {
    bleProcess.isPanelPropertiesApplyDone.value = false;
  }
  markActive();
  unawaited(start());

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _PanelPropertiesBleProgressDialog(
        bleProcess: bleProcess,
        mode: mode,
        progressLabel: progressLabel,
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;

          if (mode == PanelPropertiesBleFlowMode.download) {
            await onDownloadComplete?.call();
            if (isMounted()) {
              showDownloadSuccess?.call(successMessage);
            }
          } else {
            await onApplyComplete?.call();
            if (isMounted()) {
              showApplySuccess?.call(successMessage);
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

class _PanelPropertiesBleProgressDialog extends StatefulWidget {
  const _PanelPropertiesBleProgressDialog({
    required this.bleProcess,
    required this.mode,
    required this.progressLabel,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final PanelPropertiesBleFlowMode mode;
  final String progressLabel;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_PanelPropertiesBleProgressDialog> createState() =>
      _PanelPropertiesBleProgressDialogState();
}

class _PanelPropertiesBleProgressDialogState
    extends State<_PanelPropertiesBleProgressDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.bleProcess.isPanelPropertiesFetchDone.addListener(_onFetchDone);
    widget.bleProcess.isPanelPropertiesApplyDone.addListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
  }

  @override
  void dispose() {
    widget.bleProcess.isPanelPropertiesFetchDone.removeListener(_onFetchDone);
    widget.bleProcess.isPanelPropertiesApplyDone.removeListener(_onApplyDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onFetchDone() {
    if (_finished || widget.mode != PanelPropertiesBleFlowMode.download) return;
    if (!widget.bleProcess.isPanelPropertiesFetchDone.value) return;
    _finishSucceeded();
  }

  void _onApplyDone() {
    if (_finished || widget.mode != PanelPropertiesBleFlowMode.apply) return;
    if (!widget.bleProcess.isPanelPropertiesApplyDone.value) return;
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
    return widget.progressLabel;
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
