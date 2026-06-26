import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class CommonCtaButton extends StatelessWidget {
  final Widget child;
  final double? width;
  final Color? color;
  final bool? isDisabled;
  final Function()? onTap;
  const CommonCtaButton({
    super.key,
    required this.child,
    this.width,
    this.color,
    this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ?? false ? 0.5 : 1,
        child: Container(
          width: width ?? double.infinity,
          // height: 55,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color ?? ColorConstants.primary,
            borderRadius: BorderRadius.circular(28.5),
            boxShadow: [
              BoxShadow(
                color: color ?? ColorConstants.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
