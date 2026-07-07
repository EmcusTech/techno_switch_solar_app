import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

/// Shown after panel access code validation succeeds (before sheet closes).
class AccessCodeSuccessLottieWidget extends StatelessWidget {
  const AccessCodeSuccessLottieWidget({super.key});

  static const String _assetPath = AssetConstants.firmwareUpgradeSuccessJson;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Lottie.asset(
        _assetPath,
        key: const ValueKey('access_code_success_lottie'),
        fit: BoxFit.contain,
        repeat: false,
      ),
    );
  }
}
