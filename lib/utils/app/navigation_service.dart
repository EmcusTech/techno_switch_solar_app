import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/app/app_services.dart';
import 'package:techno_switch_solar_app/utils/app/app_state.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

class NavigationService {
  static Future<void> navigateBackToHome(BuildContext context) async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    AppState.reset();

    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  static Future<void> navigateBackToScanning(BuildContext context) async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    AppState.reset();

    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  static Future<void> popWithCleanup(
    BuildContext context, {
    bool disconnectBluetooth = false,
    bool resetState = false,
  }) async {
    if (disconnectBluetooth && AppServices.isConnected) {
      await AppServices.disconnect();
    }

    if (resetState) {
      AppState.reset();
    }

    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  static bool shouldAutoDisconnectOnPop(String currentRoute) {
    const routesToDisconnect = [
      'EventLogScreen',
      StringConstants.logretrievalloadingscreen,
      StringConstants.projectdashboardscreen,
      StringConstants.testmodescreen,
      StringConstants.scannedscreen,
    ];

    return routesToDisconnect.contains(currentRoute);
  }

  static Future<void> navigateToScanAgain(BuildContext context) async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    AppState.reset();

    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }
}

mixin BluetoothNavigationMixin<T extends StatefulWidget> on State<T> {
  bool _shouldDisconnectOnPop = true;

  bool get shouldDisconnectOnPop => _shouldDisconnectOnPop;

  void setShouldDisconnectOnPop(bool value) {
    _shouldDisconnectOnPop = value;
  }

  Future<void> onNavigationCleanup() async {
    if (shouldDisconnectOnPop && AppServices.isConnected) {
      await AppServices.disconnect();
      AppState.reset();
    }
  }

  Future<void> handleBackNavigation() async {
    await onNavigationCleanup();
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  Future<bool> onWillPop() async {
    await onNavigationCleanup();
    return true;
  }
}
