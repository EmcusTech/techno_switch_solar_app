import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import 'package:techno_switch_solar_app/widgets/common/common_numeric_keypad_tile_widget.dart';

class CommonNumericKeypadWidget extends StatefulWidget {
  const CommonNumericKeypadWidget({super.key});

  @override
  State<CommonNumericKeypadWidget> createState() =>
      _CommonNumericKeypadWidgetState();
}

class _CommonNumericKeypadWidgetState extends State<CommonNumericKeypadWidget> {
  TextEditingController accessController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE31C23),
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              // padding: EdgeInsets.only(
              //   top: 16,
              //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              // ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(height: 16),
                      _dragHandle(),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEC1D24),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFFEC1D24,
                              ).withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 1,
                              blurStyle: BlurStyle.solid,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SvgPicture.asset(
                            "assets/svgs/lock_icon_white_svg.svg",
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      Text(
                        "Enter Access Code",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26.0),
                        child: TextField(
                          controller: accessController,
                          readOnly: true,
                          // focusNode: focusNode,
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
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          // onTap: () {
                          //   if (bleProcess.isAccessKeyValid.value == false) {
                          //     bleProcess.processDesc.value = '';
                          //     bleProcess.isAccessKeyValid.value = null;
                          //   }
                          // },
                          // onChanged: (val) {
                          //   final wasWrong =
                          //       bleProcess.isAccessKeyValid.value == false;
                          //   accessKey.value = val;
                          //   bleProcess.isAccessKeyValid.value = null;
                          //   if (wasWrong) {
                          //     bleProcess.processDesc.value = '';
                          //   }
                          // },
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEC1D24),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            CommonNumericKeypadTileWidget(
                              numericValue: "1",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "1",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "2",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "2",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "3",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "3",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "4",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "4",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "5",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "5",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "6",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "6",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "7",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "7",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "8",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "8",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "9",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "9",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              isClear: true,
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  isClear: true,
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              numericValue: "0",
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  value: "0",
                                );
                              },
                            ),
                            CommonNumericKeypadTileWidget(
                              isDelete: true,
                              fillColor: Color(0xFFFAEFEF),
                              onTap: () {
                                updateAccessController(
                                  controller: accessController,
                                  isDelete: true,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26.0),
                        child: CommonCtaButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Verify",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset("assets/svgs/bottomsheet_logo.svg"),
                      Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            child: Icon(Icons.close, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void updateAccessController({
    required TextEditingController controller,
    String? value = "",
    bool? isClear = false,
    bool? isDelete = false,
  }) {
    if (isClear == true) {
      controller.clear();
      return;
    }
    if (isDelete == true) {
      deleteLastCharacter(controller: controller);
    }
    if (controller.text.length >= 8) return;

    final newText = controller.text + (value ?? "");

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    print("Controller text : ${controller.text}");
  }

  void deleteLastCharacter({required TextEditingController controller}) {
    if (controller.text.isEmpty) return;

    final newText = controller.text.substring(0, controller.text.length - 1);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
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
}
