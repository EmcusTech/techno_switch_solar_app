import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class ScanBackButton extends StatelessWidget {
  const ScanBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorConstants.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorConstants.blackMaterial.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: ColorConstants.textDark,
            size: 18,
          ),
        ),
      ),
    );
  }
}
