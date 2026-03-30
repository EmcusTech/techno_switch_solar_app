import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';

/// Observes route changes for [RouteAware] widgets (e.g. refresh home when a
/// pushed route is popped).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Service to handle navigation with proper Bluetooth cleanup
class NavigationService {
  /// Navigate back to home screen with Bluetooth disconnection
  static Future<void> navigateBackToHome(BuildContext context) async {
    // Disconnect Bluetooth if connected
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    // Reset app state
    AppState.reset();

    if (!context.mounted) return;
    // Match routes pushed with [rootNavigator: true] (e.g. from scanning).
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  /// Navigate back to scanning screen with Bluetooth disconnection
  static Future<void> navigateBackToScanning(BuildContext context) async {
    // Disconnect Bluetooth if connected
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    // Reset app state
    AppState.reset();

    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  /// Pop current screen with optional Bluetooth disconnection
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

  /// Check if should auto-disconnect based on navigation context
  static bool shouldAutoDisconnectOnPop(String currentRoute) {
    // Define routes where Bluetooth should be disconnected on back navigation
    const routesToDisconnect = [
      'EventLogScreen',
      'LogRetrievalLoadingScreen',
      'AccessCodeScreen',
      'ProjectDashboardScreen',
      'TestModeScreen',
      'ScannedScreen',
    ];

    return routesToDisconnect.contains(currentRoute);
  }

  /// Navigate to scanning screen (for "Scan Again" functionality)
  static Future<void> navigateToScanAgain(BuildContext context) async {
    // Always disconnect when going back to scan
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    // Reset app state for fresh scan
    AppState.reset();

    // Navigate back to scanning - we'll handle the import in the calling screen
    // to avoid circular dependencies
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }
}

/// Mixin to add automatic Bluetooth cleanup to screens
mixin BluetoothNavigationMixin<T extends StatefulWidget> on State<T> {
  bool _shouldDisconnectOnPop = true;

  /// Override this to control auto-disconnect behavior
  bool get shouldDisconnectOnPop => _shouldDisconnectOnPop;

  /// Set whether to auto-disconnect on pop
  void setShouldDisconnectOnPop(bool value) {
    _shouldDisconnectOnPop = value;
  }

  /// Override this method to add custom cleanup logic
  Future<void> onNavigationCleanup() async {
    // Default implementation - can be overridden
    if (shouldDisconnectOnPop && AppServices.isConnected) {
      await AppServices.disconnect();
      AppState.reset();
    }
  }

  /// Call this in your back button handlers
  Future<void> handleBackNavigation() async {
    await onNavigationCleanup();
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  /// Use this for WillPopScope or PopScope
  Future<bool> onWillPop() async {
    await onNavigationCleanup();
    return true; // Allow the pop
  }
}
