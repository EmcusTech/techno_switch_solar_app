import 'dart:async';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:Technoswitch/ble/ble_session_idle_policy.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/common/common_cta_button.dart';
import 'package:Technoswitch/bindings/firmware_binding.dart';
import '../../../../ble/ble_manager.dart';
import '../../../../ble/controller/ble_log_controller.dart';
import '../controllers/firmware_controller.dart';
import 'package:Technoswitch/utils/ble/firmware_upgrade_service.dart' as fw;
import 'package:Technoswitch/utils/logger.dart' as logger;
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/widgets/common/app_notice.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';

enum FirmwareType { mainPanel, bleChip }

enum FirmwareUpgradeStep {
  essentialSteps,
  connectDevice,
  chooseType,
  fileUpload,
  fileDetails,
  progress,
  result,
}

class FirmwareUpgradeBottomSheet extends StatefulWidget {
  final DiscoveredDevice? connectedDevice;

  const FirmwareUpgradeBottomSheet({super.key, this.connectedDevice});

  @override
  State<FirmwareUpgradeBottomSheet> createState() =>
      _FirmwareUpgradeBottomSheetState();
}

class _FirmwareUpgradeBottomSheetState
    extends State<FirmwareUpgradeBottomSheet> {
  late final FirmwareController _controller;
  StreamSubscription<fw.DownloadStatus>? _statusSub;
  final BleManager ble = Get.find<BleManager>();
  FirmwareUpgradeStep _currentStep = FirmwareUpgradeStep.essentialSteps;
  FirmwareType? _selectedFirmwareType;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isUpgrading = false;
  bool _isValidating = false;
  String? _errorMessage;
  String? _currentBleStateMessage;
  fw.FirmwareValidationResult? _validationResult;

  void _beginFirmwareSession() {
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = true;
    BleSessionIdlePolicy.suppressIdleDisconnect.value = true;
  }

  void _endFirmwareSession() {
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = false;
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
  }

  @override
  void initState() {
    super.initState();
    FirmwareBinding().dependencies();
    _controller = Get.find<FirmwareController>();

    _statusSub = _controller.downloadingStatus.listen((status) {
      if (mounted) {
        if (status == fw.DownloadStatus.upgrading) {
          setState(() {
            if (_currentStep == FirmwareUpgradeStep.fileDetails ||
                _currentStep == FirmwareUpgradeStep.progress) {
              _currentStep = FirmwareUpgradeStep.progress;
              _isUpgrading = true;
            }
          });
        } else if (status == fw.DownloadStatus.completed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage = null;
          });
        } else if (status == fw.DownloadStatus.failed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage =
                _errorMessage ?? StringConstants.firmwareUpgradeFailed;
          });
        }
      }
    });
  }

  Future<void> _sendPacketsOverBle() async {
    if (_controller.firmwareImage == null ||
        _controller.firmwareImage!.isEmpty) {
      throw Exception(StringConstants.noPacketsPrepared);
    }

    _beginFirmwareSession();
    try {
      await _sendPacketsOverBleImpl();
    } finally {
      _endFirmwareSession();
    }
  }

  Future<void> _sendPacketsOverBleImpl() async {
    final manager =
        Get.isRegistered<BleLogController>()
            ? Get.find<BleLogController>().bleManager
            : ble;
    final image = _controller.firmwareImage!;
    final DiscoveredDevice? device =
        widget.connectedDevice ?? manager.selectedDevice;
    logger.Logger(
      'Firmware upgrade start ${device?.name ?? ''} bytes=${image.length}',
    );
    final DateTime started = DateTime.now();
    await manager.bleProcess.beginFirmwareUpgrade(
      image,
      onProgress: (sent, total) {
        _controller.progressbarIndex.value = sent;
        _controller.totalPacketLength.value = total;
        _controller.progressbarCount.value = total == 0 ? 0 : sent / total;
      },
    );
    final double seconds =
        DateTime.now().difference(started).inMilliseconds / 1000;
    _controller.downloadingStatus.value = fw.DownloadStatus.completed;
    if (!mounted) return;
    showAppNotice(
      context,
      message: 'Firmware upgrade took ${seconds.toStringAsFixed(1)} s',
    );
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _endFirmwareSession();
    if (Get.isRegistered<FirmwareController>()) {
      Get.delete<FirmwareController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool upgradeInProgress =
        _currentStep == FirmwareUpgradeStep.progress || _isUpgrading;
    final bool showPhoneChrome =
        !PeripheralSheetChrome.flat && !upgradeInProgress;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PeripheralSheetDragHandle(),
        _buildHeader(showClose: !upgradeInProgress),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: peripheralSheetScrollPadding(bottom: 24),
            child: _buildStepContent(),
          ),
        ),
      ],
    );
    final sheet = Container(
      decoration: BoxDecoration(
        color: PeripheralSheetChrome.lipColor,
        borderRadius: PeripheralSheetChrome.topRadius(),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: PeripheralSheetChrome.lipPadding),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: PeripheralSheetChrome.topRadius(),
          ),
          child: Stack(
            children: [
              if (showPhoneChrome) const PeripheralSheetHeaderRow(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  showPhoneChrome ? 52 : 16,
                  24,
                  0,
                ),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async => !upgradeInProgress,
      child:
          PeripheralSheetChrome.flat
              ? sheet
              : SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                  ),
                  child: sheet,
                ),
              ),
    );
  }

  Widget _buildHeader({required bool showClose}) {
    return Row(
      children: [
        Text(
          StringConstants.firmwareUpgrade,
          style: StyleConstants.textDark20w700Style,
        ),
        const Spacer(),
        if (showClose && PeripheralSheetChrome.flat)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case FirmwareUpgradeStep.essentialSteps:
        return _buildEssentialSteps();
      case FirmwareUpgradeStep.chooseType:
        return _buildChooseType();
      case FirmwareUpgradeStep.fileUpload:
        return _buildFileUpload();
      case FirmwareUpgradeStep.fileDetails:
        return _buildFileDetails();
      case FirmwareUpgradeStep.progress:
        return _buildProgress();
      case FirmwareUpgradeStep.result:
        return _buildResult();
      case FirmwareUpgradeStep.connectDevice:
        // This step is no longer used - device is already connected
        return _buildChooseType();
    }
  }

  Widget _buildEssentialSteps() {
    final steps = [
      StringConstants.essentialStepConnectViaBluetooth,
      StringConstants.essentialStepKeepPoweredOn,
      StringConstants.essentialStepDoNotDisconnect,
      StringConstants.essentialStepCloseOtherApps,
    ];

    return FutureBuilder<bool>(
      future: _checkBleConnection(),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              StringConstants.essentialStepsBeforeFirmwareUpgrade,
              style: StyleConstants.black18w700Style,
            ),
            SizedBox(height: 24),

            ...steps.map(
              (step) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.primary.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: StyleConstants.textHeading14w400Style,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            CommonCtaButton(
              onTap: () {
                setState(() {
                  // Skip connectDevice step - device is already connected
                  _currentStep = FirmwareUpgradeStep.chooseType;
                });
              },
              child: Text(
                StringConstants.disabled,
                style: StyleConstants.white16w600Style,
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            // setState(() {
            //   _currentStep =
            //       _testMode
            //           ? FirmwareUpgradeStep.chooseType
            //           : FirmwareUpgradeStep.connectDevice;
            // });
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: ColorConstants.primary,
            //     padding: EdgeInsets.symmetric(vertical: 16),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            //   child: Text(
            //     StringConstants.disabled,
            //     style: StyleConstants.white16w600Style,
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Future<bool> _checkBleConnection() async {
    try {
      final bleManager = Get.find<BleManager>();
      return bleManager.isConnected;
    } catch (e) {
      logger.Logger('Error checking BLE connection: $e');
      return false;
    }
  }

  // Removed _buildConnectDevice and all scanning UI methods - device is already connected
  // All scanning-related methods have been removed since we use the existing BLE connection

  Widget _buildChooseType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          StringConstants.chooseFirmwareType,
          style: StyleConstants.black18w700Style,
        ),
        SizedBox(height: 24),
        _buildFirmwareTypeOption(
          title: StringConstants.mainPanelFirmware,
          description: StringConstants.upgradeMainPanelFirmwareDescription,
          type: FirmwareType.mainPanel,
          enabled: false,
        ),
        SizedBox(height: 16),
        _buildFirmwareTypeOption(
          title: StringConstants.bleChipFirmware,
          description: StringConstants.upgradeBleChipFirmwareDescription,
          type: FirmwareType.bleChip,
        ),
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                onTap: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.essentialSteps;
                  });
                },
                color: ColorConstants.buttonSecondaryBackground,
                child: Text(
                  StringConstants.back,
                  style: StyleConstants.labelText16w600Style,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    _selectedFirmwareType == null
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileUpload;
                          });
                        },
                isDisabled: _selectedFirmwareType == null,
                child: Text(
                  StringConstants.disabled,
                  style: StyleConstants.white16w600Style,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirmwareTypeOption({
    required String title,
    required String description,
    required FirmwareType type,
    bool enabled = true,
  }) {
    final isSelected = _selectedFirmwareType == type;
    return GestureDetector(
      onTap:
          enabled
              ? () {
                setState(() {
                  _selectedFirmwareType = type;
                });
              }
              : null,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              !enabled
                  ? Colors.grey.shade200
                  : (isSelected
                      ? ColorConstants.primary.withOpacity(0.1)
                      : ColorConstants.white),
          border: Border.all(
            color:
                isSelected
                    ? ColorConstants.primary
                    : ColorConstants.progressTrack,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? ColorConstants.primary
                          : ColorConstants.progressTrack,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstants.primary,
                          ),
                        ),
                      )
                      : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: StyleConstants.textHeading16w600Style),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: StyleConstants.textDisabled14w400Style,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          StringConstants.uploadFirmwareFile,
          style: StyleConstants.black18w700Style,
        ),
        SizedBox(height: 24),
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: DottedBorder(
            // childOnTop: false,
            options: RoundedRectDottedBorderOptions(
              color: ColorConstants.primary.withOpacity(0.3),
              radius: Radius.circular(12),
              dashPattern: [5, 5],
              strokeWidth: 2,
              padding: EdgeInsets.all(0),
              stackFit: StackFit.passthrough,
            ),
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ColorConstants.scaffoldGradientTop,
                // border: Border.all(
                //   color: ColorConstants.primary.withOpacity(0.3),
                //   width: 2,
                //   style: BorderStyle.solid,
                // ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    AssetConstants.uploadIcon,
                    width: 32,
                    height: 32,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedFile == null
                        ? StringConstants.tapToSelectFirmwareFile
                        : _selectedFile!.name,
                    style: StyleConstants.textHeading16w600Style,
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    SizedBox(height: 8),
                    Text(
                      '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: StyleConstants.textDisabled14w400Style,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_isUploading) ...[
          SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: ColorConstants.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.primary),
          ),
        ],
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                onTap: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.chooseType;
                  });
                },
                color: ColorConstants.buttonSecondaryBackground,
                child: Text(
                  StringConstants.back,
                  style: StyleConstants.labelText16w600Style,
                ),
              ),
            ),
            // Expanded(
            //   child: OutlinedButton(
            //     onPressed: () {
            //       setState(() {
            //         _currentStep = FirmwareUpgradeStep.chooseType;
            //       });
            //     },
            //     style: OutlinedButton.styleFrom(
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       side: BorderSide(color: ColorConstants.primary),
            //     ),
            //     child: Text(
            //       StringConstants.back,
            //       style: StyleConstants.primary16w600Style,
            //     ),
            //   ),
            // ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    _selectedFile == null || _isUploading
                        ? null
                        : _goToFileDetails,
                isDisabled: _selectedFile == null || _isUploading,
                child: Text(
                  StringConstants.disabled,
                  style: StyleConstants.white16w600Style,
                ),
              ),
            ),
            // Expanded(
            //   child: ElevatedButton(
            //     onPressed:
            //         _selectedFile == null || _isUploading
            //             ? null
            //             : _goToFileDetails,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: ColorConstants.primary,
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       disabledBackgroundColor: ColorConstants.progressTrack,
            //     ),
            //     child: Text(
            //       StringConstants.disabled,
            //       style: StyleConstants.white16w600Style,
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileDetails() {
    if (_selectedFile == null) return SizedBox();

    final result = _validationResult;
    final isCrcMatched = _controller.isFileCrcMatched.value;
    final expectedCrc = result?.expectedHex ?? '-';
    final calculatedCrc = result?.calculatedHex ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          StringConstants.fileDetails,
          style: StyleConstants.black18w700Style,
        ),
        SizedBox(height: 24),
        _buildDetailRow(StringConstants.fileName, _selectedFile!.name),
        SizedBox(height: 12),
        _buildDetailRow(
          StringConstants.fileSize,
          '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
        ),
        SizedBox(height: 12),
        _buildDetailRow(
          StringConstants.firmwareTypeLabel,
          _selectedFirmwareType == FirmwareType.mainPanel
              ? StringConstants.mainPanelFirmware
              : StringConstants.bleChipFirmware,
        ),
        if (result != null) ...[
          SizedBox(height: 12),
          _buildDetailRow(
            StringConstants.firmwareVersion2,
            _emptyToDash(result.firmwareVersion),
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            StringConstants.hardwareVersion2,
            _emptyToDash(result.hardwareVersion),
          ),
          SizedBox(height: 12),
          _buildDetailRow(StringConstants.buildDate, _emptyToDash(result.date)),
          SizedBox(height: 12),
          _buildDetailRow(
            StringConstants.productId,
            _emptyToDash(result.productId),
          ),
        ],
        Visibility(
          visible: !isCrcMatched,
          child: Column(
            children: [
              SizedBox(height: 12),
              _buildDetailRow(StringConstants.expectedCrc, expectedCrc),
              SizedBox(height: 12),
              _buildDetailRow(StringConstants.calculatedCrc, calculatedCrc),
            ],
          ),
        ),
        SizedBox(height: 12),
        _buildDetailRow(
          StringConstants.statusLabel,
          _isValidating
              ? StringConstants.validating2
              : isCrcMatched
              ? StringConstants.validLabel
              : StringConstants.invalidLabel,
          valueColor:
              _isValidating
                  ? ColorConstants.textDisabled
                  : isCrcMatched
                  ? ColorConstants.success
                  : ColorConstants.primary,
        ),
        if (_isValidating) ...[
          SizedBox(height: 16),
          Center(child: CircularProgressIndicator()),
        ],
        if (!_isValidating && !isCrcMatched)
          Container(
            margin: EdgeInsets.only(top: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: ColorConstants.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _validationResult?.error ??
                        StringConstants.fileCrcValidationFailedSelectValidFile,
                    style: StyleConstants.primary14w400Style,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                color: ColorConstants.buttonSecondaryBackground,
                onTap:
                    _isValidating
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileUpload;
                          });
                        },
                isDisabled: _isValidating,
                child: Text(
                  StringConstants.back,
                  style: StyleConstants.labelText16w600Style,
                ),
              ),
            ),
            // Expanded(
            //   child: OutlinedButton(
            //     onPressed:
            //         _isValidating
            //             ? null
            //             : () {
            //               setState(() {
            //                 _currentStep = FirmwareUpgradeStep.fileUpload;
            //               });
            //             },
            //     style: OutlinedButton.styleFrom(
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       side: BorderSide(color: ColorConstants.primary),
            //     ),
            //     child: Text(
            //       StringConstants.back,
            //       style: StyleConstants.primary16w600Style,
            //     ),
            //   ),
            // ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    (_isValidating || !isCrcMatched)
                        ? null
                        : () async {
                          await _onValidationContinuePressed();
                        },
                isDisabled: _isValidating || !isCrcMatched,
                child: Text(
                  StringConstants.disabled,
                  style: StyleConstants.white16w600Style,
                ),
              ),
            ),
            // Expanded(
            //   flex: 2,
            //   child: ElevatedButton(
            //     onPressed:
            //         (_isValidating || !isCrcMatched)
            //             ? null
            //             : () {
            //               _startUpgrade(
            //                 isChipInBootLoader:
            //                     _selectedDevice?.manufacturerData.last == 1,
            //               );
            //             },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: ColorConstants.primary,
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       disabledBackgroundColor: ColorConstants.progressTrack,
            //     ),
            //     child: Text(
            //       StringConstants.disabled,
            //       style: StyleConstants.white16w600Style,
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  String _emptyToDash(String s) => s.isEmpty ? '-' : s;

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: StyleConstants.textDisabled14w400Style),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Text(
            value,
            style: StyleConstants.primary14w600Style.copyWith(
              color: valueColor ?? ColorConstants.textHeading,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Obx(() {
      final progress = _controller.progressbarCount.value;
      final status = _controller.downloadingStatus.value;

      // Always show the normal progress UI, even during reconnection phases
      // This hides the reconnection/status fetching messages and shows only the upload progress
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text(
          //   'Firmware Upgrade in Progress',
          //   style: StyleConstants.black18w700Style,
          // ),
          // SizedBox(height: 32),
          Center(
            child:
                (progress * 100).toStringAsFixed(1) == '0.0'
                    ? Lottie.asset(AssetConstants.bleConnectingJson)
                    : CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 8,
                      percent: progress.clamp(0.0, 1.0),
                      center: Lottie.asset(AssetConstants.firmwareUpgradeJson),
                      progressColor: ColorConstants.primary,
                      backgroundColor: ColorConstants.progressTrack,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
          ),
          SizedBox(height: 12),
          Visibility(
            visible: !((progress * 100).toStringAsFixed(1) == '0.0'),
            child: Center(
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: StyleConstants.primary24w700Style,
              ),
            ),
          ),
          // if (totalPackets > 0)
          //   Text(
          //     'Packet $currentIndex of $totalPackets',
          //     style: StyleConstants.textDisabled14w400Style,
          //     textAlign: TextAlign.center,
          //   ),
          // SizedBox(height: 8),
          // LinearPercentIndicator(
          //   lineHeight: 8,
          //   percent: progress.clamp(0.0, 1.0),
          //   backgroundColor: ColorConstants.progressTrack,
          //   progressColor: ColorConstants.primary,
          //   barRadius: Radius.circular(4),
          // ),
          SizedBox(height: 12),
          Text(
            _currentBleStateMessage ??
                (status == fw.DownloadStatus.upgrading
                    ? StringConstants.pleaseWaitWhileFirmwareUpgraded
                    : StringConstants.processingLabel),
            style: StyleConstants.textDisabled14w400Style,
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  Widget _buildResult() {
    final isSuccess =
        _controller.downloadingStatus.value == fw.DownloadStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lottie.asset(
          height: 180,
          width: 180,
          isSuccess
              ? AssetConstants.firmwareUpgradeSuccessJson
              : AssetConstants.firmwareUpgradeFailedJson,
          repeat: false,
        ),
        SizedBox(height: 24),
        Text(
          isSuccess
              ? StringConstants.strf910c9ffFailed
              : StringConstants.failedLabel,
          style: StyleConstants.primary24w700Style.copyWith(
            color: isSuccess ? ColorConstants.success : ColorConstants.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        CommonCtaButton(
          onTap: () {
            Navigator.of(context).pop(isSuccess);
            // Reset state
            _controller.downloadingStatus.value = fw.DownloadStatus.downloading;
            _controller.isFileCrcMatched.value = false;
            _controller.selectedFirmwareFile = null;
            _controller.progressbarIndex.value = 0;
            _controller.progressbarCount.value = 0.0;
            _controller.totalPacketLength.value = 0;
          },
          child: Text(
            StringConstants.doneLabel,
            style: StyleConstants.white16w600Style,
          ),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //     // Reset state
        //     _controller.downloadingStatus.value = fw.DownloadStatus.downloading;
        //     _controller.isFileCrcMatched.value = false;
        //     _controller.selectedFirmwareFile = null;
        //     _controller.progressbarIndex.value = 0;
        //     _controller.progressbarCount.value = 0.0;
        //     _controller.totalPacketLength.value = 0;
        //   },
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: ColorConstants.primary,
        //     padding: EdgeInsets.symmetric(vertical: 16),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //   ),
        //   child: Text(
        //     'Done',
        //     style: StyleConstants.white16w600Style,
        //   ),
        // ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final platformFile = PlatformFile(
          name: result.files.single.name,
          path: result.files.single.path,
          size: await file.length(),
          bytes: await file.readAsBytes(),
        );

        _controller.selectFirmwareFile(platformFile);

        setState(() {
          _selectedFile = platformFile;
          _isUploading = false;
          _validationResult = null;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      logger.Logger('Error picking file: $e');
      setState(() {
        _isUploading = false;
        _errorMessage = '${StringConstants.errorSelectingFilePrefix}$e';
      });
    }
  }

  Future<void> _goToFileDetails() async {
    if (_selectedFile == null) return;

    setState(() {
      _currentStep = FirmwareUpgradeStep.fileDetails;
      _isValidating = true;
      _validationResult = null;
      _errorMessage = null;
    });

    final bool bleFile = _selectedFirmwareType == FirmwareType.bleChip;
    final result = _controller.validateSelectedFile(
      requiredProductId:
          bleFile ? null : fw.FirmwareUpgradeService.expectedProductId,
      crcOnly: bleFile,
    );

    setState(() {
      _validationResult = result;
      _isValidating = false;
      if (result == null) {
        _errorMessage = StringConstants.noFileSelectedPleaseUploadAgain;
      } else if (!result.isValid) {
        _errorMessage = result.error ?? StringConstants.crcValidationFailed;
      }
    });
  }

  bool _isVersionMissing(String? value) =>
      value == null || value.trim().isEmpty;

  bool _bleVersionsNotRecovered() =>
      _isVersionMissing(ble.bleHardwareVersion.value) ||
      _isVersionMissing(ble.bleFirmwareVersion.value);

  Future<void> _onValidationContinuePressed() async {
    if (_selectedFirmwareType == FirmwareType.bleChip) {
      await _startUpgrade();
      return;
    }

    if (_bleVersionsNotRecovered()) {
      final shouldProceed = await _confirmAndUpgrade(
        message: StringConstants.deviceHardwareFirmwareCouldNotBeRead,
      );
      if (shouldProceed) {
        await _startUpgrade(
          firmwareVersion: _validationResult?.firmwareVersion,
        );
      }
      return;
    }

    if ((_validationResult?.hardwareVersion == ble.bleHardwareVersion.value) &&
        (_validationResult?.firmwareVersion != ble.bleFirmwareVersion.value)) {
      await _startUpgrade(firmwareVersion: _validationResult?.firmwareVersion);
    } else if (_validationResult?.hardwareVersion !=
        ble.bleHardwareVersion.value) {
      await _showHardwareVersionMismatch();
    } else {
      await _showSameFirmwareVersionPopUp();
    }
  }

  Future<void> _showSameFirmwareVersionPopUp() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.firmwareUpdate,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.firmwareAlreadyUpToDate,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        StringConstants.okay,
                        style: StyleConstants.white16w600Style,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHardwareVersionMismatch() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.firmwareUpdate,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.invalidBINFileHardwareMismatch,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  StringConstants.binFileHardwareVersionDetail(
                    _validationResult?.hardwareVersion,
                    ble.bleHardwareVersion.value,
                  ),
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        StringConstants.cancel,
                        style: StyleConstants.white16w600Style,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmAndUpgrade({String? message}) async {
    final shouldUpgrade = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.firmwareUpdate,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? '',
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.cancel,
                              style: StyleConstants.textGray16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              StringConstants.disabled,
                              style: StyleConstants.white16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldUpgrade ?? false;
  }

  int compareFirmwareVersion({
    required String currentVersion,
    required String newVersion,
  }) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();

      final incoming = newVersion.split('.').map(int.parse).toList();

      final maxLength =
          current.length > incoming.length ? current.length : incoming.length;

      while (current.length < maxLength) {
        current.add(0);
      }

      while (incoming.length < maxLength) {
        incoming.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (incoming[i] > current[i]) {
          return 1; // upgrade
        }

        if (incoming[i] < current[i]) {
          return -1; // downgrade
        }
      }

      return 0; // same
    } catch (e) {
      return -999; // invalid version
    }
  }

  Future<void> _startUpgrade({String? firmwareVersion = ''}) async {
    if (firmwareVersion != null &&
        firmwareVersion.isNotEmpty &&
        !_isVersionMissing(ble.bleFirmwareVersion.value)) {
      final int comparedValue = compareFirmwareVersion(
        currentVersion: ble.bleFirmwareVersion.value,
        newVersion: firmwareVersion,
      );
      final shouldUpgrade = await _confirmAndUpgrade(
        message:
            comparedValue == 1
                ? '${StringConstants.wantUpgrade} $firmwareVersion?'
                : comparedValue == -1
                ? '${StringConstants.wantDowngrade} $firmwareVersion?'
                : StringConstants.sameVersion,
      );

      if (!shouldUpgrade) {
        return;
      }
    }

    _controller.downloadingStatus.value = fw.DownloadStatus.upgrading;

    setState(() {
      _isUpgrading = true;
      _currentStep = FirmwareUpgradeStep.progress;
      _currentBleStateMessage = StringConstants.preparingFirmwareUpgrade;
      _errorMessage = null;
    });

    final prepared = await _controller.preparePackets();
    if (!prepared ||
        _controller.firmwareImage == null ||
        _controller.firmwareImage!.isEmpty) {
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage =
            _controller.validationError ??
            StringConstants.noPacketsToProcessPleaseReUploadTheFile;
      });
      _controller.downloadingStatus.value = fw.DownloadStatus.failed;
      return;
    }

    // Real BLE path: send packets
    try {
      await _sendPacketsOverBle();
      final bool isSuccess =
          _controller.downloadingStatus.value == fw.DownloadStatus.completed;
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage =
            isSuccess ? null : StringConstants.firmwareTransferFailed;
        _currentBleStateMessage = null;
      });
    } catch (e) {
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage = '${StringConstants.errorSendingPacketsPrefix}$e';
        _currentBleStateMessage = null;
      });
      _controller.downloadingStatus.value = fw.DownloadStatus.failed;
    }
  }
}

class _AnimatedGridCard extends StatefulWidget {
  final Widget child;
  final bool highlight;

  const _AnimatedGridCard({required this.child, required this.highlight});

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [widget.child, if (widget.highlight) const _PulseGlow()],
        ),
      ),
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow();

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.25 * (1 - _controller.value),
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
