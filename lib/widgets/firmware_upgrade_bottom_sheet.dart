import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../ble/ble_manager.dart';
import '../ble/controller/ble_log_controller.dart';
import '../controllers/updates_controller.dart';
import '../models/ble/firmware/firmware_packet_model.dart';
import '../services/firmware_upgrade_service.dart' as fw;
import '../widgets/common/common_cta_button.dart';

enum FirmwareType { mainPanel, bleChip }

enum FirmwareUpgradeStep {
  essentialSteps,
  chooseType,
  fileUpload,
  fileDetails,
  progress,
  result,
}

class FirmwareUpgradeBottomSheet extends StatefulWidget {
  final String deviceId;

  const FirmwareUpgradeBottomSheet({super.key, required this.deviceId});

  @override
  State<FirmwareUpgradeBottomSheet> createState() =>
      _FirmwareUpgradeBottomSheetState();
}

class _FirmwareUpgradeBottomSheetState
    extends State<FirmwareUpgradeBottomSheet> {
  final UpdatesController _controller = Get.find<UpdatesController>();
  final BleManager _bleManager = Get.find<BleLogController>().bleManager;

  FirmwareUpgradeStep _currentStep = FirmwareUpgradeStep.essentialSteps;
  FirmwareType? _selectedFirmwareType;
  PlatformFile? _selectedFile;

  bool _isUploading = false;
  bool _isUpgrading = false;
  bool _isValidating = false;

  String? _errorMessage;
  String? _currentBleStateMessage;
  fw.FirmwareValidationResult? _validationResult;

  /* -------------------------------------------------------------------------- */
  /*                               OTA FLOW                                     */
  /* -------------------------------------------------------------------------- */

  Future<void> _startUpgrade() async {
    _controller.downloadingStatus.value = fw.DownloadStatus.upgrading;

    setState(() {
      _currentStep = FirmwareUpgradeStep.progress;
      _isUpgrading = true;
      _currentBleStateMessage = 'Preparing firmware upgrade...';
      _errorMessage = null;
    });

    final prepared = await _controller.preparePackets();
    if (!prepared || _controller.packetResult == null) {
      _fail('Failed to prepare firmware packets');
      return;
    }

    try {
      await _sendPacketsOverBle();
      _success();
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> _sendPacketsOverBle() async {
    final packets = _controller.packetResult!.packets;
    final total = _controller.packetResult!.totalLogicalPackets;

    _bleManager.resetFirmwareState();

    /* -------------------- JUMP TO BOOTLOADER -------------------- */
    if (_bleManager.bleManufacturerData.value != 1) {
      _currentBleStateMessage = 'Switching device to bootloader...';
      await _bleManager.registerNotifyHandlerForFirmwareUpgrade(
        isChipInBootLoader: false,
      );

      try {
        await _bleManager.sendJumpFirmwarePacket();
      } catch (_) {
        // expected: device disconnects
      }

      await _bleManager.waitForDeviceState(
        expectedState: BleDeviceState.bootloader,
        timeout: const Duration(seconds: 30),
      );
    }

    /* -------------------- START OTA -------------------- */
    await _bleManager.registerNotifyHandlerForFirmwareUpgrade(
      isChipInBootLoader: true,
    );

    await _bleManager.sendStartFirmwarePacket();
    await Future.delayed(const Duration(milliseconds: 300));

    int sent = 0;
    int lastSeq = 0;

    for (final FirmwarePacket pkt in packets) {
      await _bleManager.sendFirmwarePacket(
        Uint8List.fromList(pkt.bytes),
        isFirstPacketAfterSkip: pkt.sequence != lastSeq + 1,
      );
      lastSeq = pkt.sequence;
      sent++;

      _controller.progressbarIndex.value = sent;
      _controller.progressbarCount.value = sent / total;

      await Future.delayed(const Duration(milliseconds: 8));
    }

    /* -------------------- END OTA -------------------- */
    try {
      await _bleManager.sendEndFirmwarePacket();
    } catch (_) {}

    await _bleManager.waitForDeviceState(
      expectedState: BleDeviceState.upgradeSuccess,
      timeout: const Duration(seconds: 30),
    );
  }

  void _success() {
    setState(() {
      _isUpgrading = false;
      _currentStep = FirmwareUpgradeStep.result;
      _errorMessage = null;
      _currentBleStateMessage = null;
    });
    _controller.downloadingStatus.value = fw.DownloadStatus.completed;
  }

  void _fail(String message) {
    setState(() {
      _isUpgrading = false;
      _currentStep = FirmwareUpgradeStep.result;
      _errorMessage = message;
      _currentBleStateMessage = null;
    });
    _controller.downloadingStatus.value = fw.DownloadStatus.failed;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  UI                                        */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case FirmwareUpgradeStep.essentialSteps:
        return _essentialSteps();
      case FirmwareUpgradeStep.chooseType:
        return _chooseType();
      case FirmwareUpgradeStep.fileUpload:
        return _fileUpload();
      case FirmwareUpgradeStep.fileDetails:
        return _fileDetails();
      case FirmwareUpgradeStep.progress:
        return _progress();
      case FirmwareUpgradeStep.result:
        return _result();
    }
  }

  Widget _essentialSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Firmware Upgrade',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        const Text(
          '• Keep device powered on\n'
          '• Do not disconnect Bluetooth\n'
          '• Keep app in foreground',
        ),
        const SizedBox(height: 32),
        CommonCtaButton(
          onTap:
              () =>
                  setState(() => _currentStep = FirmwareUpgradeStep.chooseType),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _chooseType() {
    return Column(
      children: [
        _fwOption('Main Panel Firmware', FirmwareType.mainPanel),
        const SizedBox(height: 12),
        _fwOption('BLE Chip Firmware', FirmwareType.bleChip),
        const SizedBox(height: 32),
        CommonCtaButton(
          isDisabled: _selectedFirmwareType == null,
          onTap:
              () =>
                  setState(() => _currentStep = FirmwareUpgradeStep.fileUpload),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _fwOption(String title, FirmwareType type) {
    final selected = _selectedFirmwareType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFirmwareType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.red : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _fileUpload() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: DottedBorder(
            // childOnTop: false,
            options: RoundedRectDottedBorderOptions(
              color: Color(0xFFEC1D24).withOpacity(0.3),
              radius: Radius.circular(12),
              dashPattern: [5, 5],
              strokeWidth: 2,
              padding: EdgeInsets.all(0),
              stackFit: StackFit.passthrough,
            ),
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFFF6EBEB),
                // border: Border.all(
                //   color: Color(0xFFEC1D24).withOpacity(0.3),
                //   width: 2,
                //   style: BorderStyle.solid,
                // ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/upload_icon.svg',
                    width: 32,
                    height: 32,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedFile == null
                        ? 'Tap to select firmware file'
                        : _selectedFile!.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1F26),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    SizedBox(height: 8),
                    Text(
                      '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF979797),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        CommonCtaButton(
          isDisabled: _selectedFile == null,
          onTap: _goToFileDetails,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _fileDetails() {
    final valid = _controller.isFileCrcMatched.value;
    return Column(
      children: [
        Text(valid ? 'CRC Valid' : 'CRC Invalid'),
        const SizedBox(height: 32),
        CommonCtaButton(
          isDisabled: !valid,
          onTap: _startUpgrade,
          child: const Text('Start Upgrade'),
        ),
      ],
    );
  }

  Widget _progress() {
    return Obx(() {
      final progress = _controller.progressbarCount.value;
      return Column(
        children: [
          CircularPercentIndicator(
            radius: 80,
            percent: progress.clamp(0, 1),
            progressColor: Colors.red,
            center: Text('${(progress * 100).toStringAsFixed(1)}%'),
          ),
          const SizedBox(height: 16),
          Text(_currentBleStateMessage ?? 'Upgrading...'),
        ],
      );
    });
  }

  Widget _result() {
    final success =
        _controller.downloadingStatus.value == fw.DownloadStatus.completed;

    return Column(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.error,
          size: 80,
          color: success ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 16),
        Text(success ? 'Success' : 'Failed'),
        const SizedBox(height: 32),
        CommonCtaButton(
          onTap: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              HELPERS                                       */
  /* -------------------------------------------------------------------------- */

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );
    if (result == null) return;

    _controller.selectFirmwareFile(result.files.single);
    setState(() => _selectedFile = result.files.single);
  }

  Future<void> _goToFileDetails() async {
    setState(() => _isValidating = true);
    _validationResult = _controller.validateSelectedFile();
    setState(() {
      _isValidating = false;
      _currentStep = FirmwareUpgradeStep.fileDetails;
    });
  }
}
