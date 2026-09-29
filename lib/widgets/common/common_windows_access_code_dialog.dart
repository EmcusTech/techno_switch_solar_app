import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/ble/ble_process.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:Technoswitch/widgets/common/access_code_success_lottie_widget.dart';
import 'package:Technoswitch/widgets/common/access_code_verifying_lottie_widget.dart';
import 'package:Technoswitch/widgets/common/common_cta_button.dart';

enum _AccessCodeStatus { empty, verifying, success, error }

/// Centered access-code dialog for Windows. The code is typed on the keyboard.
class CommonWindowsAccessCodeDialog extends StatefulWidget {
  const CommonWindowsAccessCodeDialog({
    super.key,
    required this.bleProcess,
    required this.onStartValidation,
    required this.sheetContext,
    this.onAccessGranted,
    this.successCloseDelay = const Duration(milliseconds: 400),
    this.persistSessionAccessCode = true,
  });

  final BleProcess bleProcess;
  final Future<void> Function() onStartValidation;
  final BuildContext sheetContext;
  final Future<void> Function()? onAccessGranted;
  final Duration successCloseDelay;
  final bool persistSessionAccessCode;

  @override
  State<CommonWindowsAccessCodeDialog> createState() =>
      _CommonWindowsAccessCodeDialogState();
}

class _CommonWindowsAccessCodeDialogState
    extends State<CommonWindowsAccessCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _closing = false;

  static const int _maxLength = 8;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncAccessKeyFromController() {
    final bleProcess = widget.bleProcess;
    final wasWrong = bleProcess.isAccessKeyValid.value == false;
    bleProcess.accessKey.value = _controller.text;
    bleProcess.isAccessKeyValid.value = null;
    if (wasWrong) {
      bleProcess.processDesc.value = '';
    }
  }

  void _clearErrorStateIfNeeded() {
    final bleProcess = widget.bleProcess;
    if (bleProcess.isAccessKeyValid.value == false) {
      bleProcess.processDesc.value = '';
      bleProcess.isAccessKeyValid.value = null;
    }
  }

  Future<void> _onVerify() async {
    final bleProcess = widget.bleProcess;
    if (_controller.text.trim().isEmpty) return;

    bleProcess.isAccessKeyValid.value = null;
    bleProcess.processDesc.value = StringConstants.validating;
    bleProcess.accessKey.value = _controller.text;
    await widget.onStartValidation();
    if (bleProcess.processDesc.value.isEmpty) {
      bleProcess.processDesc.value = StringConstants.validating;
    }
  }

  bool _isLocked(_AccessCodeStatus status) {
    return status == _AccessCodeStatus.verifying ||
        status == _AccessCodeStatus.success ||
        _closing;
  }

  void _onClose() {
    if (_closing) return;
    widget.bleProcess.clearCommunicationFailure();
    final sheetContext = widget.sheetContext;
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop(false);
    }
  }

  void _onChanged(String _) {
    _clearErrorStateIfNeeded();
    _syncAccessKeyFromController();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bleProcess = widget.bleProcess;

    return ValueListenableBuilder<bool?>(
      valueListenable: bleProcess.isAccessKeyValid,
      builder: (context, isAccessKeyValidValue, _) {
        if (isAccessKeyValidValue == true && !_closing) {
          _closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(widget.successCloseDelay);
            if (!mounted) return;
            if (widget.onAccessGranted != null) {
              await widget.onAccessGranted!();
              return;
            }
            if (widget.persistSessionAccessCode) {
              bleProcess.setSessionAccessCode(bleProcess.accessKey.value);
            }
            final sheetContext = widget.sheetContext;
            if (sheetContext.mounted) {
              Navigator.of(sheetContext, rootNavigator: true).pop(true);
            }
          });
        }

        return ValueListenableBuilder<String?>(
          valueListenable: bleProcess.communicationFailureMessage,
          builder: (context, commFailure, _) {
            final commFailed = commFailure != null && commFailure.isNotEmpty;

            return ValueListenableBuilder<String>(
              valueListenable: bleProcess.processDesc,
              builder: (context, processDescValue, _) {
                var hideInput =
                    (processDescValue.isNotEmpty &&
                        isAccessKeyValidValue != false) ||
                    isAccessKeyValidValue == true;

                final _AccessCodeStatus status;
                if (commFailed) {
                  status = _AccessCodeStatus.error;
                  hideInput = true;
                } else if (isAccessKeyValidValue == true) {
                  status = _AccessCodeStatus.success;
                } else if (hideInput) {
                  status = _AccessCodeStatus.verifying;
                } else if (isAccessKeyValidValue == false) {
                  status = _AccessCodeStatus.error;
                } else {
                  status = _AccessCodeStatus.empty;
                }

                final showVerify =
                    !commFailed &&
                    !_closing &&
                    isAccessKeyValidValue != true &&
                    (processDescValue.isEmpty ||
                        isAccessKeyValidValue == false) &&
                    !hideInput;

                String? message;
                if (commFailed) {
                  message = commFailure;
                } else if (isAccessKeyValidValue == false) {
                  message =
                      processDescValue.isNotEmpty
                          ? processDescValue
                          : StringConstants.wrongPassword;
                }

                if (!commFailed &&
                    isAccessKeyValidValue == false &&
                    _controller.text.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _controller.text.isNotEmpty) {
                      _controller.clear();
                      bleProcess.accessKey.value = '';
                      setState(() {});
                    }
                  });
                }

                return _buildDialog(
                  hideInput: hideInput,
                  showVerify: showVerify,
                  message: message,
                  isError: commFailed || isAccessKeyValidValue == false,
                  status: status,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDialog({
    required bool hideInput,
    required bool showVerify,
    required String? message,
    required bool isError,
    required _AccessCodeStatus status,
  }) {
    final locked = _isLocked(status);
    final borderColor =
        isError ? ColorConstants.primary : ColorConstants.borderLight;

    return PopScope(
      canPop: !locked,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      locked
                          ? const SizedBox(height: 38, width: 38)
                          : IconButton(
                            onPressed: _onClose,
                            icon: const Icon(Icons.close, size: 20),
                          ),
                ),
                _buildHeader(status, isError),
                const SizedBox(height: 24),
                if (!hideInput)
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    obscureText: true,
                    maxLength: _maxLength,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: StyleConstants.textDark24w600Style,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onChanged,
                    onSubmitted: (_) {
                      if (showVerify && _controller.text.trim().isNotEmpty) {
                        _onVerify();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: StringConstants.strca4d661a,
                      hintStyle: StyleConstants.borderLight24w600Style,
                      counterText: '',
                      filled: true,
                      fillColor: ColorConstants.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: ColorConstants.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: StyleConstants.primary14w600Style.copyWith(
                      color:
                          isError
                              ? ColorConstants.primary
                              : ColorConstants.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (showVerify) ...[
                  const SizedBox(height: 18),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final canVerify = _controller.text.trim().isNotEmpty;
                      return CommonCtaButton(
                        isDisabled: !canVerify,
                        onTap: canVerify ? _onVerify : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: ColorConstants.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StringConstants.verify,
                              style: StyleConstants.white14boldStyle,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_AccessCodeStatus status, bool isError) {
    switch (status) {
      case _AccessCodeStatus.verifying:
        return Column(
          children: [
            const AccessCodeVerifyingLottieWidget(key: ValueKey('verifying')),
            Text(
              StringConstants.verifyingAccess,
              style: StyleConstants.textDark14w600Style,
            ),
          ],
        );
      case _AccessCodeStatus.success:
        return Column(
          children: [
            const AccessCodeSuccessLottieWidget(key: ValueKey('success')),
            Text(
              StringConstants.accessGranted,
              style: StyleConstants.textDark14w600Style,
            ),
          ],
        );
      case _AccessCodeStatus.empty:
      case _AccessCodeStatus.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.primary,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: ColorConstants.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 1,
                    blurStyle: BlurStyle.solid,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SvgPicture.asset(AssetConstants.lockIconWhiteSvg),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isError
                  ? StringConstants.deviceNotResponding2
                  : StringConstants.enterAccessCode,
              textAlign: TextAlign.center,
              style: StyleConstants.black20w600Style,
            ),
          ],
        );
    }
  }
}
