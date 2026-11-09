import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/models/log_model.dart';

/// Shared demo data for the scan list and the event-log screen.
abstract final class DemoConstants {
  static const int sampleEventLogCount = 1000;

  static const List<String> _eventTexts = <String>[
    'Zone alarm',
    'Input fault',
    'Relay operated',
    'Sounder activated',
    'Panel reset',
    'Zone enabled',
    'Service switch on',
    'Access code invalid',
  ];

  static const List<String> _eventClasses = <String>[
    'Release',
    'Alarm',
    'Fault',
    'Disablement',
    'Condition',
    'Action',
  ];

  /// Sample records for the event-log screen when demo mode is on.
  static final List<LogModel> sampleEventLogs = List<LogModel>.generate(
    sampleEventLogCount,
    (int index) {
      final int source = index % 5;
      final int number = index % 8;
      final DateTime time = DateTime(2026, 11, 1, 8).add(
        Duration(minutes: index),
      );
      return LogModel(
        eventId: '${0x1000 + (index % 240)}',
        text: _eventTexts[index % _eventTexts.length],
        configText: 'Config ${index + 1}',
        eventDateTime: time,
        eventClass: _eventClasses[index % _eventClasses.length],
        par0: source,
        par1: number,
        isValid: true,
      );
    },
  );

  static List<DiscoveredDevice> scanDevices() {
    return [
      DiscoveredDevice(
        id: 'demo-panel-1',
        name: 'TECHNOSWITCH_11873122',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -46,
        serviceUuids: const <Uuid>[],
      ),
      DiscoveredDevice(
        id: 'demo-panel-3',
        name: 'TECHNOSWITCH_73823342',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -68,
        serviceUuids: const <Uuid>[],
      ),
      DiscoveredDevice(
        id: 'demo-panel-4',
        name: 'TECHNOSWITCH_73823343',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -68,
        serviceUuids: const <Uuid>[],
      ),
      DiscoveredDevice(
        id: 'demo-panel-5',
        name: 'TECHNOSWITCH_73823341',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -68,
        serviceUuids: const <Uuid>[],
      ),
      DiscoveredDevice(
        id: 'demo-panel-6',
        name: 'TECHNOSWITCH_73823346',
        serviceData: const <Uuid, List<int>>{},
        manufacturerData: const [0],
        rssi: -68,
        serviceUuids: const <Uuid>[],
      ),
    ];
  }
}
