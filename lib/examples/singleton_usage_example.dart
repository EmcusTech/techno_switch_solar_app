// import 'package:flutter/material.dart';
// import 'package:techno_switch_solar_app/services/app_services.dart';
// import 'package:techno_switch_solar_app/services/app_state.dart';

// /// Example screen demonstrating how to use the improved singleton services
// class SingletonUsageExample extends StatefulWidget {
//   const SingletonUsageExample({super.key});

//   @override
//   State<SingletonUsageExample> createState() => _SingletonUsageExampleState();
// }

// class _SingletonUsageExampleState extends State<SingletonUsageExample> {
//   @override
//   void initState() {
//     super.initState();

//     // Example of listening to global state changes
//     AppState.connectionState.addListener(_onConnectionStateChanged);
//     AppState.logsCount.addListener(_onLogsCountChanged);
//     AppState.connectionStatus.addListener(_onConnectionStatusChanged);
//   }

//   @override
//   void dispose() {
//     // Clean up listeners
//     AppState.connectionState.removeListener(_onConnectionStateChanged);
//     AppState.logsCount.removeListener(_onLogsCountChanged);
//     AppState.connectionStatus.removeListener(_onConnectionStatusChanged);
//     super.dispose();
//   }

//   void _onConnectionStateChanged() {
//     setState(() {}); // Trigger rebuild when connection state changes
//   }

//   void _onLogsCountChanged() {
//     setState(() {}); // Trigger rebuild when logs count changes
//   }

//   void _onConnectionStatusChanged() {
//     setState(() {}); // Trigger rebuild when status changes
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Singleton Usage Example')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Connection Status Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Connection Status',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 8),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.connectionStatus,
//                       builder: (context, status, child) {
//                         return Text('Status: $status');
//                       },
//                     ),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.connectionState,
//                       builder: (context, state, child) {
//                         return Text(
//                           'State: ${state.toString().split('.').last}',
//                         );
//                       },
//                     ),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.connectedDeviceName,
//                       builder: (context, deviceName, child) {
//                         return Text('Device: ${deviceName ?? 'None'}');
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Logs Information Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Logs Information',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 8),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.logsCount,
//                       builder: (context, count, child) {
//                         return Text('Logs Count: $count');
//                       },
//                     ),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.isRetrievingLogs,
//                       builder: (context, isRetrieving, child) {
//                         return Text(
//                           'Retrieving: ${isRetrieving ? 'Yes' : 'No'}',
//                         );
//                       },
//                     ),
//                     ValueListenableBuilder(
//                       valueListenable: AppState.logRetrievalProgress,
//                       builder: (context, progress, child) {
//                         return Text('Progress: ${(progress * 100).toInt()}%');
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Action Buttons Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Actions',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 16),

//                     // Connect Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed:
//                             AppServices.isConnected || AppServices.isConnecting
//                                 ? null
//                                 : () async {
//                                   final success =
//                                       await AppServices.connectToDevice();
//                                   if (mounted) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text(
//                                           success
//                                               ? 'Connected successfully'
//                                               : 'Connection failed',
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                         child: Text(
//                           AppServices.isConnecting
//                               ? 'Connecting...'
//                               : AppServices.isConnected
//                               ? 'Connected'
//                               : 'Connect to Device',
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     // Start Log Retrieval Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed:
//                             !AppServices.isConnected
//                                 ? null
//                                 : () {
//                                   AppServices.startLogRetrieval();
//                                 },
//                         child: const Text('Start Log Retrieval'),
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     // Disconnect Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed:
//                             !AppServices.isConnected
//                                 ? null
//                                 : () async {
//                                   await AppServices.disconnect();
//                                   if (mounted) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text('Disconnected'),
//                                       ),
//                                     );
//                                   }
//                                 },
//                         child: const Text('Disconnect'),
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     // Scan for Devices Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () async {
//                           final devices = await AppServices.scanForDevices();
//                           if (mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'Found ${devices.length} devices',
//                                 ),
//                               ),
//                             );
//                           }
//                         },
//                         child: const Text('Scan for Devices'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
