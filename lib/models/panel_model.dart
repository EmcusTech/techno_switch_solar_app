import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelModel {
  final int? id;
  final String panelId;
  final String panelName;
  final String deviceType;
  final String deviceInfo;
  final int? siteId;
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
      baseString =
          bluetoothMac?.isNotEmpty == true
              ? 'BT_${bluetoothMac!.replaceAll(':', '').toUpperCase()}'
              : 'BT_NAME_${bluetoothName ?? 'UNKNOWN'}';
    } else if (deviceType == 'usb') {
      if (usbVid?.isNotEmpty == true && usbPid?.isNotEmpty == true) {
        baseString = 'USB_${usbVid!.toUpperCase()}_${usbPid!.toUpperCase()}';
      } else {
        baseString = 'USB_NAME_${usbProductName ?? 'UNKNOWN'}';
      }
    } else {
      baseString =
          'UNKNOWN_${deviceType}_${DateTime.now().millisecondsSinceEpoch}';
    }

    var bytes = utf8.encode(baseString);
    var digest = sha1.convert(bytes);

    String shortHash = digest.toString().substring(0, 8).toUpperCase();
    return '${deviceType.toUpperCase()}_$shortHash';
  }

  static Map<String, dynamic> createBluetoothDeviceInfo({
    required String macAddress,
    required String deviceName,
    int? rssi,
  }) {
    return {
      StringConstants.macaddress: macAddress,
      StringConstants.devicename: deviceName,
      'rssi': rssi,
      StringConstants.productname: 'bluetooth',
    };
  }

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
      StringConstants.productname: 'usb',
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'panel_id': panelId,
      'panel_name': panelName,
      'device_type': deviceType,
      StringConstants.str99914b93: deviceInfo,
      'site_id': siteId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_connected': lastConnected?.millisecondsSinceEpoch,
    };
  }

  factory PanelModel.fromMap(Map<String, dynamic> map) {
    return PanelModel(
      id: map['id']?.toInt(),
      panelId: map['panel_id'] ?? '',
      panelName: map['panel_name'] ?? '',
      deviceType: map['device_type'] ?? '',
      deviceInfo: map[StringConstants.str99914b93] ?? '{}',
      siteId: map['site_id']?.toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      lastConnected:
          map['last_connected'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'])
              : null,
    );
  }

  Map<String, dynamic> get parsedDeviceInfo {
    try {
      if (deviceInfo.isEmpty) return {};
      return Map<String, dynamic>.from(const JsonDecoder().convert(deviceInfo));
    } catch (e) {
      return {};
    }
  }

  bool get isOfflineProvisionedOnly {
    final info = parsedDeviceInfo;
    if (info['offlineProvisioned'] == true) return true;
    final mac = info[StringConstants.macaddress]?.toString().trim() ?? '';
    return mac.isEmpty && (info[StringConstants.offlineprovisioned]?.toString().isNotEmpty ?? false);
  }

  bool isLinkedToBleMac(String mac) {
    final stored = parsedDeviceInfo[StringConstants.macaddress]?.toString().trim() ?? '';
    if (stored.isEmpty || mac.trim().isEmpty) return false;
    return _normalizeMac(stored) == _normalizeMac(mac);
  }

  static String _normalizeMac(String mac) =>
      mac.replaceAll(':', '').toUpperCase();

  static Map<String, dynamic> createOfflineProvisionedDeviceInfo(
    String panelId,
  ) {
    return {StringConstants.offlineprovisioned: panelId, 'offlineProvisioned': true};
  }

  String get deviceDisplayInfo {
    final info = parsedDeviceInfo;
    if (deviceType == 'bluetooth') {
      final mac = info[StringConstants.macaddress] ?? '';
      final rssi = info['rssi'];
      return rssi != null ? '$mac (${rssi}dBm)' : mac;
    } else if (deviceType == 'usb') {
      final vid = info['vid'] ?? '';
      final pid = info['pid'] ?? '';
      return vid.isNotEmpty && pid.isNotEmpty
          ? 'VID:$vid PID:$pid'
          : StringConstants.vidVidPIDPid;
    }
    return StringConstants.unknownDevice;
  }

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
