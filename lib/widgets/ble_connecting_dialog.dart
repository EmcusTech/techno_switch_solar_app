import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Copy for the shared BLE connecting dialog. Use [afterFirmwareUpgrade] for
/// post-upgrade reconnect; [standard] matches the default connect flow.
class BleConnectingDialogMessages {
  final String connectingTitle;
  final String Function(DiscoveredDevice device) connectingSubtitle;
  final String connectedTitle;
  final String connectedSubtitle;
  final String handshakeCompleteSubtitle;

  const BleConnectingDialogMessages({
    required this.connectingTitle,
    required this.connectingSubtitle,
    required this.connectedTitle,
    required this.connectedSubtitle,
    required this.handshakeCompleteSubtitle,
  });

  static final standard = BleConnectingDialogMessages(
    connectingTitle: StringConstants.establishingSecureConnection,
    connectingSubtitle:
        (device) => 'Please wait while we connect to ${device.name}',
    connectedTitle: 'Device Connected!',
    connectedSubtitle: StringConstants.encryptingAndAuthenticating,
    handshakeCompleteSubtitle: StringConstants.preparing,
  );

  static final afterFirmwareUpgrade = BleConnectingDialogMessages(
    connectingTitle: StringConstants.reconnecting,
    connectingSubtitle:
        (_) =>
            'Device is restarting. Searching for panel and establishing connection...',
    connectedTitle: 'Device Connected!',
    connectedSubtitle: StringConstants.encryptingAndAuthenticating,
    handshakeCompleteSubtitle: StringConstants.preparing,
  );
}

/// Shows the connecting dialog while [operation] runs. Pops automatically when
/// [operation] completes (success or failure).
Future<T?> runWithBleConnectingDialog<T>({
  required BuildContext context,
  required DiscoveredDevice device,
  required BleLogController bleController,
  required Future<T?> Function() operation,
  BleConnectingDialogMessages? messages,
  bool useRootNavigator = true,
  VoidCallback? onErrorDismiss,
}) async {
  if (!context.mounted) return null;

  final resolvedMessages = messages ?? BleConnectingDialogMessages.standard;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: useRootNavigator,
      builder:
          (dialogContext) => BleConnectingDialog(
            device: device,
            bleController: bleController,
            messages: resolvedMessages,
            onErrorDismiss: onErrorDismiss,
          ),
    ),
  );

  // Let the dialog mount before BLE state updates begin.
  await Future.delayed(const Duration(milliseconds: 100));

  T? result;
  try {
    result = await operation();
    if (bleController.bleManager.handshakeCompleteNotifier.value &&
        !bleController.bleManager.maxBleConnectionRetriesReached.value) {
      await Future.delayed(const Duration(milliseconds: 400));
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: useRootNavigator).pop();
    }
  }
  return result;
}

class BleConnectingDialog extends StatefulWidget {
  const BleConnectingDialog({
    super.key,
    required this.device,
    required this.bleController,
    required this.messages,
    this.onErrorDismiss,
  });

  final DiscoveredDevice device;
  final BleLogController bleController;
  final BleConnectingDialogMessages messages;
  final VoidCallback? onErrorDismiss;

  @override
  State<BleConnectingDialog> createState() => _BleConnectingDialogState();
}

class _BleConnectingDialogState extends State<BleConnectingDialog> {
  @override
  Widget build(BuildContext context) {
    final bleManager = widget.bleController.bleManager;
    final bleProcess = widget.bleController.bleProcess;
    final messages = widget.messages;

    final connectionNotifier = bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier = bleManager.handshakeCompleteNotifier;
    final maxRetriesNotifier = bleManager.maxBleConnectionRetriesReached;
    final networkCommFailureNotifier = bleProcess.communicationFailureMessage;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
      maxRetriesNotifier,
      networkCommFailureNotifier,
    ]);

    return ListenableBuilder(
      listenable: mergedListenable,
      builder: (dialogContext, _) {
        final isConnected = connectionNotifier.value;
        final handshakeComplete = handshakeCompleteNotifier.value;
        final maxRetries = maxRetriesNotifier.value;
        final networkCommMessage = networkCommFailureNotifier.value;
        final showNetworkCommError =
            networkCommMessage != null && networkCommMessage.isNotEmpty;
        final showConnectionError = maxRetries || showNetworkCommError;

        final title =
            showNetworkCommError
                ? StringConstants.connectionProblem
                : maxRetries
                ? StringConstants.maxConnectionRetriesReached
                : handshakeComplete
                ? messages.connectedTitle
                : isConnected
                ? messages.connectedTitle
                : messages.connectingTitle;

        final subtitle =
            maxRetries
                ? StringConstants.pleaseScanAgainAndReconnect
                : showNetworkCommError
                ? networkCommMessage
                : handshakeComplete
                ? messages.handshakeCompleteSubtitle
                : isConnected
                ? messages.connectedSubtitle
                : messages.connectingSubtitle(widget.device);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    color:
                        handshakeComplete && !showConnectionError
                            ? Colors.green.withValues(alpha: 0.1)
                            : showNetworkCommError
                            ? ColorConstants.errorIconBackground
                            : ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        handshakeComplete && !showConnectionError
                            ? const Icon(
                              Icons.check_circle,
                              size: 32,
                              color: Colors.green,
                            )
                            : showNetworkCommError
                            ? const Icon(
                              Icons.error_outline,
                              size: 32,
                              color: ColorConstants.primary,
                            )
                            : Lottie.asset(
                              AssetConstants.bleConnectingJson,
                              animate: !showConnectionError,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (showConnectionError)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.5),
                        ),
                      ),
                      onPressed: () {
                        if (showNetworkCommError) {
                          bleProcess.clearCommunicationFailure();
                        }
                        widget.onErrorDismiss?.call();
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        StringConstants.ok,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
