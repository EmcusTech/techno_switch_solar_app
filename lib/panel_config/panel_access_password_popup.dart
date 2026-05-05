import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_cache_to_ble.dart';

/// Per-tile cache saves and navigation after access-code verification.
class PanelAccessPasswordDelegates {
  PanelAccessPasswordDelegates({
    required this.saveExtOutCache,
    required this.saveInputCache,
    required this.saveRelayCache,
    required this.saveZoneCache,
    required this.saveRadioCache,
    required this.saveLBusCache,
    required this.saveSounderCache,
    required this.saveServiceDueCache,
    required this.saveAccessCodeCache,
    required this.savePanelInfoCache,
    required this.saveGeneralModuleCache,
    required this.showApplySuccess,
    required this.showDownloadSuccess,
    required this.openLogRetrievalLoading,
    this.afterBulkApplyAccessGranted,
  });

  final Future<void> Function() saveExtOutCache;
  final Future<void> Function() saveInputCache;
  final Future<void> Function() saveRelayCache;
  final Future<void> Function() saveZoneCache;
  final Future<void> Function() saveRadioCache;
  final Future<void> Function() saveLBusCache;
  final Future<void> Function() saveSounderCache;
  final Future<void> Function() saveServiceDueCache;
  final Future<void> Function() saveAccessCodeCache;
  final Future<void> Function() savePanelInfoCache;
  final Future<void> Function() saveGeneralModuleCache;

  final void Function(BuildContext context, String message, {String? subtitle})
  showApplySuccess;
  final void Function(BuildContext context, String message) showDownloadSuccess;

  final void Function(BuildContext dialogContext) openLogRetrievalLoading;

  /// When [isConfigLogBulkApply] succeeds: run apply chain (and optional UI).
  final Future<void> Function()? afterBulkApplyAccessGranted;
}

/// Removes the modal route that contains [routeContext] from its [Navigator].
///
/// [Navigator.pop(context)] always pops the **top** route on that navigator.
/// After bulk apply, delegates may push a success dialog on top; popping would
/// dismiss that dialog and leave the access ("Applying…") route visible.
void _removeOverlayRouteFor(BuildContext routeContext) {
  if (!routeContext.mounted) return;
  final route = ModalRoute.of(routeContext);
  final navigator = route?.navigator;
  if (route != null && navigator != null) {
    navigator.removeRoute(route);
  }
}

Future<void> showPanelAccessPasswordPopup({
  required BuildContext context,
  required bool Function() isMounted,
  required BleManager bleManager,
  required BleLogController bleController,
  required DiscoveredDevice selectedDevice,
  required ValueNotifier<bool> navigatingToDeviceConnecting,
  required PanelAccessPasswordDelegates delegates,
  required VoidCallback onCall,
  bool isExtOut = false,
  bool isInputSetup = false,
  bool isRelaySetup = false,
  bool isZoneSetup = false,
  bool isLBusSetup = false,
  bool isSounderSetup = false,
  bool isServiceDueSetup = false,
  bool isAccessCodeSetup = false,
  bool isPanelInfoSetup = false,
  bool isGeneralModuleSetup = false,
  bool isAdcSetup = false,
  bool isConfigLogBulk = false,
  bool isConfigLogBulkApply = false,
  /// When false (e.g. dashboard Config tile), bulk config uses generic copy only,
  /// not live [BleProcess.processDesc] strings in the access dialog.
  bool showDetailedConfigLogBulkBleProgressInAccessDialog = true,
  String? mode,
  Future<void> Function()? onDownloadComplete,
  String? downloadSuccessMessage,
  ValueNotifier<bool>? configLogWorking,
}) {
  final bleProcess = bleManager.bleProcess;
  final bool useCachedSessionAccess =
      bleProcess.sessionAccessCodeReady.value &&
      bleProcess.accessKey.value.isNotEmpty;

  navigatingToDeviceConnecting.value = false;

  bleProcess.isAccessKeyValid.value = null;
  if (useCachedSessionAccess) {
    bleProcess.processDesc.value = 'Validating';
  } else {
    bleProcess.accessKey.value = '';
    bleProcess.processDesc.value = '';
  }

  Timer? accessKeyValidationTimer;
  void cancelAccessKeyTimer() {
    accessKeyValidationTimer?.cancel();
    accessKeyValidationTimer = null;
  }

  /// Prevents scheduling [afterBulkApplyAccessGranted] twice when access stays
  /// valid but [navigatingToDeviceConnecting] is reset in the bulk `finally`
  /// (duplicate [ValueListenableBuilder] rebuilds would otherwise enqueue
  /// another post-frame bulk apply).
  var configLogBulkApplyChainScheduled = false;

  final TextEditingController accessController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final accessKey = bleProcess.accessKey;
  final ValueNotifier<bool?> isAccessKeyValid = bleProcess.isAccessKeyValid;

  final dialogFuture = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool?>(
                valueListenable: isAccessKeyValid,
                builder: (_, isAccessKeyValidValue, __) {
                  return ValueListenableBuilder<String>(
                    valueListenable: bleProcess.processDesc,
                    builder: (_, processDescValue, __) {
                      final bool hideInput =
                          (processDescValue.isNotEmpty &&
                              isAccessKeyValidValue != false) ||
                          isAccessKeyValidValue == true;
                      final Color iconColor =
                          hideInput
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFEC1D24);
                      final Color circleColor =
                          hideInput
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFBDEE1);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/svgs/lock_icon.svg',
                            height: 32,
                            width: 32,
                            colorFilter: ColorFilter.mode(
                              iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool?>(
                valueListenable: isAccessKeyValid,
                builder: (_, isAccessKeyValidValue, __) {
                  if (isAccessKeyValidValue != null) {
                    cancelAccessKeyTimer();
                  }
                  if (isConfigLogBulkApply && mode == 'bottomsheet_apply') {
                    if (isAccessKeyValidValue != true) {
                      configLogBulkApplyChainScheduled = false;
                    }
                  }
                  if (isAccessKeyValidValue == true &&
                      !navigatingToDeviceConnecting.value &&
                      !(isConfigLogBulkApply &&
                          mode == 'bottomsheet_apply' &&
                          configLogBulkApplyChainScheduled)) {
                    if (isConfigLogBulkApply && mode == 'bottomsheet_apply') {
                      configLogBulkApplyChainScheduled = true;
                    }
                    navigatingToDeviceConnecting.value = true;
                    bleProcess.setSessionAccessCode(bleProcess.accessKey.value);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!isMounted()) return;
                      await Future.delayed(const Duration(seconds: 1));
                      if (!isMounted()) return;

                      Future<void> afterAccessDialogPopped() async {
                        if (mode == 'bottomsheet_download') {
                          await onDownloadComplete?.call();
                          if (isMounted()) {
                            final message =
                                downloadSuccessMessage ??
                                (isExtOut == true
                                    ? 'Extinguishing Output'
                                    : isInputSetup == true
                                    ? 'Inputs'
                                    : isRelaySetup == true
                                    ? 'Relays'
                                    : isZoneSetup == true
                                    ? 'Zones'
                                    : isSounderSetup == true
                                    ? 'Sounders'
                                    : isServiceDueSetup == true
                                    ? 'Service Due'
                                    : isAccessCodeSetup == true
                                    ? 'Access Code'
                                    : isPanelInfoSetup == true
                                    ? 'Panel Info'
                                    : isGeneralModuleSetup == true
                                    ? 'General Module'
                                    : isAdcSetup == true
                                    ? 'Diagnostics'
                                    : 'Configuration');
                            delegates.showDownloadSuccess(context, message);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (isMounted()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            });
                          }
                        } else if (isExtOut &&
                            bleManager.bleProcess.isExtOutApplyDone.value) {
                          bleManager.bleProcess.isExtOutApplyButtonActive.value =
                              true;
                          await delegates.saveExtOutCache();
                          if (isMounted()) {
                            delegates.showApplySuccess(
                              context,
                              'Extinguishing Output',
                            );
                          }
                        } else if (isInputSetup &&
                            bleManager.bleProcess.isInputSetupApplyDone.value) {
                          await delegates.saveInputCache();
                          if (isMounted()) {
                            delegates.showApplySuccess(context, 'Inputs');
                          }
                        } else if (isRelaySetup &&
                            bleManager.bleProcess.isRelaySetupApplyDone.value &&
                            isMounted()) {
                          await delegates.saveRelayCache();
                          delegates.showApplySuccess(context, 'Relays');
                        } else if (isZoneSetup &&
                            bleManager.bleProcess.isRadioSetupApplyDone.value &&
                            isMounted()) {
                          await delegates.saveRadioCache();
                          delegates.showApplySuccess(context, 'Radio');
                        } else if (isZoneSetup &&
                            bleManager.bleProcess.isZoneSetupApplyDone.value &&
                            isMounted()) {
                          await delegates.saveZoneCache();
                          delegates.showApplySuccess(context, 'Zones');
                        } else if (isLBusSetup &&
                            bleManager.bleProcess.isLBusSetupApplyDone.value &&
                            isMounted()) {
                          await delegates.saveLBusCache();
                          delegates.showApplySuccess(context, 'L-Bus');
                        } else if (isSounderSetup &&
                            bleManager
                                .bleProcess
                                .isSounderSetupApplyDone
                                .value &&
                            isMounted()) {
                          await delegates.saveSounderCache();
                          delegates.showApplySuccess(context, 'Sounders');
                        } else if (isServiceDueSetup &&
                            bleManager.bleProcess.isServiceDueApplyDone.value &&
                            isMounted()) {
                          await delegates.saveServiceDueCache();
                          delegates.showApplySuccess(context, 'Service Due');
                        } else if (isAccessCodeSetup &&
                            bleManager
                                .bleProcess
                                .isAccessCodeSetupApplyDone
                                .value &&
                            isMounted()) {
                          await delegates.saveAccessCodeCache();
                          delegates.showApplySuccess(context, 'Access Code');
                        } else if (isPanelInfoSetup &&
                            bleManager
                                .bleProcess
                                .isPanelInfoSetupApplyDone
                                .value &&
                            isMounted()) {
                          await delegates.savePanelInfoCache();
                          delegates.showApplySuccess(context, 'Panel Info');
                        } else if (isGeneralModuleSetup &&
                            bleManager
                                .bleProcess
                                .isGeneralModuleSetupApplyDone
                                .value &&
                            isMounted()) {
                          await delegates.saveGeneralModuleCache();
                          delegates.showApplySuccess(context, 'General Module');
                        } else {
                          delegates.openLogRetrievalLoading(dialogContext);
                        }
                      }

                      if (isConfigLogBulkApply &&
                          mode == 'bottomsheet_apply') {
                        configLogWorking?.value = true;
                        try {
                          await delegates.afterBulkApplyAccessGranted?.call();
                        } catch (e, st) {
                          debugPrint('$e\n$st');
                          if (isMounted()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not apply configuration: $e',
                                ),
                              ),
                            );
                          }
                        } finally {
                          configLogWorking?.value = false;
                          _removeOverlayRouteFor(dialogContext);
                          navigatingToDeviceConnecting.value = false;
                        }
                        return;
                      }

                      if (mode == 'bottomsheet_download' && isConfigLogBulk) {
                        configLogWorking?.value = true;
                        var accessDialogClosed = false;
                        void closeAccessDialog() {
                          if (accessDialogClosed) return;
                          accessDialogClosed = true;
                          _removeOverlayRouteFor(dialogContext);
                        }
                        try {
                          await onDownloadComplete?.call();
                          if (isMounted()) {
                            final message =
                                downloadSuccessMessage ?? 'Configuration';
                            closeAccessDialog();
                            delegates.showDownloadSuccess(context, message);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (isMounted()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            });
                          }
                        } catch (e, st) {
                          debugPrint('$e\n$st');
                          if (isMounted()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not download configuration: $e',
                                ),
                              ),
                            );
                          }
                        } finally {
                          configLogWorking?.value = false;
                          navigatingToDeviceConnecting.value = false;
                          closeAccessDialog();
                        }
                        return;
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(
                          dialogContext,
                          rootNavigator: true,
                        ).pop();
                      }
                      await afterAccessDialogPopped();
                    });
                  }

                  return ValueListenableBuilder<String>(
                    valueListenable: bleProcess.processDesc,
                    builder: (_, processDescValue, __) {
                      final bool hideInput =
                          (processDescValue.isNotEmpty &&
                              isAccessKeyValidValue != false) ||
                          isAccessKeyValidValue == true;
                      if (hideInput) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (focusNode.hasFocus) {
                            focusNode.unfocus();
                          }
                        });
                      }

                      const Duration animDuration = Duration(
                        milliseconds: 280,
                      );

                      final String dialogTitle =
                          !hideInput
                              ? 'Enter Access Code'
                              : (isAccessKeyValidValue == true
                                  ? mode == 'bottomsheet_download'
                                      ? 'Downloading...'
                                      : mode == 'bottomsheet_apply'
                                      ? 'Applying...'
                                      : 'Validated'
                                  : (processDescValue == 'Validating' ||
                                      processDescValue.toLowerCase().contains(
                                        'validat',
                                      ))
                                  ? (bleProcess.sessionAccessCodeReady.value
                                      ? 'Initiating'
                                      : 'Verifying access')
                                  : (mode == 'bottomsheet_download'
                                      ? 'Downloading...'
                                      : mode == 'bottomsheet_apply'
                                      ? 'Applying...'
                                      : 'Validated'));

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: AnimatedSwitcher(
                              duration: animDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                dialogTitle,
                                key: ValueKey<String>(dialogTitle),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3D3D3D),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: animDuration,
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.hardEdge,
                            child:
                                hideInput
                                    ? const SizedBox.shrink()
                                    : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 24),
                                        TextField(
                                          controller: accessController,
                                          focusNode: focusNode,
                                          keyboardType: TextInputType.number,
                                          obscureText: true,
                                          maxLength: 8,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 8,
                                            color: const Color(0xFF3D3D3D),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onTap: () {
                                            if (bleProcess
                                                    .isAccessKeyValid
                                                    .value ==
                                                false) {
                                              bleProcess.processDesc.value = '';
                                              bleProcess.isAccessKeyValid.value =
                                                  null;
                                            }
                                          },
                                          onChanged: (val) {
                                            final wasWrong =
                                                bleProcess
                                                    .isAccessKeyValid
                                                    .value ==
                                                false;
                                            accessKey.value = val;
                                            bleProcess.isAccessKeyValid.value =
                                                null;
                                            if (wasWrong) {
                                              bleProcess.processDesc.value = '';
                                            }
                                          },
                                          decoration: InputDecoration(
                                            hintText: '••••••••',
                                            hintStyle: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 8,
                                              color: const Color(0xFFD0D0D0),
                                            ),
                                            counterText: '',
                                            filled: true,
                                            fillColor: const Color(0xFFF8F8F8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color:
                                                    isAccessKeyValidValue ==
                                                            false
                                                        ? const Color(
                                                          0xFFEC1D24,
                                                        )
                                                        : const Color(
                                                          0xFFD0D0D0,
                                                        ),
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color:
                                                    isAccessKeyValidValue ==
                                                            false
                                                        ? const Color(
                                                          0xFFEC1D24,
                                                        )
                                                        : const Color(
                                                          0xFFD0D0D0,
                                                        ),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFEC1D24),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFEC1D24),
                                                width: 1,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12,
                                                      ),
                                                  borderSide:
                                                      const BorderSide(
                                                        color: Color(
                                                          0xFFEC1D24,
                                                        ),
                                                        width: 2,
                                                      ),
                                                ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                          ),
                          Builder(
                            builder: (context) {
                              String? status;
                              if (isAccessKeyValidValue == false) {
                                status =
                                    processDescValue.isNotEmpty
                                        ? processDescValue
                                        : 'Wrong password. Try again.';
                              } else if (isAccessKeyValidValue == null &&
                                  (processDescValue.isNotEmpty ||
                                      accessController.text.isNotEmpty)) {
                                final bool validatingLike =
                                    processDescValue == 'Validating' ||
                                    processDescValue.toLowerCase().contains(
                                      'validat',
                                    );
                                status =
                                    processDescValue.isNotEmpty
                                        ? (bleProcess
                                                    .sessionAccessCodeReady
                                                    .value &&
                                                validatingLike
                                            ? ''
                                            : processDescValue)
                                        : 'Validating...';
                              } else if (isAccessKeyValidValue == true) {
                                final bool bulkOp =
                                    isConfigLogBulk || isConfigLogBulkApply;
                                if (bulkOp &&
                                    showDetailedConfigLogBulkBleProgressInAccessDialog) {
                                  if (processDescValue.isNotEmpty &&
                                      processDescValue != 'Success') {
                                    status = processDescValue;
                                  } else {
                                    status =
                                        mode == 'bottomsheet_download'
                                            ? 'Downloading configuration…'
                                            : 'Applying configuration to panel…';
                                  }
                                } else if (bulkOp &&
                                    !showDetailedConfigLogBulkBleProgressInAccessDialog) {
                                  status =
                                      mode == 'bottomsheet_download'
                                          ? 'Downloading configuration…'
                                          : 'Applying configuration to panel…';
                                } else {
                                  status =
                                      mode == 'bottomsheet_download'
                                          ? 'Processing...'
                                          : mode == 'bottomsheet_apply'
                                          ? 'Processing...'
                                          : 'Fetching...';
                                  if (isMounted()) {
                                    bleProcess.processDesc.value = 'Success';
                                  }
                                }
                              }
                              if (isAccessKeyValidValue == false) {
                                if (accessController.text.isNotEmpty) {
                                  accessController.clear();
                                }
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (focusNode.canRequestFocus) {
                                    focusNode.requestFocus();
                                  }
                                });
                              }
                              return status == null || status.isEmpty
                                  ? const SizedBox(height: 8)
                                  : Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                      top: 12,
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isAccessKeyValidValue == false
                                                ? const Color(0xFFEC1D24)
                                                : const Color(0xFF3D3D3D),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                            },
                          ),
                          ValueListenableBuilder<String>(
                            valueListenable: bleProcess.processDesc,
                            builder: (_, processDescForButtons, __) {
                              final bool showButtons =
                                  isAccessKeyValidValue != true &&
                                  (processDescForButtons.isEmpty ||
                                      isAccessKeyValidValue == false);
                              return showButtons
                                  ? Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 48,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFEC1D24),
                                                  side: const BorderSide(
                                                    color: Color(0xFFEC1D24),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  cancelAccessKeyTimer();
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: SizedBox(
                                              height: 48,
                                              child: ListenableBuilder(
                                                listenable: accessController,
                                                builder: (context, _) {
                                                  final canVerify =
                                                      accessController.text
                                                          .trim()
                                                          .isNotEmpty;
                                                  return ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFEC1D24,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        canVerify
                                                            ? () async {
                                                              FocusScope.of(
                                                                dialogContext,
                                                              ).unfocus();

                                                              bleProcess
                                                                      .isAccessKeyValid
                                                                      .value =
                                                                  null;
                                                              bleProcess
                                                                      .processDesc
                                                                      .value =
                                                                  'Validating';

                                                              accessKey
                                                                      .value =
                                                                  accessController
                                                                      .text;

                                                              if (isConfigLogBulkApply &&
                                                                  mode ==
                                                                      'bottomsheet_apply') {
                                                                await PeripheralCacheToBle.applyToBleManager(
                                                                  bleManager,
                                                                  selectedDevice
                                                                      .id,
                                                                );
                                                              }

                                                              onCall();
                                                            }
                                                            : null,
                                                    child: Text(
                                                      'Verify',
                                                      style:
                                                          GoogleFonts.inter(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (useCachedSessionAccess) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isMounted()) return;
      if (isConfigLogBulkApply && mode == 'bottomsheet_apply') {
        await PeripheralCacheToBle.applyToBleManager(
          bleManager,
          selectedDevice.id,
        );
      }
      if (!isMounted()) return;
      onCall();
      if (bleProcess.processDesc.value.isEmpty) {
        bleProcess.processDesc.value = 'Validating';
      }
    });
  }

  return dialogFuture.then((_) {});
}
