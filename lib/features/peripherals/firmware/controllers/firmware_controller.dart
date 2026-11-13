import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../../../models/ble/firmware/firmware_packet_model.dart';
import '../../../../utils/ble/firmware_packet_service.dart';
import 'package:Technoswitch/utils/ble/firmware_upgrade_service.dart';

class FirmwareController extends GetxController {
  final FirmwareUpgradeService _firmwareService = FirmwareUpgradeService();
  final FirmwarePacketService _packetService = FirmwarePacketService();
  final Rx<DownloadStatus> downloadingStatus = DownloadStatus.downloading.obs;
  final RxBool isFileCrcMatched = false.obs;
  final RxDouble progressbarCount = 0.0.obs;
  final RxInt progressbarIndex = 0.obs;
  final RxInt totalPacketLength = 0.obs;

  PlatformFile? selectedFirmwareFile;
  FirmwareValidationResult? validationResult;
  FirmwarePacketResult? packetResult;
  Uint8List? firmwareImage;
  String? validationError;

  void resetState() {
    downloadingStatus.value = DownloadStatus.downloading;
    isFileCrcMatched.value = false;
    progressbarCount.value = 0.0;
    progressbarIndex.value = 0;
    totalPacketLength.value = 0;
    validationResult = null;
    packetResult = null;
    firmwareImage = null;
    validationError = null;
  }

  void selectFirmwareFile(PlatformFile file) {
    resetState();
    selectedFirmwareFile = file;
  }

  FirmwareValidationResult? validateSelectedFile({
    String? requiredProductId,
    bool crcOnly = false,
  }) {
    if (selectedFirmwareFile == null) return null;

    final result = _firmwareService.validateFirmwareFile(
      selectedFirmwareFile!,
      requiredProductId: requiredProductId,
      crcOnly: crcOnly,
    );

    validationResult = result;
    isFileCrcMatched.value = result.isValid;
    validationError = result.error;
    return result;
  }

  Future<bool> preparePackets({bool verifyCrc = true}) async {
    if (selectedFirmwareFile == null ||
        validationResult == null ||
        !validationResult!.isValid) {
      return false;
    }

    try {
      final file = File(selectedFirmwareFile!.path!);

      firmwareImage = await _packetService.readVerifiedImage(
        file,
        verifyCrc: verifyCrc,
      );
      packetResult = null;
      totalPacketLength.value = 0;
      return firmwareImage!.isNotEmpty;
    } catch (e) {
      validationError = e.toString();
      return false;
    }
  }

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

    for (int i = 0; i < packets.length; i++) {
      progressbarIndex.value = i;
      progressbarCount.value = i / logicalTotal;

      await Future.delayed(packetDelay);
    }

    downloadingStatus.value = DownloadStatus.completed;
  }
}
