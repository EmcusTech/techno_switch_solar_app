import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

/// Shared "Enter Access Code" dialog. On successful panel validation, calls
/// [BleProcess.setSessionAccessCode] and pops `true`.
Future<bool> showPanelAccessCodeGatewayDialog({
  required BuildContext context,
  required Future<void> Function() onStartValidation,
}) async {
  final bleController = Get.find<BleLogController>();
  final bleProcess = bleController.bleProcess;

  bleProcess.isAccessKeyValid.value = null;
  bleProcess.accessKey.value = "";
  bleProcess.processDesc.value = "";

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _PanelAccessCodeGatewayBody(
        onStartValidation: onStartValidation,
        bleProcess: bleProcess,
        dialogContext: dialogContext,
      );
    },
  );
  return result ?? false;
}

class _PanelAccessCodeGatewayBody extends StatefulWidget {
  const _PanelAccessCodeGatewayBody({
    required this.onStartValidation,
    required this.bleProcess,
    required this.dialogContext,
  });

  final Future<void> Function() onStartValidation;
  final BleProcess bleProcess;
  final BuildContext dialogContext;

  @override
  State<_PanelAccessCodeGatewayBody> createState() =>
      _PanelAccessCodeGatewayBodyState();
}

class _PanelAccessCodeGatewayBodyState
    extends State<_PanelAccessCodeGatewayBody> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _closing = false;

  static const Duration _animDuration = Duration(milliseconds: 280);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleProcess = widget.bleProcess;
    final accessKey = bleProcess.accessKey;
    final isAccessKeyValid = bleProcess.isAccessKeyValid;

    return ValueListenableBuilder<bool?>(
      valueListenable: isAccessKeyValid,
      builder: (context, isAccessKeyValidValue, __) {
        if (isAccessKeyValidValue == true && !_closing) {
          _closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(seconds: 1));
            if (!mounted) return;
            bleProcess.setSessionAccessCode(accessKey.value);
            if (widget.dialogContext.mounted) {
              Navigator.of(widget.dialogContext, rootNavigator: true).pop(true);
            }
          });
        }
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
                // Lock — matches project_dashboard: red while entering, green when verifying
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
                          duration: _animDuration,
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
                    return ValueListenableBuilder<String>(
                      valueListenable: bleProcess.processDesc,
                      builder: (_, processDescValue, __) {
                        final bool hideInput =
                            (processDescValue.isNotEmpty &&
                                isAccessKeyValidValue != false) ||
                            isAccessKeyValidValue == true;
                        if (hideInput) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_focusNode.hasFocus) {
                              _focusNode.unfocus();
                            }
                          });
                        }

                        final String dialogTitle =
                            !hideInput
                                ? 'Enter Access Code'
                                : (isAccessKeyValidValue == true
                                    ? 'Success'
                                    : 'Verifying access');

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: _animDuration,
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
                            const SizedBox(height: 24),
                            AnimatedSize(
                              duration: _animDuration,
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.hardEdge,
                              child:
                                  hideInput
                                      ? const SizedBox.shrink()
                                      : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _controller,
                                            focusNode: _focusNode,
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
                                                bleProcess.processDesc.value =
                                                    '';
                                                bleProcess
                                                    .isAccessKeyValid
                                                    .value = null;
                                              }
                                            },
                                            onChanged: (val) {
                                              final wasWrong =
                                                  bleProcess
                                                      .isAccessKeyValid
                                                      .value ==
                                                  false;
                                              accessKey.value = val;
                                              bleProcess
                                                  .isAccessKeyValid
                                                  .value = null;
                                              if (wasWrong) {
                                                bleProcess.processDesc.value =
                                                    '';
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
                                              fillColor: const Color(
                                                0xFFF8F8F8,
                                              ),
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
                            // Status line (BLE processDesc)
                            ValueListenableBuilder<String>(
                              valueListenable: bleProcess.processDesc,
                              builder: (_, pd, __) {
                                String? status;
                                if (isAccessKeyValidValue == false) {
                                  status =
                                      pd.isNotEmpty
                                          ? pd
                                          : 'Wrong password. Try again.';
                                } else if (isAccessKeyValidValue == null &&
                                    (pd.isNotEmpty ||
                                        _controller.text.isNotEmpty)) {
                                  status = pd.isNotEmpty ? pd : '';
                                } else if (isAccessKeyValidValue == true) {
                                  status = '';
                                }
                                if (isAccessKeyValidValue == false) {
                                  if (_controller.text.isNotEmpty) {
                                    _controller.clear();
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_focusNode.canRequestFocus) {
                                      _focusNode.requestFocus();
                                    }
                                  });
                                }
                                return status == null || status.isEmpty
                                    ? const SizedBox.shrink()
                                    : Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
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
                            const SizedBox(height: 12),
                            ValueListenableBuilder<String>(
                              valueListenable: bleProcess.processDesc,
                              builder: (_, processDescForButtons, __) {
                                // Show only before verify, or after wrong key (retry). Never on success.
                                final bool showButtons =
                                    !_closing &&
                                    isAccessKeyValidValue != true &&
                                    (processDescForButtons.isEmpty ||
                                        isAccessKeyValidValue == false);
                                return showButtons
                                    ? Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFFEC1D24,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFEC1D24),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.of(
                                                  widget.dialogContext,
                                                ).pop(false);
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
                                              listenable: _controller,
                                              builder: (context, _) {
                                                final canVerify =
                                                    _controller.text
                                                        .trim()
                                                        .isNotEmpty;
                                                return ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFEC1D24),
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
                                                              widget
                                                                  .dialogContext,
                                                            ).unfocus();
                                                            bleProcess
                                                                .isAccessKeyValid
                                                                .value = null;
                                                            bleProcess
                                                                    .processDesc
                                                                    .value =
                                                                "Validating";
                                                            accessKey.value =
                                                                _controller
                                                                    .text;
                                                            await widget
                                                                .onStartValidation();
                                                            // resetProcessState clears processDesc → buttons would reappear
                                                            if (bleProcess
                                                                .processDesc
                                                                .value
                                                                .isEmpty) {
                                                              bleProcess
                                                                      .processDesc
                                                                      .value =
                                                                  "Validating";
                                                            }
                                                          }
                                                          : null,
                                                  child: Text(
                                                    'Verify',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
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
  }
}
