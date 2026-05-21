import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Shown while panel access code is being validated over BLE.
class AccessCodeVerifyingLottieWidget extends StatelessWidget {
  const AccessCodeVerifyingLottieWidget({super.key});

  static const String _assetPath = 'assets/jsons/ble_connecting.json';

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
