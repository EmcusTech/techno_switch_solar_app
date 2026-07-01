import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/bindings/firmware_binding.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/bluetooth_service.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/app_styled_dialogs.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/ble_connecting_dialog.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/firmware_upgrade_bottom_sheet.dart';

/// True when scan MSD or post-connect [BleManager.bleManufacturerData] indicates bootloader.
bool isBleDeviceInBootloaderMode({
  required DiscoveredDevice device,
  BleManager? bleManager,
}) {
  if (BleMsdUtils.isBootloader(device.manufacturerData)) {
    return true;
  }
  if (bleManager != null &&
      bleManager.bleManufacturerData.value == BleMsdUtils.statusBootloader) {
    return true;
  }
  return false;
}

String _bootloaderUpgradeConnectMessage({
  required bool bootloaderFileCorrupted,
}) {
  if (bootloaderFileCorrupted) {
    return UiStrings.bootloaderFileCorruptedDoYouWantToUpdateMessage;
  }
  return '${UiStrings.firmwareUpgradeModeCannotUseNormallyPrefix}'
      '${UiStrings.doYouWantToUpdateFirmwareMessage}';
}

String _bootloaderUpgradeDashboardMessage({
  required bool bootloaderFileCorrupted,
}) {
  if (bootloaderFileCorrupted) {
    return StringConstants.theBootloaderFileOnTheDeviceIsCorrupted;
  }
  return StringConstants.tapOnUpdateToUpdateTheFirmware;
}

/// Connect-time offer: Cancel / Yes.
Future<bool?> showBootloaderUpgradeOfferDialog(
  BuildContext context, {
  bool bootloaderFileCorrupted = false,
}) {
  return showAppStyledTwoActionDialog<bool>(
    context: context,
    title: StringConstants.deviceIsInBootloaderMode,
    message: _bootloaderUpgradeConnectMessage(
      bootloaderFileCorrupted: bootloaderFileCorrupted,
    ),
    leadingActionLabel: StringConstants.cancel,
    trailingActionLabel: StringConstants.yes,
    leadingValue: false,
    trailingValue: true,
    icon: Icons.warning,
  );
}

/// Dashboard tile tap: Close / Update (same upgrade intent, different labels).
Future<bool?> showBootloaderUpgradeOfferFromDashboardDialog(
  BuildContext context, {
  bool bootloaderFileCorrupted = false,
}) {
  return showAppStyledTwoActionDialog<bool>(
    context: context,
    title: StringConstants.deviceIsInBootloaderMode,
    message: _bootloaderUpgradeDashboardMessage(
      bootloaderFileCorrupted: bootloaderFileCorrupted,
    ),
    leadingActionLabel: StringConstants.close,
    trailingActionLabel: StringConstants.update,
    leadingValue: false,
    trailingValue: true,
    icon: Icons.warning,
  );
}

Future<bool> showFirmwareUpgradeBottomSheetForConnect({
  required BuildContext context,
  required DiscoveredDevice connectedDevice,
}) async {
  FirmwareBinding().dependencies();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorConstants.transparent,
    isDismissible: false,
    enableDrag: false,
    builder:
        (sheetContext) =>
            FirmwareUpgradeBottomSheet(connectedDevice: connectedDevice),
  );
  Get.delete<UpdatesController>();
  return result ?? false;
}

Future<DiscoveredDevice?> reconnectBleDeviceInAppModeAfterUpgrade({
  required BleLogController bleController,
  required BluetoothService bluetoothService,
  required DiscoveredDevice originalDevice,
}) async {
  final bleManager = bleController.bleManager;

  await bleManager.disconnectConnectedDevice();
  await Future.delayed(const Duration(seconds: 2));

  await bluetoothService.requestPermissions();
  final poweredOn = await bluetoothService.ensurePoweredOn();
  if (!poweredOn) return null;

  await bluetoothService.startScanning();

  final stableId = BleNameUtils.getDisplayIdFromBleName(originalDevice.name);
  final originalName = originalDevice.name;

  final completer = Completer<DiscoveredDevice?>();
  StreamSubscription<List<DiscoveredDevice>>? sub;
  Timer? timer;

  sub = bluetoothService.scanResultsStream.listen((results) {
    for (final result in results) {
      if (BleMsdUtils.isBootloader(result.manufacturerData)) {
        continue;
      }

      final resultStableId = BleNameUtils.getDisplayIdFromBleName(result.name);
      final matchesStableId =
          stableId.isNotEmpty &&
          resultStableId.isNotEmpty &&
          resultStableId == stableId;
      final matchesName =
          originalName.isNotEmpty && result.name == originalName;

      if (matchesStableId || matchesName) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
        return;
      }
    }
  });

  timer = Timer(const Duration(seconds: 15), () {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  final found = await completer.future;
  timer.cancel();
  await sub.cancel();
  await bluetoothService.stopScanning();

  if (found == null) return null;

  await bleController.connectToDevice(device: found);

  if (!bleManager.handshakeCompleteNotifier.value) {
    final handshakeCompleter = Completer<void>();
    void listener() {
      if (bleManager.handshakeCompleteNotifier.value &&
          !handshakeCompleter.isCompleted) {
        handshakeCompleter.complete();
      }
    }

    bleManager.handshakeCompleteNotifier.addListener(listener);
    if (bleManager.handshakeCompleteNotifier.value &&
        !handshakeCompleter.isCompleted) {
      handshakeCompleter.complete();
    }

    try {
      await handshakeCompleter.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      bleManager.handshakeCompleteNotifier.removeListener(listener);
      return null;
    }
    bleManager.handshakeCompleteNotifier.removeListener(listener);
  }

  return found;
}

typedef BootloaderConnectAbortCallback = void Function();

/// If the device is in bootloader mode, offers firmware upgrade and reconnects
/// in application mode on success. Returns the device to use for the rest of
/// the connect flow, or `null` when the host should abort.
Future<DiscoveredDevice?> resolveBootloaderModeOnConnect({
  required BuildContext context,
  required BleLogController bleController,
  required BluetoothService bluetoothService,
  required DiscoveredDevice device,
  BootloaderConnectAbortCallback? onAbort,
}) async {
  if (!isBleDeviceInBootloaderMode(
    device: device,
    bleManager: bleController.bleManager,
  )) {
    return device;
  }

  final bootloaderFileCorrupted = BleMsdUtils.isBootloaderCorrupt(
    device.manufacturerData,
  );
  final wantUpgrade = await showBootloaderUpgradeOfferDialog(
    context,
    bootloaderFileCorrupted: bootloaderFileCorrupted,
  );
  if (wantUpgrade != true || !context.mounted) {
    await bleController.bleManager.disconnectConnectedDevice();
    onAbort?.call();
    return null;
  }

  final upgraded = await showFirmwareUpgradeBottomSheetForConnect(
    context: context,
    connectedDevice: device,
  );
  if (!upgraded || !context.mounted) {
    await bleController.bleManager.disconnectConnectedDevice();
    onAbort?.call();
    return null;
  }

  // Clear stale bootloader handshake before the reconnect dialog reads BLE notifiers.
  await bleController.bleManager.disconnectConnectedDevice();

  final refreshed = await runWithBleConnectingDialog<DiscoveredDevice?>(
    context: context,
    device: device,
    bleController: bleController,
    messages: BleConnectingDialogMessages.afterFirmwareUpgrade,
    operation:
        () => reconnectBleDeviceInAppModeAfterUpgrade(
          bleController: bleController,
          bluetoothService: bluetoothService,
          originalDevice: device,
        ),
  );
  if (refreshed == null || !context.mounted) {
    await bleController.bleManager.disconnectConnectedDevice();
    onAbort?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.deviceNotFoundAfterFirmwareUpgradeMessage),
        ),
      );
    }
    return null;
  }

  return refreshed;
}
