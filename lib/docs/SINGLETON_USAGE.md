# Bluetooth Singleton Services Usage Guide

## Overview

This guide explains how to use the improved singleton pattern for Bluetooth services in the Techno Switch Solar app. The singleton pattern ensures that only one instance of the Bluetooth service exists throughout the app, providing consistent state management and preventing connection conflicts.

## Architecture

### 1. SerialCommunicationService (Singleton)
- **Location**: `lib/utils/serial_communication_service.dart`
- **Purpose**: Handles all Bluetooth communication with the device
- **Pattern**: Singleton with factory constructor

```dart
// Get the singleton instance
final service = SerialCommunicationService.instance;
// OR use the factory constructor
final service = SerialCommunicationService();
```

### 2. AppServices (Singleton Wrapper)
- **Location**: `lib/services/app_services.dart`
- **Purpose**: Provides easy access to the serial service and additional convenience methods
- **Pattern**: Singleton wrapper around SerialCommunicationService

```dart
// Access the service
final service = AppServices.serialService;

// Check connection status
bool isConnected = AppServices.isConnected;

// Connect to device
await AppServices.connectToDevice();
```

### 3. BluetoothConnectionManager
- **Location**: `lib/services/bluetooth_connection_manager.dart`
- **Purpose**: Manages connection state and prevents multiple concurrent connections
- **Pattern**: Static utility class

```dart
// Ensure connection (prevents duplicate attempts)
await BluetoothConnectionManager.ensureConnection();

// Safely disconnect
await BluetoothConnectionManager.safeDisconnect();
```

### 4. AppState (Global State Management)
- **Location**: `lib/services/app_state.dart`
- **Purpose**: Provides reactive global state using ValueNotifiers
- **Pattern**: Singleton with ValueNotifiers

```dart
// Listen to connection state changes
AppState.connectionState.addListener(() {
  // Handle state change
});

// Update logs count
AppState.updateLogsCount(10);
```

## Usage Examples

### Basic Connection Management

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    
    // Listen to global state changes
    AppState.connectionState.addListener(_onConnectionChanged);
    AppState.logsCount.addListener(_onLogsCountChanged);
  }

  @override
  void dispose() {
    // Clean up listeners
    AppState.connectionState.removeListener(_onConnectionChanged);
    AppState.logsCount.removeListener(_onLogsCountChanged);
    super.dispose();
  }

  void _onConnectionChanged() {
    setState(() {}); // Trigger rebuild
  }

  void _onLogsCountChanged() {
    setState(() {}); // Trigger rebuild
  }

  Future<void> _connectToDevice() async {
    final success = await AppServices.connectToDevice();
    if (success) {
      // Connection successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Display connection status
          ValueListenableBuilder(
            valueListenable: AppState.connectionStatus,
            builder: (context, status, child) {
              return Text('Status: $status');
            },
          ),
          
          // Display logs count
          ValueListenableBuilder(
            valueListenable: AppState.logsCount,
            builder: (context, count, child) {
              return Text('Logs: $count');
            },
          ),
          
          // Connect button
          ElevatedButton(
            onPressed: AppServices.isConnected ? null : _connectToDevice,
            child: Text('Connect'),
          ),
        ],
      ),
    );
  }
}
```

### Log Retrieval with State Management

```dart
class LogRetrievalScreen extends StatefulWidget {
  @override
  State<LogRetrievalScreen> createState() => _LogRetrievalScreenState();
}

class _LogRetrievalScreenState extends State<LogRetrievalScreen> {
  @override
  void initState() {
    super.initState();
    
    // Listen to logs updates
    AppState.currentLogs.addListener(_onLogsUpdated);
    AppState.isRetrievingLogs.addListener(_onRetrievalStatusChanged);
  }

  @override
  void dispose() {
    AppState.currentLogs.removeListener(_onLogsUpdated);
    AppState.isRetrievingLogs.removeListener(_onRetrievalStatusChanged);
    super.dispose();
  }

  void _onLogsUpdated() {
    setState(() {});
  }

  void _onRetrievalStatusChanged() {
    if (!AppState.isRetrievingLogs.value) {
      // Log retrieval completed
      _navigateToLogScreen();
    }
  }

  void _startLogRetrieval() {
    if (AppServices.isConnected) {
      AppServices.startLogRetrieval();
    }
  }

  void _navigateToLogScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EventLogScreen(
          logDataList: AppState.currentLogs.value,
          panelName: 'RHINO2008',
          panelVersionNo: '0.98',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show logs count during retrieval
            ValueListenableBuilder(
              valueListenable: AppState.logsCount,
              builder: (context, count, child) {
                return Text(
                  '$count logs',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                );
              },
            ),
            
            // Show retrieval status
            ValueListenableBuilder(
              valueListenable: AppState.connectionStatus,
              builder: (context, status, child) {
                return Text(status);
              },
            ),
            
            // Start retrieval button
            ElevatedButton(
              onPressed: AppServices.isConnected ? _startLogRetrieval : null,
              child: Text('Start Log Retrieval'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Benefits of This Singleton Approach

1. **Thread Safety**: Only one instance across the entire app
2. **Memory Efficiency**: No duplicate instances
3. **State Consistency**: All screens see the same connection state
4. **Resource Management**: Single Bluetooth connection management
5. **Stream Management**: Centralized data streams
6. **Easy Testing**: Can easily mock the singleton for testing
7. **Reactive UI**: ValueNotifiers provide automatic UI updates

## Best Practices

1. **Always use AppServices**: Use `AppServices` instead of accessing `SerialCommunicationService` directly
2. **Clean up listeners**: Always remove ValueNotifier listeners in dispose()
3. **Use connection manager**: Use `BluetoothConnectionManager` for connection operations
4. **Initialize once**: Call `AppServices.initialize()` once at app startup
5. **Dispose properly**: Call `AppServices.dispose()` when app closes

## Migration from Previous Implementation

If you have existing code using direct `SerialCommunicationService` instances:

### Before:
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late SerialCommunicationService _service;
  
  @override
  void initState() {
    super.initState();
    _service = SerialCommunicationService(); // Creates new instance
    _service.logStream.listen((log) {
      // Handle log
    });
  }
}
```

### After:
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Use global state instead
    AppState.currentLogs.addListener(_onLogsChanged);
  }
  
  @override
  void dispose() {
    AppState.currentLogs.removeListener(_onLogsChanged);
    super.dispose();
  }
  
  void _onLogsChanged() {
    setState(() {});
  }
}
```

## Troubleshooting

1. **Multiple connection attempts**: Use `BluetoothConnectionManager.ensureConnection()` instead of direct connection calls
2. **State not updating**: Make sure you're listening to the correct ValueNotifier and calling setState()
3. **Memory leaks**: Always remove listeners in dispose()
4. **Connection issues**: Check `AppServices.isConnected` before performing operations

## Example Implementation

See `lib/examples/singleton_usage_example.dart` for a complete working example of how to use all the singleton services together.
