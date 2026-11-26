import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/ble/controller/ble_log_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

enum TestModeBleFlowMode { download, apply }

/// Runs the sounder setup exchange to completion, then the relay exchange.
/// Sounder is one packet. Relay is one packet per relay, already sequenced
/// inside the relay command. This flow only starts relay after sounder is done.
Future<void> runTestModeDownloadFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onSounderComplete,
  required Future<void> Function() onRelayComplete,
  required void Function(String message) showDownloadSuccess,
}) {
  return _runTestModeBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: TestModeBleFlowMode.download,
    onSounderComplete: onSounderComplete,
    onRelayComplete: onRelayComplete,
    showDownloadSuccess: showDownloadSuccess,
  );
}

Future<void> runTestModeApplyFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required Future<void> Function() onSounderComplete,
  required Future<void> Function() onRelayComplete,
  required void Function(String message) showApplySuccess,
}) {
  return _runTestModeBleFlow(
    context: context,
    isMounted: isMounted,
    bleProcess: bleProcess,
    bleController: bleController,
    mode: TestModeBleFlowMode.apply,
    onSounderComplete: onSounderComplete,
    onRelayComplete: onRelayComplete,
    showApplySuccess: showApplySuccess,
  );
}

Future<void> _runTestModeBleFlow({
  required BuildContext context,
  required bool Function() isMounted,
  required BleProcess bleProcess,
  required BleLogController bleController,
  required TestModeBleFlowMode mode,
  required Future<void> Function() onSounderComplete,
  required Future<void> Function() onRelayComplete,
  void Function(String message)? showDownloadSuccess,
  void Function(String message)? showApplySuccess,
}) async {
  bleProcess.maxOtherPacketsRetriesReached.value = false;

  if (mode == TestModeBleFlowMode.download) {
    bleProcess.isSounderSetupFetchDone.value = false;
    bleProcess.isRelaySetupFetchDone.value = false;
    bleProcess.isSounderSetupFetchCommandActive.value = true;
    unawaited(bleController.startSounderSetupFetch());
  } else {
    bleProcess.isSounderSetupApplyDone.value = false;
    bleProcess.isRelaySetupApplyDone.value = false;
    bleProcess.isSounderSetupApplyCommandActive.value = true;
    unawaited(bleController.startSounderSetupApply());
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _TestModeBleProgressDialog(
        bleProcess: bleProcess,
        mode: mode,
        onSounderDone: () async {
          await onSounderComplete();
          if (mode == TestModeBleFlowMode.download) {
            bleProcess.isRelaySetupFetchCommandActive.value = true;
            unawaited(bleController.startRelaySetupFetch());
          } else {
            bleProcess.isRelaySetupCommandApplyActive.value = true;
            unawaited(bleController.startRelaySetupApply());
          }
        },
        onSucceeded: () async {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext, rootNavigator: true).pop();
          if (!isMounted()) return;
          await onRelayComplete();
          if (!isMounted()) return;
          if (mode == TestModeBleFlowMode.download) {
            showDownloadSuccess?.call(StringConstants.testMode);
          } else {
            showApplySuccess?.call(StringConstants.testMode);
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

class _TestModeBleProgressDialog extends StatefulWidget {
  const _TestModeBleProgressDialog({
    required this.bleProcess,
    required this.mode,
    required this.onSounderDone,
    required this.onSucceeded,
    required this.onFailed,
  });

  final BleProcess bleProcess;
  final TestModeBleFlowMode mode;
  final Future<void> Function() onSounderDone;
  final Future<void> Function() onSucceeded;
  final VoidCallback onFailed;

  @override
  State<_TestModeBleProgressDialog> createState() =>
      _TestModeBleProgressDialogState();
}

class _TestModeBleProgressDialogState extends State<_TestModeBleProgressDialog> {
  bool _handedOff = false;
  bool _finished = false;

  ValueNotifier<bool> get _sounderDone =>
      widget.mode == TestModeBleFlowMode.download
          ? widget.bleProcess.isSounderSetupFetchDone
          : widget.bleProcess.isSounderSetupApplyDone;

  ValueNotifier<bool> get _relayDone =>
      widget.mode == TestModeBleFlowMode.download
          ? widget.bleProcess.isRelaySetupFetchDone
          : widget.bleProcess.isRelaySetupApplyDone;

  @override
  void initState() {
    super.initState();
    _sounderDone.addListener(_onSounderDone);
    _relayDone.addListener(_onRelayDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.addListener(_onFailed);
  }

  @override
  void dispose() {
    _sounderDone.removeListener(_onSounderDone);
    _relayDone.removeListener(_onRelayDone);
    widget.bleProcess.maxOtherPacketsRetriesReached.removeListener(_onFailed);
    super.dispose();
  }

  void _onSounderDone() {
    if (_finished || _handedOff) return;
    if (!_sounderDone.value) return;
    _handedOff = true;
    unawaited(widget.onSounderDone());
  }

  void _onRelayDone() {
    if (_finished || !_handedOff) return;
    if (!_relayDone.value) return;
    unawaited(_finishSucceeded());
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
    if (processDesc.isNotEmpty) return processDesc;
    return widget.mode == TestModeBleFlowMode.download
        ? StringConstants.downloadingSounder
        : StringConstants.applyingSounder;
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
