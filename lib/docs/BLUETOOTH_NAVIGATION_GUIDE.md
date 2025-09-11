# Bluetooth Navigation and Connection Management Guide

## Overview

This guide explains how Bluetooth connections are properly managed during navigation in the Techno Switch Solar app. The implementation ensures that Bluetooth connections are properly disconnected when returning to the home screen or scanning screen, allowing users to discover devices again.

## Key Problems Solved

1. **Device Discovery Issues**: Previously, devices might not be discoverable again if the Bluetooth connection wasn't properly closed
2. **Memory Leaks**: Bluetooth connections consuming resources when not needed
3. **State Confusion**: App state persisting when users want to start fresh
4. **Connection Conflicts**: Multiple connection attempts causing conflicts

## Architecture

### NavigationService

The `NavigationService` provides centralized navigation methods with proper Bluetooth cleanup:

```dart
// Navigate back to home with cleanup
await NavigationService.navigateBackToHome(context);

// Navigate back to scanning with cleanup  
await NavigationService.navigateBackToScanning(context);

// Pop with optional cleanup
await NavigationService.popWithCleanup(
  context, 
  disconnectBluetooth: true,
  resetState: true,
);
```

### HomeScreen Auto-Cleanup

The home screen automatically disconnects Bluetooth when loaded:

```dart
@override
void initState() {
  super.initState();
  // Disconnect Bluetooth when returning to home screen
  _handleBluetoothCleanup();
}

Future<void> _handleBluetoothCleanup() async {
  if (AppServices.isConnected) {
    await AppServices.disconnect();
  }
  AppState.reset();
}
```

## Implementation Details

### 1. Back Navigation with Cleanup

Screens that connect to Bluetooth devices now properly clean up:

**Event Log Screen:**
```dart
GestureDetector(
  onTap: () async {
    // Disconnect Bluetooth when going back
    await NavigationService.navigateBackToScanning(context);
  },
  child: SvgPicture.asset('assets/svgs/arrow_back_icon.svg'),
),
```

**Scanned Screen (Tap to Scan Again):**
```dart
GestureDetector(
  onTap: () async {
    // Disconnect Bluetooth before going back to scan
    await NavigationService.navigateToScanAgain(context);
    
    // Then navigate to scanning screen
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanningScreen(),
        ),
      );
    }
  },
  // ... rest of widget
),
```

### 2. Automatic Cleanup Scenarios

**When Bluetooth is automatically disconnected:**

1. **Returning to Home Screen**: Always disconnects and resets state
2. **Back Navigation from Connected Screens**: Disconnects when leaving connection-dependent screens
3. **Scanning Again**: Disconnects to allow fresh device discovery
4. **App State Reset**: Clears logs, connection status, and device information

### 3. Navigation Patterns

**From Connection Screens to Home:**
```
Event Log Screen → [Disconnect] → Scanning Screen → Home Screen
Log Retrieval → [Disconnect] → Scanning Screen → Home Screen
Access Code → [Disconnect] → Scanned Screen → Scanning Screen
```

**Scan Again Flow:**
```
Any Connected Screen → [Disconnect] → [Reset State] → Scanning Screen
```

## Usage Examples

### Basic Back Navigation with Cleanup

```dart
class MyConnectedScreen extends StatefulWidget {
  @override
  State<MyConnectedScreen> createState() => _MyConnectedScreenState();
}

class _MyConnectedScreenState extends State<MyConnectedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () async {
            // Proper cleanup before navigation
            await NavigationService.navigateBackToScanning(context);
          },
          child: Icon(Icons.arrow_back),
        ),
      ),
      // ... rest of screen
    );
  }
}
```

### Using the BluetoothNavigationMixin

For screens that need automatic cleanup:

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> 
    with BluetoothNavigationMixin {
  
  @override
  bool get shouldDisconnectOnPop => true; // Enable auto-disconnect
  
  @override
  Future<void> onNavigationCleanup() async {
    // Custom cleanup logic
    await super.onNavigationCleanup();
    // Add any additional cleanup here
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await onNavigationCleanup();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: handleBackNavigation, // Uses mixin method
            child: Icon(Icons.arrow_back),
          ),
        ),
        // ... rest of screen
      ),
    );
  }
}
```

## State Management Integration

### AppState Reset

When navigating with cleanup, the global app state is reset:

```dart
AppState.reset(); // Resets all state to initial values:
// - connectionState: PanelConnectionState.notConnected
// - logsCount: 0
// - currentLogs: []
// - connectionStatus: 'Disconnected'
// - connectedDeviceName: null
// - logRetrievalProgress: 0.0
// - isRetrievingLogs: false
```

### Connection Status Updates

The UI automatically reflects the disconnected state through ValueNotifiers:

```dart
ValueListenableBuilder(
  valueListenable: AppState.connectionStatus,
  builder: (context, status, child) {
    return Text('Status: $status'); // Shows "Disconnected" after cleanup
  },
),
```

## Best Practices

### 1. Always Use NavigationService

Instead of direct `Navigator.pop()`:

```dart
// ❌ Don't do this for Bluetooth-connected screens
Navigator.of(context).pop();

// ✅ Do this instead
await NavigationService.navigateBackToScanning(context);
```

### 2. Check Connection State

Before attempting disconnection:

```dart
if (AppServices.isConnected) {
  await AppServices.disconnect();
}
```

### 3. Handle Async Navigation

Always check if context is still mounted:

```dart
if (context.mounted) {
  Navigator.of(context).pushReplacement(/* ... */);
}
```

### 4. Consistent State Reset

Always reset app state when disconnecting:

```dart
await AppServices.disconnect();
AppState.reset(); // Important!
```

## Testing the Implementation

### Manual Testing Steps

1. **Basic Flow Test**:
   - Connect to a device
   - Navigate through screens  
   - Press back to return to home
   - Verify device can be discovered again

2. **Scan Again Test**:
   - Connect to a device
   - Go to any connected screen
   - Use "Tap to Scan Again" functionality
   - Verify clean disconnection and new scan

3. **Memory Test**:
   - Connect and disconnect multiple times
   - Monitor memory usage
   - Verify no memory leaks

4. **State Reset Test**:
   - Retrieve logs from device
   - Navigate back to home
   - Verify all counters and states are reset

### Expected Behaviors

✅ **Device becomes discoverable again after disconnection**
✅ **App state is properly reset**  
✅ **No memory leaks from hanging connections**
✅ **Clean UI state transitions**
✅ **No connection conflicts**

## Troubleshooting

### Issue: Device Not Discoverable Again

**Solution**: Ensure `NavigationService` methods are used instead of direct `Navigator.pop()`

### Issue: App State Not Resetting

**Solution**: Verify `AppState.reset()` is called after disconnection

### Issue: Memory Leaks

**Solution**: Check that all screens use proper disposal and cleanup

### Issue: Connection Conflicts

**Solution**: Ensure only one connection attempt at a time using `BluetoothConnectionManager`

## Migration Guide

### Updating Existing Screens

Replace direct navigation with NavigationService:

```dart
// Before
GestureDetector(
  onTap: () {
    Navigator.of(context).pop();
  },
  // ...
)

// After  
GestureDetector(
  onTap: () async {
    await NavigationService.navigateBackToScanning(context);
  },
  // ...
)
```

This implementation ensures proper Bluetooth connection management throughout the app's navigation flow.
