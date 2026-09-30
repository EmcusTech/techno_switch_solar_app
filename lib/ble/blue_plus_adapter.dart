import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:Technoswitch/utils/constants/string_constants.dart';
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
  QualifiedCharacteristic? _windowsNotifySubscription;
  Completer<void>? _windowsNotifyReady;

  /// Completes after the Windows notify characteristic is subscribed.
  Future<void> waitForWindowsNotifySubscription() {
    final ready = _windowsNotifyReady;
    if (ready == null) return Future<void>.value();
    return ready.future;
  }

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
    if (Platform.isWindows) {
      return _connectToDeviceWindows(id, connectionTimeout);
    }
    return _connectToDeviceAndroid(id, connectionTimeout);
  }

  Stream<ConnectionStateUpdate> _connectToDeviceWindows(
    String id,
    Duration? connectionTimeout,
  ) {
    final controller = StreamController<ConnectionStateUpdate>.broadcast();
    var connected = false;

    controller.add(
      ConnectionStateUpdate(
        deviceId: id,
        connectionState: DeviceConnectionState.connecting,
      ),
    );

    StreamSubscription<bool>? stateSub;

    () async {
      try {
        WinBle.stopScanning();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (controller.isClosed) return;

        final deadline = DateTime.now().add(
          connectionTimeout ?? const Duration(seconds: 10),
        );
        var services = <String>[];
        var attempts = 0;

        while (services.isEmpty &&
            attempts < 3 &&
            DateTime.now().isBefore(deadline) &&
            !controller.isClosed) {
          attempts++;
          final remaining = deadline.difference(DateTime.now());
          final attemptTimeout =
              remaining < const Duration(seconds: 4)
                  ? remaining
                  : const Duration(seconds: 4);
          try {
            await WinBle.connect(id).timeout(attemptTimeout);
          } catch (e) {
            debugPrint('WinBle connect attempt failed: $e');
          }

          services = await _readWinBleServices(id);
          if (services.isEmpty && !controller.isClosed) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            services = await _readWinBleServices(id);
          }
          debugPrint('WinBle services for $id: $services');
        }

        if (controller.isClosed) return;
        if (services.isEmpty) {
          controller.addError(StateError('WinBle connect failed for $id'));
          return;
        }

        connected = true;
        controller.add(
          ConnectionStateUpdate(
            deviceId: id,
            connectionState: DeviceConnectionState.connected,
          ),
        );

        stateSub = WinBle.connectionStreamOf(id).listen((isConnected) {
          if (isConnected || controller.isClosed) return;
          connected = false;
          controller.add(
            ConnectionStateUpdate(
              deviceId: id,
              connectionState: DeviceConnectionState.disconnected,
            ),
          );
        });
      } catch (e, stack) {
        debugPrint('WinBle connect failed: $e');
        debugPrint('$stack');
        if (!controller.isClosed) controller.addError(e, stack);
      }
    }();

    controller.onCancel = () async {
      await stateSub?.cancel();
      if (!connected) return;
      await _releaseWindowsSubscription();
      try {
        await WinBle.disconnect(id);
      } catch (e) {
        debugPrint('WinBle disconnect failed: $e');
      }
    };

    return controller.stream;
  }

  Stream<ConnectionStateUpdate> _connectToDeviceAndroid(
    String id,
    Duration? connectionTimeout,
  ) {
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
    if (Platform.isWindows) {
      await _releaseWindowsSubscription();
      try {
        await WinBle.disconnect(id);
      } catch (e) {
        debugPrint('WinBle disconnect failed: $e');
      }
      return;
    }

    final device = _deviceCache.remove(id);
    if (device == null) return;
    try {
      await device.disconnect();
    } catch (_) {}
  }

  Future<int> requestMtu({required String deviceId, required int mtu}) async {
    if (Platform.isWindows) return _requestMtuWindows(deviceId, mtu);

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

  Future<List<String>> _readWinBleServices(String id) async {
    try {
      return await WinBle.discoverServices(id);
    } catch (e) {
      debugPrint('WinBle discoverServices failed: $e');
      return const <String>[];
    }
  }

  Future<int> _requestMtuWindows(String deviceId, int mtu) async {
    try {
      final size = await WinBle.getMaxMtuSize(deviceId);
      if (size is int && size > 0) return size;
      final parsed = int.tryParse(size.toString());
      if (parsed != null && parsed > 0) return parsed;
    } catch (e) {
      debugPrint('WinBle getMaxMtuSize failed: $e');
    }
    return mtu;
  }

  Stream<List<int>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
  ) {
    if (Platform.isWindows) {
      return _subscribeToCharacteristicWindows(characteristic);
    }
    return _subscribeToCharacteristicAndroid(characteristic);
  }

  Stream<List<int>> _subscribeToCharacteristicWindows(
    QualifiedCharacteristic characteristic,
  ) {
    final controller = StreamController<List<int>>();
    StreamSubscription<dynamic>? valueSub;
    final ready = Completer<void>();
    _windowsNotifyReady = ready;

    controller.onListen = () async {
      try {
        await _ensureWindowsSubscription(characteristic);
        if (controller.isClosed) {
          await _releaseWindowsSubscription(characteristic);
          if (!ready.isCompleted) {
            ready.completeError(
              StateError('Windows notify subscription cancelled'),
            );
          }
          return;
        }
        if (!ready.isCompleted) ready.complete();
        valueSub = WinBle.characteristicValueStreamOf(
          address: characteristic.deviceId,
          serviceId: _winBleUuid(characteristic.serviceId),
          characteristicId: _winBleUuid(characteristic.characteristicId),
        ).listen(
          (value) {
            if (!controller.isClosed) {
              controller.add(_winBleValueBytes(value));
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          },
        );
      } catch (e, stack) {
        if (!ready.isCompleted) ready.completeError(e, stack);
        if (!controller.isClosed) controller.addError(e, stack);
      }
    };
    controller.onCancel = () async {
      if (!ready.isCompleted) {
        ready.completeError(StateError('Windows notify subscription cancelled'));
      }
      await valueSub?.cancel();
      await _releaseWindowsSubscription(characteristic);
    };

    return controller.stream;
  }

  Future<void> _ensureWindowsSubscription(
    QualifiedCharacteristic characteristic,
  ) async {
    final address = characteristic.deviceId;
    final serviceId = _winBleUuid(characteristic.serviceId);
    final characteristicId = _winBleUuid(characteristic.characteristicId);

    Future<void> subscribe() {
      return WinBle.subscribeToCharacteristic(
        address: address,
        serviceId: serviceId,
        characteristicId: characteristicId,
      );
    }

    try {
      await subscribe();
    } catch (e) {
      final closed = e.toString().toLowerCase().contains('closed');
      if (closed) {
        debugPrint('WinBle subscribe hit a closed device, reconnecting: $e');
        await _releaseWindowsSubscription(characteristic);
        try {
          await WinBle.connect(address);
        } catch (connectError) {
          debugPrint('WinBle reconnect before subscribe failed: $connectError');
        }
        await subscribe();
      } else {
        debugPrint('WinBle subscribe failed, trying pair: $e');
        try {
          final paired = await WinBle.isPaired(address, forceRefresh: true);
          if (!paired) await WinBle.pair(address);
        } catch (pairError) {
          debugPrint('WinBle pair failed: $pairError');
        }
        await subscribe();
      }
    }

    _windowsNotifySubscription = characteristic;
  }

  Future<void> _releaseWindowsSubscription([
    QualifiedCharacteristic? characteristic,
  ]) async {
    final stored = _windowsNotifySubscription;
    final current = characteristic ?? stored;
    if (current == null) return;
    if (stored != null &&
        characteristic != null &&
        (stored.deviceId != characteristic.deviceId ||
            stored.characteristicId != characteristic.characteristicId)) {
      return;
    }
    if (stored == null ||
        (stored.deviceId == current.deviceId &&
            stored.characteristicId == current.characteristicId)) {
      _windowsNotifySubscription = null;
    }
    try {
      await WinBle.unSubscribeFromCharacteristic(
        address: current.deviceId,
        serviceId: _winBleUuid(current.serviceId),
        characteristicId: _winBleUuid(current.characteristicId),
      );
    } catch (e) {
      debugPrint('WinBle unsubscribe failed: $e');
    }
  }

  Stream<List<int>> _subscribeToCharacteristicAndroid(
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
    if (Platform.isWindows) {
      await _writeWindows(characteristic, value, false);
      return;
    }
    final fbp.BluetoothCharacteristic char = await _resolveCharacteristic(
      characteristic,
    );
    await char.write(value, withoutResponse: true);
  }

  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<int> value,
  }) async {
    if (Platform.isWindows) {
      await _writeWindows(characteristic, value, true);
      return;
    }
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
      final decoded =
          String.fromCharCodes(ad.data).replaceAll('\u0000', '').trim();
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

  Future<void> _writeWindows(
    QualifiedCharacteristic characteristic,
    List<int> value,
    bool writeWithResponse,
  ) {
    return WinBle.write(
      address: characteristic.deviceId,
      service: _winBleUuid(characteristic.serviceId),
      characteristic: _winBleUuid(characteristic.characteristicId),
      data: Uint8List.fromList(value),
      writeWithResponse: writeWithResponse,
    );
  }

  String _winBleUuid(Uuid uuid) => _normalizeUuid(uuid.toString());

  List<int> _winBleValueBytes(dynamic value) {
    if (value is Uint8List) return List<int>.from(value);
    if (value is List<int>) return List<int>.from(value);
    if (value is List) {
      return value
          .map((item) => item is int ? item : int.parse('$item'))
          .toList();
    }
    return const <int>[];
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
