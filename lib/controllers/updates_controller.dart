import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import '../models/ble/firmware/firmware_packet_model.dart';
import '../services/firmware_packet_service.dart';
import 'package:techno_switch_solar_app/services/firmware_upgrade_service.dart';

class UpdatesController extends GetxController {
  final FirmwareUpgradeService _firmwareService = FirmwareUpgradeService();
  final FirmwarePacketService _packetService = FirmwarePacketService();

  // UI-observed state
  final Rx<DownloadStatus> downloadingStatus = DownloadStatus.downloading.obs;
  final RxBool isFileCrcMatched = false.obs;
  final RxDouble progressbarCount = 0.0.obs;
  final RxInt progressbarIndex = 0.obs;
  final RxInt totalPacketLength = 0.obs;

  PlatformFile? selectedFirmwareFile;
  FirmwareValidationResult? validationResult;
  FirmwarePacketResult? packetResult;
  String? validationError;

  void resetState() {
    downloadingStatus.value = DownloadStatus.downloading;
    isFileCrcMatched.value = false;
    progressbarCount.value = 0.0;
    progressbarIndex.value = 0;
    totalPacketLength.value = 0;
    validationResult = null;
    packetResult = null;
    validationError = null;
  }

  void selectFirmwareFile(PlatformFile file) {
    resetState();
    selectedFirmwareFile = file;
  }

  /// STEP 1 - CRC, trailer fields, and optional product ID
  FirmwareValidationResult? validateSelectedFile({String? requiredProductId}) {
    if (selectedFirmwareFile == null) return null;

    final result = _firmwareService.validateFirmwareFile(
      selectedFirmwareFile!,
      requiredProductId: requiredProductId,
    );

    validationResult = result;
    isFileCrcMatched.value = result.isValid;
    validationError = result.error;
    return result;
  }

  /// STEP 2 - Packet preparation (service-based)
  Future<bool> preparePackets() async {
    if (selectedFirmwareFile == null ||
        validationResult == null ||
        !validationResult!.isValid) {
      return false;
    }

    try {
      final file = File(selectedFirmwareFile!.path!);

      packetResult = await _packetService.processBinFile(file);

      totalPacketLength.value = packetResult!.totalLogicalPackets;
      return packetResult!.packets.isNotEmpty;
    } catch (e) {
      validationError = e.toString();
      return false;
    }
  }

  /// STEP 3 - Progress simulation (replace with BLE sender later)
  Future<void> simulateUpgradeProgress({
    Duration packetDelay = const Duration(milliseconds: 35),
  }) async {
    if (packetResult == null || packetResult!.packets.isEmpty) {
      downloadingStatus.value = DownloadStatus.failed;
      return;
    }

    downloadingStatus.value = DownloadStatus.upgrading;

    final packets = packetResult!.packets;
    final logicalTotal = packetResult!.totalLogicalPackets;

    int logicalIndex = 0;

    // await Get.find<BleLogController>().bleManager.sendStartFirmwarePacket();

    // await Future.delayed(const Duration(milliseconds: 300));

    // await Get.find<BleLogController>().bleManager.sendFirmwarePacket(
    //   Uint8List.fromList(packets[0].bytes),
    // );

    for (final packet in packets) {
      print("Sending packet: ${packet.sequence}");
      print(
        "Packet: ${packet.bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
      );
      logicalIndex++;

      progressbarIndex.value = logicalIndex;
      progressbarCount.value = logicalIndex / logicalTotal;

      await Future.delayed(packetDelay);
    }

    downloadingStatus.value = DownloadStatus.completed;
  }
}
