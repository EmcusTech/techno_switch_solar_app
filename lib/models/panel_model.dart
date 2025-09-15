import 'dart:convert';
import 'package:crypto/crypto.dart';

class PanelModel {
  final int? id;
  final String panelId; // Unique identifier generated from device info
  final String panelName; // Display name (device name)
  final String deviceType; // 'bluetooth' or 'usb'
  final String deviceInfo; // JSON string containing device details
  final int? siteId; // Foreign key to associated site (nullable)
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConnected;

  PanelModel({
    this.id,
    required this.panelId,
    required this.panelName,
    required this.deviceType,
    required this.deviceInfo,
    this.siteId,
    required this.createdAt,
    required this.updatedAt,
    this.lastConnected,
  });

  /// Generate a unique panel ID from device information
  static String generatePanelId({
    required String deviceType,
    String? bluetoothMac,
    String? bluetoothName,
    String? usbVid,
    String? usbPid,
    String? usbProductName,
  }) {
    String baseString;

    if (deviceType == 'bluetooth') {
      // Use MAC address as primary identifier, fallback to name
      baseString =
          bluetoothMac?.isNotEmpty == true
              ? 'BT_${bluetoothMac!.replaceAll(':', '').toUpperCase()}'
              : 'BT_NAME_${bluetoothName ?? 'UNKNOWN'}';
    } else if (deviceType == 'usb') {
      // Use VID:PID combination, fallback to product name
      if (usbVid?.isNotEmpty == true && usbPid?.isNotEmpty == true) {
        baseString = 'USB_${usbVid!.toUpperCase()}_${usbPid!.toUpperCase()}';
      } else {
        baseString = 'USB_NAME_${usbProductName ?? 'UNKNOWN'}';
      }
    } else {
      baseString =
          'UNKNOWN_${deviceType}_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Generate a consistent hash for the panel ID
    var bytes = utf8.encode(baseString);
    var digest = sha1.convert(bytes);

    // Take first 8 characters of hash and combine with device type prefix
    String shortHash = digest.toString().substring(0, 8).toUpperCase();
    return '${deviceType.toUpperCase()}_$shortHash';
  }

  /// Create panel info from Bluetooth device
  static Map<String, dynamic> createBluetoothDeviceInfo({
    required String macAddress,
    required String deviceName,
    int? rssi,
  }) {
    return {
      'macAddress': macAddress,
      'deviceName': deviceName,
      'rssi': rssi,
      'connectionType': 'bluetooth',
    };
  }

  /// Create panel info from USB device
  static Map<String, dynamic> createUsbDeviceInfo({
    String? vid,
    String? pid,
    String? productName,
    String? vendorName,
  }) {
    return {
      'vid': vid,
      'pid': pid,
      'productName': productName,
      'vendorName': vendorName,
      'connectionType': 'usb',
    };
  }

  /// Convert Panel object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'panel_id': panelId,
      'panel_name': panelName,
      'device_type': deviceType,
      'device_info': deviceInfo,
      'site_id': siteId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_connected': lastConnected?.millisecondsSinceEpoch,
    };
  }

  /// Convert Map from database to Panel object
  factory PanelModel.fromMap(Map<String, dynamic> map) {
    return PanelModel(
      id: map['id']?.toInt(),
      panelId: map['panel_id'] ?? '',
      panelName: map['panel_name'] ?? '',
      deviceType: map['device_type'] ?? '',
      deviceInfo: map['device_info'] ?? '{}',
      siteId: map['site_id']?.toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      lastConnected:
          map['last_connected'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'])
              : null,
    );
  }

  /// Get parsed device info as Map
  Map<String, dynamic> get parsedDeviceInfo {
    try {
      if (deviceInfo.isEmpty) return {};
      return Map<String, dynamic>.from(const JsonDecoder().convert(deviceInfo));
    } catch (e) {
      return {};
    }
  }

  /// Get display string for device connection info
  String get deviceDisplayInfo {
    final info = parsedDeviceInfo;
    if (deviceType == 'bluetooth') {
      final mac = info['macAddress'] ?? '';
      final rssi = info['rssi'];
      return rssi != null ? '$mac (${rssi}dBm)' : mac;
    } else if (deviceType == 'usb') {
      final vid = info['vid'] ?? '';
      final pid = info['pid'] ?? '';
      return vid.isNotEmpty && pid.isNotEmpty
          ? 'VID:$vid PID:$pid'
          : 'USB Device';
    }
    return 'Unknown Device';
  }

  /// Create a copy with updated fields
  PanelModel copyWith({
    int? id,
    String? panelId,
    String? panelName,
    String? deviceType,
    String? deviceInfo,
    int? siteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastConnected,
  }) {
    return PanelModel(
      id: id ?? this.id,
      panelId: panelId ?? this.panelId,
      panelName: panelName ?? this.panelName,
      deviceType: deviceType ?? this.deviceType,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      siteId: siteId ?? this.siteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  @override
  String toString() {
    return 'PanelModel{id: $id, panelId: $panelId, panelName: $panelName, deviceType: $deviceType, siteId: $siteId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanelModel &&
          runtimeType == other.runtimeType &&
          panelId == other.panelId;

  @override
  int get hashCode => panelId.hashCode;
}

/// Enum for device connection types
enum DeviceType {
  bluetooth,
  usb,
  unknown;

  static DeviceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bluetooth':
        return DeviceType.bluetooth;
      case 'usb':
        return DeviceType.usb;
      default:
        return DeviceType.unknown;
    }
  }
}
