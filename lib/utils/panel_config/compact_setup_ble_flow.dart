import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

/// Spinner-and-status dialog used by relays, inputs, and zones.
/// Sounders, radio, module info, and L-Bus use this instead of the
/// access-code dialog once the session code is already accepted.
Future<void> runCompactSetupDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required String successMessage,
  required String fallbackStatus,
  required void Function() markActive,
  required Future<void> Function() start,
  required Future<void> Function() onDownloadComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runCompactSetupFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    successMessage: successMessage,
    fallbackStatus: fallbackStatus,
    markActive: markActive,
    start: start,
    onComplete: onDownloadComplete,
    showSuccess: showDownloadSuccess,
  );
}

Future<void> runCompactSetupApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required String successMessage,
  required String fallbackStatus,
  required void Function() markActive,
  required Future<void> Function() start,
  required Future<void> Function() onApplyComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runCompactSetupFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    successMessage: successMessage,
    fallbackStatus: fallbackStatus,
    markActive: markActive,
    start: start,
    onComplete: onApplyComplete,
    showSuccess: showApplySuccess,
  );
}

Future<void> _runCompactSetupFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required String successMessage,
  required String fallbackStatus,
  required void Function() markActive,
  required Future<void> Function() start,
  required Future<void> Function() onComplete,
  required void Function(String message) showSuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;
  bleProcess.isAccessKeyValid.value = null;
  markActive();
  unawaited(start());

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _CompactSetupProgressDialog(
        bleProcess: bleProcess,
        fallbackStatus: fallbackStatus,
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;
          await onComplete();
          if (isMounted()) {
            showSuccess(successMessage);
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

class _CompactSetupProgressDialog extends StatefulWidget {
  const _CompactSetupProgressDialog({
    required this.bleProcess,
    required this.fallbackStatus,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final String fallbackStatus;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_CompactSetupProgressDialog> createState() =>
      _CompactSetupProgressDialogState();
}

class _CompactSetupProgressDialogState
    extends State<_CompactSetupProgressDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.bleProcess.isAccessKeyValid.addListener(_onAccessKey);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
    if (widget.bleProcess.isAccessKeyValid.value == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishSucceeded();
      });
    }
  }

  @override
  void dispose() {
    widget.bleProcess.isAccessKeyValid.removeListener(_onAccessKey);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onAccessKey() {
    if (_finished) return;
    if (widget.bleProcess.isAccessKeyValid.value != true) return;
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
    return widget.fallbackStatus;
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
