import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/widgets/common/access_code_success_lottie_widget.dart';
import 'package:techno_switch_solar_app/widgets/common/access_code_verifying_lottie_widget.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import 'package:techno_switch_solar_app/widgets/common/common_numeric_keypad_tile_widget.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
enum ValidatingStatus { empty, verifying, success, error }

class CommonNumericKeypadWidget extends StatefulWidget {
  const CommonNumericKeypadWidget({
    super.key,
    this.bleProcess,
    this.onStartValidation,
    this.sheetContext,
    this.onAccessGranted,
    this.successCloseDelay = const Duration(milliseconds: 400),
    this.persistSessionAccessCode = true,
  });

  final BleProcess? bleProcess;
  final Future<void> Function()? onStartValidation;
  final BuildContext? sheetContext;

  /// When set, runs instead of [BleProcess.setSessionAccessCode] + pop on success.
  final Future<void> Function()? onAccessGranted;

  final Duration successCloseDelay;

  /// When true (default), calls [BleProcess.setSessionAccessCode] on success.
  final bool persistSessionAccessCode;

  bool get _isGatewayMode =>
      bleProcess != null && onStartValidation != null && sheetContext != null;

  @override
  State<CommonNumericKeypadWidget> createState() =>
      _CommonNumericKeypadWidgetState();
}

class _CommonNumericKeypadWidgetState extends State<CommonNumericKeypadWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _closing = false;

  static const Duration _animDuration = Duration(milliseconds: 280);

  BleProcess? get _bleProcess => widget.bleProcess;
  BuildContext? get _sheetContext => widget.sheetContext;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAccessKeyFromController() {
    final bleProcess = _bleProcess;
    if (bleProcess == null) return;

    final accessKey = bleProcess.accessKey;
    final wasWrong = bleProcess.isAccessKeyValid.value == false;
    accessKey.value = _controller.text;
    bleProcess.isAccessKeyValid.value = null;
    if (wasWrong) {
      bleProcess.processDesc.value = '';
    }
  }

  void _clearErrorStateIfNeeded() {
    final bleProcess = _bleProcess;
    if (bleProcess == null) return;
    if (bleProcess.isAccessKeyValid.value == false) {
      bleProcess.processDesc.value = '';
      bleProcess.isAccessKeyValid.value = null;
    }
  }

  Future<void> _onVerify() async {
    final bleProcess = _bleProcess;
    final onStartValidation = widget.onStartValidation;
    if (bleProcess == null || onStartValidation == null) return;
    if (_controller.text.trim().isEmpty) return;

    bleProcess.isAccessKeyValid.value = null;
    bleProcess.processDesc.value = StringConstants.validating;
    bleProcess.accessKey.value = _controller.text;
    await onStartValidation();
    if (bleProcess.processDesc.value.isEmpty) {
      bleProcess.processDesc.value = StringConstants.validating;
    }
  }

  bool _isSheetLocked(ValidatingStatus validatingStatus) {
    return validatingStatus == ValidatingStatus.verifying ||
        validatingStatus == ValidatingStatus.success ||
        _closing;
  }

  void _onClose() {
    if (_closing) return;
    _bleProcess?.clearCommunicationFailure();
    final sheetContext = _sheetContext;
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.of(sheetContext).pop(false);
      return;
    }
    Navigator.of(context).pop();
  }

  void _updateAccessController({
    String? value,
    bool isClear = false,
    bool isDelete = false,
  }) {
    _clearErrorStateIfNeeded();

    if (isClear) {
      _controller.clear();
      _syncAccessKeyFromController();
      setState(() {});
      return;
    }
    if (isDelete) {
      _deleteLastCharacter();
      _syncAccessKeyFromController();
      setState(() {});
      return;
    }
    if (_controller.text.length >= 8) return;

    final newText = _controller.text + (value ?? '');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _syncAccessKeyFromController();
    setState(() {});
  }

  void _deleteLastCharacter() {
    if (_controller.text.isEmpty) return;
    final newText = _controller.text.substring(0, _controller.text.length - 1);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isGatewayMode) {
      return _buildGatewaySheet(context);
    }
    return _buildSheetContent(
      context: context,
      hideInput: false,
      showKeypad: true,
      showVerify: true,
      status: null,
      isErrorStatus: false,
      fieldBorderIsError: false,
      validatingStatus: ValidatingStatus.empty,
    );
  }

  Widget _buildGatewaySheet(BuildContext context) {
    final bleProcess = _bleProcess!;
    final accessKey = bleProcess.accessKey;
    final isAccessKeyValid = bleProcess.isAccessKeyValid;

    return ValueListenableBuilder<bool?>(
      valueListenable: isAccessKeyValid,
      builder: (context, isAccessKeyValidValue, __) {
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
              bleProcess.setSessionAccessCode(accessKey.value);
            }
            final sheetContext = _sheetContext;
            if (sheetContext != null && sheetContext.mounted) {
              Navigator.of(sheetContext, rootNavigator: true).pop(true);
            }
          });
        }

        return ValueListenableBuilder<String?>(
          valueListenable: bleProcess.communicationFailureMessage,
          builder: (context, commFailure, __) {
            final bool commFailed =
                commFailure != null && commFailure.isNotEmpty;

            return ValueListenableBuilder<String>(
              valueListenable: bleProcess.processDesc,
              builder: (context, processDescValue, __) {
                var hideInput =
                    (processDescValue.isNotEmpty &&
                        isAccessKeyValidValue != false) ||
                    isAccessKeyValidValue == true;

                ValidatingStatus validatingStatus;
                if (commFailed) {
                  validatingStatus = ValidatingStatus.error;
                  hideInput = true;
                } else if (isAccessKeyValidValue == true) {
                  validatingStatus = ValidatingStatus.success;
                } else if (hideInput) {
                  validatingStatus = ValidatingStatus.verifying;
                } else if (isAccessKeyValidValue == false) {
                  validatingStatus = ValidatingStatus.error;
                } else {
                  validatingStatus = ValidatingStatus.empty;
                }

                final showKeypad =
                    !commFailed &&
                    !_closing &&
                    isAccessKeyValidValue != true &&
                    (processDescValue.isEmpty ||
                        isAccessKeyValidValue == false);

                final showVerify = showKeypad;

                String? status;
                if (commFailed) {
                  status = commFailure;
                } else if (isAccessKeyValidValue == false) {
                  status =
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
                      accessKey.value = '';
                      setState(() {});
                    }
                  });
                }

                return _buildSheetContent(
                  context: context,
                  hideInput: hideInput,
                  showKeypad: showKeypad && !hideInput,
                  showVerify: showVerify && !hideInput,
                  status: status,
                  isErrorStatus: commFailed || isAccessKeyValidValue == false,
                  fieldBorderIsError:
                      commFailed || isAccessKeyValidValue == false,
                  validatingStatus: validatingStatus,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSheetContent({
    required BuildContext context,
    required bool hideInput,
    required bool showKeypad,
    required bool showVerify,
    required String? status,
    required bool isErrorStatus,
    required bool fieldBorderIsError,
    required ValidatingStatus validatingStatus,
  }) {
    final maxHeight =
        status != null && status.isNotEmpty
            ? MediaQuery.of(context).size.height * 0.85
            : MediaQuery.of(context).size.height * 0.82;
    final borderColor =
        fieldBorderIsError ? ColorConstants.primary : ColorConstants.borderLight;
    final lockSheet = _isSheetLocked(validatingStatus);

    return PopScope(
      canPop: !lockSheet,
      child: SafeArea(
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeInOutCubic,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: ColorConstants.primaryVariant,
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _dragHandle(),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: _animDuration,
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          child: _buildLockOrLottieHeader(
                            validatingStatus,
                            isErrorStatus,
                          ),
                        ),
                        const SizedBox(height: 26),
                        AnimatedSize(
                          duration: _animDuration,
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child:
                              hideInput
                                  ? const SizedBox.shrink()
                                  : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 26.0,
                                    ),
                                    child: TextField(
                                      controller: _controller,
                                      readOnly: true,
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      maxLength: 8,
                                      textAlign: TextAlign.center,
                                      style: StyleConstants.textDark24w600Style,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        hintText: StringConstants.strca4d661a,
                                        hintStyle: StyleConstants.borderLight24w600Style,
                                        counterText: '',
                                        filled: true,
                                        fillColor: ColorConstants.surfaceLight,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: fieldBorderIsError ? 1 : 2,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: ColorConstants.primary,
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
                                  ),
                        ),
                        AnimatedSize(
                          duration: _animDuration,
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child:
                              status != null && status.isNotEmpty
                                  ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                        ),
                                        child: Text(
                                          status,
                                          style: StyleConstants.primary14w600Style.copyWith(
                                            color: isErrorStatus
                                                    ? ColorConstants.primary
                                                    : ColorConstants.textDark,
                                            ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        AnimatedSize(
                          duration: _animDuration,
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child:
                              showKeypad
                                  ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 18),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 34,
                                        ),
                                        child: GridView.count(
                                          shrinkWrap: true,
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.5,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: _keypadTiles(),
                                        ),
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        AnimatedSize(
                          duration: _animDuration,
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child:
                              showVerify
                                  ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 18),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26.0,
                                        ),
                                        child: ListenableBuilder(
                                          listenable: _controller,
                                          builder: (context, _) {
                                            final canVerify =
                                                _controller.text
                                                    .trim()
                                                    .isNotEmpty;
                                            return CommonCtaButton(
                                              isDisabled: !canVerify,
                                              onTap:
                                                  canVerify ? _onVerify : null,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.verified,
                                                    color: ColorConstants.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Verify',
                                                    style: StyleConstants.white14boldStyle,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                  : const SizedBox(height: 16),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(AssetConstants.bottomsheetLogo),
                      if (!lockSheet)
                        Padding(
                          padding: const EdgeInsets.only(right: 32.0),
                          child: GestureDetector(
                            onTap: _onClose,
                            child: Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorConstants.blackMaterial.withValues(alpha: 0.06),
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 70),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  List<Widget> _keypadTiles() {
    return [
      _digitTile('1'),
      _digitTile('2'),
      _digitTile('3'),
      _digitTile('4'),
      _digitTile('5'),
      _digitTile('6'),
      _digitTile('7'),
      _digitTile('8'),
      _digitTile('9'),
      CommonNumericKeypadTileWidget(
        isClear: true,
        onTap: () => _updateAccessController(isClear: true),
      ),
      _digitTile('0'),
      CommonNumericKeypadTileWidget(
        isDelete: true,
        fillColor: ColorConstants.colorFffaefef,
        onTap: () => _updateAccessController(isDelete: true),
      ),
    ];
  }

  Widget _digitTile(String digit) {
    return CommonNumericKeypadTileWidget(
      numericValue: digit,
      onTap: () => _updateAccessController(value: digit),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildLockOrLottieHeader(
    ValidatingStatus validatingStatus,
    bool isError,
  ) {
    switch (validatingStatus) {
      case ValidatingStatus.verifying:
        return Column(
          children: [
            const AccessCodeVerifyingLottieWidget(key: ValueKey('verifying')),
            Text(
              StringConstants.verifyingAccess,
              style: StyleConstants.textDark14w600Style,
            ),
          ],
        );
      case ValidatingStatus.success:
        return Column(
          children: [
            const AccessCodeSuccessLottieWidget(key: ValueKey('success')),
            Text(
              StringConstants.accessGranted,
              style: StyleConstants.textDark14w600Style,
            ),
          ],
        );
      case ValidatingStatus.empty:
      case ValidatingStatus.error:
        return Column(
          key: const ValueKey('enter_access_code'),
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
                padding: const EdgeInsets.all(16.0),
                child: SvgPicture.asset(AssetConstants.lockIconWhiteSvg),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isError ? StringConstants.deviceNotResponding2 : StringConstants.enterAccessCode,
              textAlign: TextAlign.center,
              style: StyleConstants.black20w600Style,
            ),
          ],
        );
    }
  }
}
