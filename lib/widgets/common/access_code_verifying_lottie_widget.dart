import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

/// Shown while panel access code is being validated over BLE.
class AccessCodeVerifyingLottieWidget extends StatelessWidget {
  const AccessCodeVerifyingLottieWidget({super.key});

  static const String _assetPath = AssetConstants.bleConnectingJson;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Lottie.asset(
        _assetPath,
        key: const ValueKey('access_code_verifying_lottie'),
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
