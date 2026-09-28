import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:win_ble/win_ble.dart';

class Uuid {
  const Uuid._(this.value);

  final fbp.Guid value;

  factory Uuid(String uuid) => Uuid._(fbp.Guid(uuid));

  static Uuid parse(String uuid) => Uuid._(fbp.Guid(uuid));

  static Uuid fromGuid(fbp.Guid guid) => Uuid._(guid);

  @override
  bool operator ==(Object other) =>
      other is Uuid &&
      other.value.toString().toLowerCase() == value.toString().toLowerCase();

  @override
  int get hashCode => value.toString().toLowerCase().hashCode;

  @override
  String toString() => value.toString();
}

enum BleStatus {
  unknown,
  ready,
  poweredOff,
  locationServicesDisabled,
  unauthorized,
  unsupported,
}

enum DeviceConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
}

enum ScanMode { lowLatency, balanced, lowPower, opportunistic }

enum LogLevel { none, error, info, verbose, debug }

class ConnectionStateUpdate {
  ConnectionStateUpdate({
    required this.deviceId,
    required this.connectionState,
    this.failure,
  });

  final String deviceId;
  final DeviceConnectionState connectionState;
  final Object? failure;
}

class QualifiedCharacteristic {
  QualifiedCharacteristic({
    required this.serviceId,
    required this.characteristicId,
    required this.deviceId,
  });

  final Uuid serviceId;
  final Uuid characteristicId;
  final String deviceId;
}

class DiscoveredDevice {
  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.serviceData,
    required this.manufacturerData,
    required this.rssi,
    required this.serviceUuids,
    this.device,
  });

  final String id;
  final String name;
  final Map<Uuid, List<int>> serviceData;
  final List<int> manufacturerData;
  final int rssi;
  final List<Uuid> serviceUuids;
  final fbp.BluetoothDevice? device;

  factory DiscoveredDevice.fromScanResult(fbp.ScanResult result) {
    final serviceData = <Uuid, List<int>>{};

    try {
      result.advertisementData.serviceData.forEach((key, value) {
        serviceData[Uuid.fromGuid(key)] = List<int>.from(value);
      });
    } catch (_) {}

    final manufacturerData = <int>[];
    try {
      final ad = result.advertisementData;

      if (ad.msd.isNotEmpty) {
        final msdData = ad.msd.first;

        manufacturerData.addAll(msdData);
      } else {
        final manuDataMap = ad.manufacturerData;
        if (manuDataMap.isNotEmpty) {
          for (final entry in manuDataMap.entries) {
            manufacturerData.addAll(entry.value);
          }
        }
      }
    } catch (_) {}

    final serviceUuids = <Uuid>[];
    try {
      for (final guid in result.advertisementData.serviceUuids) {
        serviceUuids.add(Uuid.fromGuid(guid));
      }
    } catch (_) {}

    final deviceName =
        result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.device.remoteId.str;

    return DiscoveredDevice(
      id: result.device.remoteId.str,
      name: deviceName,
      serviceData: serviceData,
      manufacturerData: manufacturerData,
      rssi: result.rssi,
      serviceUuids: serviceUuids,
      device: result.device,
    );
  }
}

class FlutterReactiveBle {
  FlutterReactiveBle({this.logLevel = LogLevel.none});

  LogLevel logLevel;

  final Map<String, fbp.BluetoothDevice> _deviceCache =
      <String, fbp.BluetoothDevice>{};

  Stream<BleStatus> get statusStream {
    if (Platform.isWindows) return _windowsStatusStream();
    return fbp.FlutterBluePlus.adapterState.map(_mapAdapterState);
  }

  Stream<DiscoveredDevice> scanForDevices({
    required List<Uuid> withServices,
    ScanMode scanMode = ScanMode.lowLatency,
  }) {
    if (Platform.isWindows) return _scanForDevicesWindows(withServices);
    return _scanForDevicesAndroid(withServices, scanMode);
  }

  Stream<BleStatus> _windowsStatusStream() async* {
    try {
      yield _mapWinBleState(await WinBle.getBluetoothState());
    } catch (e) {
      debugPrint('WinBle adapter state failed: $e');
      yield BleStatus.unknown;
    }
    yield* WinBle.bleState.map(_mapWinBleState);
  }

  Stream<DiscoveredDevice> _scanForDevicesWindows(List<Uuid> withServices) {
    final controller = StreamController<DiscoveredDevice>.broadcast();
    final namesByAddress = <String, String>{};
    final matchedByAddress = <String, BleDevice>{};

    final sub = WinBle.scanStream.listen(
      (event) {
        final advertisedName = _winBleAdvertisedName(event);
        if (advertisedName != null) {
          namesByAddress[event.address] = advertisedName;
        }

        final matchesService = _winBleMatchesServices(event, withServices);
        if (matchesService) {
          matchedByAddress[event.address] = event;
        }

        final matched = matchedByAddress[event.address];
        if (matched == null) return;
        if (!matchesService && advertisedName == null) return;

        final name = namesByAddress[event.address] ?? matched.address;
        final source = matchesService ? event : matched;

        if (!controller.isClosed) {
          debugPrint(
            'WinBle scan shown '
            'uiName=$name '
            'name=${source.name} '
            'address=${source.address} '
            'rssi=${source.rssi} '
            'advType=${source.advType} '
            'serviceUuids=${source.serviceUuids} '
            'manufacturerData=${source.manufacturerData} '
            'adStructures=${source.adStructures?.map((ad) => 'type=${ad.type} data=${ad.data}').toList()}',
          );
          controller.add(_discoveredDeviceFromWinBle(source, name));
        }
      },
      onError: (Object e, StackTrace stack) {
        debugPrint('WinBle scan error: $e');
        debugPrint('$stack');
        if (!controller.isClosed) controller.addError(e, stack);
      },
    );

    try {
      WinBle.startScanning();
    } catch (e, stack) {
      debugPrint('WinBle startScan failed: $e');
      debugPrint('$stack');
      if (!controller.isClosed) controller.addError(e, stack);
    }

    controller.onCancel = () async {
      await sub.cancel();
      WinBle.stopScanning();
    };

    return controller.stream;
  }

  Stream<DiscoveredDevice> _scanForDevicesAndroid(
    List<Uuid> withServices,
    ScanMode scanMode,
  ) {
    final controller = StreamController<DiscoveredDevice>.broadcast();

    fbp.AndroidScanMode? androidScanMode;
    switch (scanMode) {
      case ScanMode.lowLatency:
        androidScanMode = fbp.AndroidScanMode.lowLatency;
        break;
      case ScanMode.balanced:
        androidScanMode = fbp.AndroidScanMode.balanced;
        break;
      case ScanMode.lowPower:
        androidScanMode = fbp.AndroidScanMode.lowPower;
        break;
      case ScanMode.opportunistic:
        androidScanMode = fbp.AndroidScanMode.opportunistic;
        break;
    }

    final List<fbp.Guid>? serviceFilters =
        withServices.isEmpty ? null : withServices.map((e) => e.value).toList();

    fbp.FlutterBluePlus.startScan(
      withServices: serviceFilters ?? const <fbp.Guid>[],
      androidScanMode: androidScanMode,
    );

    final sub = fbp.FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        controller.add(DiscoveredDevice.fromScanResult(result));
      }
    }, onError: controller.addError);

    controller.onCancel = () async {
      await sub.cancel();
      await fbp.FlutterBluePlus.stopScan();
    };

    return controller.stream;
  }

  Stream<ConnectionStateUpdate> connectToDevice({
    required String id,
    Duration? connectionTimeout,
  }) {
    final device = _deviceCache.putIfAbsent(
      id,
      () => fbp.BluetoothDevice.fromId(id),
    );
    final controller = StreamController<ConnectionStateUpdate>.broadcast();

    final stateSub = device.connectionState.listen(
      (state) {
        controller.add(
          ConnectionStateUpdate(
            deviceId: id,
            connectionState: _mapConnectionState(state),
          ),
        );
      },
      onError: (Object error) {
        controller.add(
          ConnectionStateUpdate(
            deviceId: id,
            connectionState: DeviceConnectionState.disconnected,
            failure: error,
          ),
        );
      },
    );

    () async {
      try {
        await device.connect(
          timeout: connectionTimeout ?? const Duration(seconds: 10),
          autoConnect: false,
        );
      } catch (_) {}
    }();

    controller.onCancel = () async {
      await stateSub.cancel();
      if (device.isConnected) {
        try {
          await device.disconnect();
        } catch (_) {}
      }
    };

    return controller.stream;
  }

  Future<void> abortConnection(String id) async {
    final device = _deviceCache.remove(id);
    if (device == null) return;
    try {
      await device.disconnect();
    } catch (_) {}
  }

  Future<int> requestMtu({required String deviceId, required int mtu}) async {
    final device = _deviceCache.putIfAbsent(
      deviceId,
      () => fbp.BluetoothDevice.fromId(deviceId),
    );
    try {
      await device.requestMtu(mtu);
      return await device.mtu.first;
    } catch (_) {
      return mtu;
    }
  }

  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) async* {
    final fbp.BluetoothCharacteristic char = await _resolveCharacteristic(
      characteristic,
    );
    await char.setNotifyValue(true);
    yield* _characteristicStream(char);
  }

  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    final fbp.BluetoothCharacteristic char = await _resolveCharacteristic(
      characteristic,
    );
    await char.write(value, withoutResponse: true);
  }

  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    final fbp.BluetoothCharacteristic char = await _resolveCharacteristic(
      characteristic,
    );
    await char.write(value, withoutResponse: false);
  }

  Future<void> clearGattCache(String deviceId) async {
    try {
      final device = _deviceCache[deviceId];
      if (device != null) {
        await device.clearGattCache();
      }
    } catch (_) {}
  }

  BleStatus _mapWinBleState(BleState state) {
    switch (state) {
      case BleState.On:
        return BleStatus.ready;
      case BleState.Off:
      case BleState.Disabled:
        return BleStatus.poweredOff;
      case BleState.Unsupported:
        return BleStatus.unsupported;
      case BleState.Unknown:
        return BleStatus.unknown;
    }
  }

  bool _winBleMatchesServices(BleDevice device, List<Uuid> withServices) {
    if (withServices.isEmpty) return true;

    final targets =
        withServices.map((uuid) => _normalizeUuid(uuid.toString())).toSet();
    return _winBleServiceUuids(device).any(targets.contains);
  }

  Set<String> _winBleServiceUuids(BleDevice device) {
    final advertised = <String>{};

    try {
      for (final raw in device.serviceUuids) {
        final value = _normalizeUuid(raw.toString());
        if (value.isNotEmpty && value != 'null') advertised.add(value);
      }
    } catch (_) {}

    for (final ad in device.adStructures ?? const <AdStructure>[]) {
      if (ad.type != 0x06 && ad.type != 0x07) continue;
      for (var i = 0; i + 16 <= ad.data.length; i += 16) {
        advertised.add(_uuidFromLittleEndian(ad.data.sublist(i, i + 16)));
      }
    }

    return advertised;
  }

  String? _winBleAdvertisedName(BleDevice device) {
    final name = device.name.trim();
    if (name.isNotEmpty && name.toUpperCase() != 'N/A') return name;

    for (final ad in device.adStructures ?? const <AdStructure>[]) {
      if (ad.type != 0x08 && ad.type != 0x09) continue;
      final decoded = String.fromCharCodes(
        ad.data,
      ).replaceAll('\u0000', '').trim();
      if (decoded.isNotEmpty) return decoded;
    }

    return null;
  }

  DiscoveredDevice _discoveredDeviceFromWinBle(BleDevice device, String name) {
    final serviceUuids = <Uuid>[];
    for (final value in _winBleServiceUuids(device)) {
      try {
        serviceUuids.add(Uuid.parse(value));
      } catch (_) {}
    }

    return DiscoveredDevice(
      id: device.address,
      name: name,
      serviceData: const <Uuid, List<int>>{},
      manufacturerData: List<int>.from(device.manufacturerData),
      rssi: int.tryParse(device.rssi) ?? 0,
      serviceUuids: serviceUuids,
    );
  }

  String _normalizeUuid(String raw) =>
      raw.replaceAll(RegExp(r'[{}]'), '').trim().toLowerCase();

  String _uuidFromLittleEndian(List<int> bytes) {
    final encoded =
        bytes.reversed
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
    return '${encoded.substring(0, 8)}-'
            '${encoded.substring(8, 12)}-'
            '${encoded.substring(12, 16)}-'
            '${encoded.substring(16, 20)}-'
            '${encoded.substring(20)}'
        .toLowerCase();
  }

  BleStatus _mapAdapterState(fbp.BluetoothAdapterState state) {
    switch (state) {
      case fbp.BluetoothAdapterState.on:
        return BleStatus.ready;
      case fbp.BluetoothAdapterState.off:
        return BleStatus.poweredOff;
      case fbp.BluetoothAdapterState.unauthorized:
        return BleStatus.unauthorized;
      case fbp.BluetoothAdapterState.unavailable:
        return BleStatus.unsupported;
      case fbp.BluetoothAdapterState.unknown:
      default:
        return BleStatus.unknown;
    }
  }

  DeviceConnectionState _mapConnectionState(
    fbp.BluetoothConnectionState state,
  ) {
    switch (state) {
      case fbp.BluetoothConnectionState.connecting:
        return DeviceConnectionState.connecting;
      case fbp.BluetoothConnectionState.connected:
        return DeviceConnectionState.connected;
      case fbp.BluetoothConnectionState.disconnecting:
        return DeviceConnectionState.disconnecting;
      case fbp.BluetoothConnectionState.disconnected:
        return DeviceConnectionState.disconnected;
    }
  }

  Future<fbp.BluetoothCharacteristic> _resolveCharacteristic(
    QualifiedCharacteristic target,
  ) async {
    final device = _deviceCache.putIfAbsent(
      target.deviceId,
      () => fbp.BluetoothDevice.fromId(target.deviceId),
    );

    final services = await device.discoverServices();
    final matchedService = services.firstWhere(
      (service) => _uuidsEqual(_serviceUuid(service), target.serviceId),
      orElse: () => throw StateError("Service ${target.serviceId} not found"),
    );

    final matchedChar = matchedService.characteristics.firstWhere(
      (char) => _uuidsEqual(_characteristicUuid(char), target.characteristicId),
      orElse:
          () =>
              throw StateError(
                "Characteristic ${target.characteristicId} not found",
              ),
    );

    return matchedChar;
  }

  Uuid _serviceUuid(fbp.BluetoothService service) {
    try {
      final dynamic candidate = (service as dynamic).serviceUuid;
      if (candidate is fbp.Guid) return Uuid.fromGuid(candidate);
    } catch (_) {}

    try {
      final dynamic candidate = (service as dynamic).uuid;
      if (candidate is fbp.Guid) return Uuid.fromGuid(candidate);
    } catch (_) {}

    throw StateError(StringConstants.unableToReadServiceUuid);
  }

  Uuid _characteristicUuid(fbp.BluetoothCharacteristic characteristic) {
    try {
      final dynamic candidate = (characteristic as dynamic).characteristicUuid;
      if (candidate is fbp.Guid) return Uuid.fromGuid(candidate);
    } catch (_) {}

    try {
      final dynamic candidate = (characteristic as dynamic).uuid;
      if (candidate is fbp.Guid) return Uuid.fromGuid(candidate);
    } catch (_) {}

    throw StateError(StringConstants.unableToReadCharacteristicUuid);
  }

  bool _uuidsEqual(Uuid a, Uuid b) =>
      a.value.toString().toLowerCase() == b.value.toString().toLowerCase();

  Stream<List<int>> _characteristicStream(
    fbp.BluetoothCharacteristic characteristic,
  ) {
    try {
      final dynamic candidate = (characteristic as dynamic).onValueReceived;
      if (candidate is Stream<List<int>>) return candidate;
    } catch (_) {}

    try {
      final dynamic candidate = (characteristic as dynamic).lastValueStream;
      if (candidate is Stream<List<int>>) return candidate;
    } catch (_) {}

    try {
      final dynamic candidate = (characteristic as dynamic).value;
      if (candidate is Stream<List<int>>) return candidate;
    } catch (_) {}

    return const Stream<List<int>>.empty();
  }
}
