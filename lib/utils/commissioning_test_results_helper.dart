import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';
import 'package:techno_switch_solar_app/widgets/commissioning_test_result_dialog.dart';

Future<void> showCommissioningTestResultConfirmation({
  required BuildContext context,
  required String deviceId,
  required CommissioningTestType type,
  required BleManager manager,
}) async {
  final items = _buildItems(type, manager);
  if (items.isEmpty) return;

  final cachedItems = await CommissioningTestResultsCache.loadItems(
    deviceId,
    type,
  );
  final initialResults = <String, String>{};
  for (final item in items) {
    final cached = CommissioningTestResultsCache.resultForItem(
      cachedItems,
      item.id,
    );
    if (cached != null && (cached == 'pass' || cached == 'fail')) {
      initialResults[item.id] = cached;
    }
  }

  final title = switch (type) {
    CommissioningTestType.walkTest => 'Walk Test Results',
    CommissioningTestType.relayTest => 'Relay Test Results',
    CommissioningTestType.sounderTest => 'Sounder Test Results',
  };

  if (!context.mounted) return;
  final results = await showCommissioningTestResultDialog(
    context: context,
    title: title,
    subtitle: 'Did each test pass or fail?',
    items: items,
    initialResults: initialResults,
  );

  if (results == null || results.isEmpty) return;
  await CommissioningTestResultsCache.mergeResults(deviceId, type, results);
}

List<CommissioningTestItem> _buildItems(
  CommissioningTestType type,
  BleManager manager,
) {
  return switch (type) {
    CommissioningTestType.walkTest => _walkTestItems(manager),
    CommissioningTestType.relayTest => _relayTestItems(manager),
    CommissioningTestType.sounderTest => _sounderTestItems(manager),
  };
}

List<CommissioningTestItem> _walkTestItems(BleManager manager) {
  final flags = [
    manager.isZoneOneSetupTest.value,
    manager.isZoneTwoSetupTest.value,
    manager.isZoneThreeSetupTest.value,
  ];
  return _itemsFromFlags(flags, 'Zone', 'z');
}

List<CommissioningTestItem> _relayTestItems(BleManager manager) {
  final flags = [
    manager.isRelayOneSetupTest.value,
    manager.isRelayTwoSetupTest.value,
    manager.isRelayThreeSetupTest.value,
  ];
  return _itemsFromFlags(flags, 'Relay', 'r');
}

List<CommissioningTestItem> _sounderTestItems(BleManager manager) {
  final flags = [
    manager.isSounderOneTest.value,
    manager.isSounderTwoTest.value,
    manager.isSounderThreeTest.value,
  ];
  return _itemsFromFlags(flags, 'Sounder', 's');
}

List<CommissioningTestItem> _itemsFromFlags(
  List<bool> flags,
  String prefix,
  String idPrefix,
) {
  final items = <CommissioningTestItem>[];
  for (var i = 0; i < flags.length; i++) {
    if (!flags[i]) continue;
    items.add(
      CommissioningTestItem(id: '$idPrefix${i + 1}', label: '$prefix ${i + 1}'),
    );
  }
  return items;
}

String commissioningTestItemLabel(CommissioningTestType type, String itemId) {
  final index = int.tryParse(itemId.replaceAll(RegExp(r'[^0-9]'), ''));
  if (index == null) return itemId.toUpperCase();

  final prefix = switch (type) {
    CommissioningTestType.walkTest => 'Zone',
    CommissioningTestType.relayTest => 'Relay',
    CommissioningTestType.sounderTest => 'Sounder',
  };
  return '$prefix $index';
}
