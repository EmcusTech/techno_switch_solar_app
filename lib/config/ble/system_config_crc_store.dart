import 'package:flutter/foundation.dart';
import 'package:Technoswitch/config/structs/system_config_def.dart';
import 'package:Technoswitch/utils/constants/ble/ble_msd_utils.dart';
import 'package:Technoswitch/utils/peripherals/peripheral_setup_cache_resolver.dart';
import 'package:Technoswitch/utils/storage/peripheral_setup_cache.dart';

enum SystemConfigCrcCheck { missingLocal, match, mismatch, noAdvertisedCrc }

class SystemConfigCrcResult {
  const SystemConfigCrcResult({
    required this.check,
    this.advertised,
    this.stored,
  });

  final SystemConfigCrcCheck check;
  final int? advertised;
  final int? stored;
}

abstract final class SystemConfigCrcStore {
  static Future<void> save({
    required int crc,
    required String primaryDeviceId,
    String? bleName,
    String? panelVersionNo,
    Uint8List? image,
  }) async {
    final value = crc & 0xFFFF;
    final ids = PeripheralSetupCacheResolver.cacheDeviceIdCandidates(
      primaryDeviceId: primaryDeviceId,
      bleName: bleName,
      panelVersionNo: panelVersionNo,
    );
    final seen = <String>{};
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      await PeripheralSetupCache.saveSystemConfigCrc(trimmed, value);
      if (image != null) {
        await PeripheralSetupCache.saveSystemConfigImage(trimmed, image);
      }
    }
  }

  static Future<Uint8List?> loadImage({
    required String primaryDeviceId,
    String? bleName,
    String? panelVersionNo,
  }) async {
    final ids = PeripheralSetupCacheResolver.cacheDeviceIdCandidates(
      primaryDeviceId: primaryDeviceId,
      bleName: bleName,
      panelVersionNo: panelVersionNo,
    );
    for (final id in ids) {
      final image = await PeripheralSetupCache.loadSystemConfigImage(id);
      if (image != null && image.length >= SystemConfigDef.byteLength) {
        return Uint8List.fromList(image.sublist(0, SystemConfigDef.byteLength));
      }
    }
    return null;
  }

  static Future<int?> load({
    required String primaryDeviceId,
    String? bleName,
    String? panelVersionNo,
  }) {
    final ids = PeripheralSetupCacheResolver.cacheDeviceIdCandidates(
      primaryDeviceId: primaryDeviceId,
      bleName: bleName,
      panelVersionNo: panelVersionNo,
    );
    return PeripheralSetupCacheResolver.loadMap(ids, (id) async {
      final crc = await PeripheralSetupCache.loadSystemConfigCrc(id);
      if (crc == null) return null;
      return {'crc': crc};
    }).then((data) => data?['crc'] as int?);
  }

  static Future<SystemConfigCrcResult> check({
    required List<int> manufacturerData,
    required String primaryDeviceId,
    String? bleName,
    String? panelVersionNo,
  }) async {
    final advertised = BleMsdUtils.advertisedConfigCrc(manufacturerData);
    if (advertised == null) {
      return const SystemConfigCrcResult(
        check: SystemConfigCrcCheck.noAdvertisedCrc,
      );
    }
    final stored = await load(
      primaryDeviceId: primaryDeviceId,
      bleName: bleName,
      panelVersionNo: panelVersionNo,
    );
    if (stored == null) {
      return SystemConfigCrcResult(
        check: SystemConfigCrcCheck.missingLocal,
        advertised: advertised,
      );
    }
    final storedCrc = stored & 0xFFFF;
    return SystemConfigCrcResult(
      check:
          storedCrc == advertised
              ? SystemConfigCrcCheck.match
              : SystemConfigCrcCheck.mismatch,
      advertised: advertised,
      stored: storedCrc,
    );
  }

  static Future<void> logScan({
    required String name,
    required String deviceId,
    required List<int> manufacturerData,
  }) async {
    final result = await check(
      manufacturerData: manufacturerData,
      primaryDeviceId: deviceId,
      bleName: name,
    );
    debugPrint(
      'SYSTEM_CONFIG scan crc '
      'name=$name '
      'advertised=${_hex(result.advertised)} '
      'stored=${_hex(result.stored)} '
      'check=${result.check.name}',
    );
  }

  static String _hex(int? value) {
    if (value == null) return 'none';
    return value.toRadixString(16);
  }
}
