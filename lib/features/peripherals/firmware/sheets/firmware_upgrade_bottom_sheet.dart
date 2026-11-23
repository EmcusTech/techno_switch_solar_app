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
import 'package:Technoswitch/ble/demo/demo_ble.dart';
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
import 'package:Technoswitch/widgets/dialogs/app_styled_dialogs.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';

enum FirmwareType { mainPanel, bleChip }

enum FirmwareUpgradeStep {
  essentialSteps,
  connectDevice,
  chooseType,
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
  bool _isConfirmingComplete = false;
  bool _upgradePromptShown = false;
  String? _errorMessage;
  String? _currentBleStateMessage;
  fw.FirmwareValidationResult? _validationResult;

  static const double _firmwareDesignHeight = 700;

  double _firmwareHeightScale(BoxConstraints constraints) {
    final double height = constraints.maxHeight;
    if (!height.isFinite || height <= 0) return 1;
    return (height / _firmwareDesignHeight).clamp(0.7, 1.2);
  }

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
          if (!_upgradePromptShown) {
            _upgradePromptShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _onResultDone(true);
            });
          }
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
    void onProgress(int sent, int total) {
      _controller.progressbarIndex.value = sent;
      _controller.totalPacketLength.value = total;
      _controller.progressbarCount.value = total == 0 ? 0 : sent / total;
    }

    if (DemoBle.enabled) {
      await DemoBle.runFirmwareUpgrade(
        process: manager.bleProcess,
        onProgress: onProgress,
      );
      final String upgradedVersion = _validationResult?.firmwareVersion ?? '';
      if (upgradedVersion.isNotEmpty) {
        ble.bleFirmwareVersion.value = upgradedVersion;
      }
      final String upgradedHardware = _validationResult?.hardwareVersion ?? '';
      if (_selectedFirmwareType != FirmwareType.bleChip &&
          upgradedHardware.isNotEmpty) {
        ble.bleHardwareVersion.value = upgradedHardware;
      }
    } else {
      await manager.bleProcess.beginFirmwareUpgrade(
        image,
        onProgress: onProgress,
      );
    }
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
        _currentStep == FirmwareUpgradeStep.progress ||
        _isUpgrading ||
        _isConfirmingComplete;
    final bool showPhoneChrome =
        !PeripheralSheetChrome.flat && !upgradeInProgress;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PeripheralSheetDragHandle(),
        // _buildHeader(showClose: !upgradeInProgress),
        // Spacer(),
        Expanded(child: _buildStepContent()),
        SizedBox(height: 12),
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
    return Text(
      StringConstants.firmwareUpgrade,
      style: StyleConstants.textDark20w700Style,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case FirmwareUpgradeStep.essentialSteps:
        return _buildEssentialSteps();
      case FirmwareUpgradeStep.chooseType:
        return _buildChooseType();
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final double scale = _firmwareHeightScale(constraints);
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16 * scale),
                Align(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 250 * scale,
                      maxHeight: 250 * scale,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            AssetConstants.firmwareUpgradeIcon,
                            fit: BoxFit.contain,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              StringConstants.firmwareUpgrade,
                              style: StyleConstants.primary20w700Style,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringConstants.essentialStepsBeforeFirmwareUpgrade,
                      style: StyleConstants.black18w700Style,
                    ),
                    SizedBox(height: 24 * scale),
                    ...steps.map(
                      (step) => Padding(
                        padding: EdgeInsets.only(bottom: 16 * scale),
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
                  ],
                ),
                CommonCtaButton(
                  onTap: () {
                    setState(() {
                      _currentStep = FirmwareUpgradeStep.chooseType;
                    });
                  },
                  child: Text(
                    StringConstants.disabled,
                    style: StyleConstants.white22w600Style,
                  ),
                ),
              ],
            );
          },
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
    final bool canUpload = _selectedFirmwareType != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = _firmwareHeightScale(constraints);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              StringConstants.firmwareUpgrade,
              style: StyleConstants.primary18w700Style,
            ),
            Text(
              StringConstants.chooseFirmwareType,
              style: StyleConstants.black18w700Style,
            ),
            SizedBox(height: 24 * scale),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFirmwareTypeOption(
                    title: StringConstants.mainPanelFirmware,
                    description:
                        StringConstants.upgradeMainPanelFirmwareDescription,
                    iconAsset: AssetConstants.mainPanelFirmwareIcon,
                    type: FirmwareType.mainPanel,
                    enabled: false,
                    scale: scale,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFirmwareTypeOption(
                    title: StringConstants.bleChipFirmware,
                    description:
                        StringConstants.upgradeBleChipFirmwareDescription,
                    iconAsset: AssetConstants.bleChipFirmwareIcon,
                    type: FirmwareType.bleChip,
                    scale: scale,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 18 * scale),
                  Text(
                    StringConstants.uploadFirmwareFile,
                    style: StyleConstants.black18w700Style,
                  ),
                  SizedBox(height: 12 * scale),
                  Expanded(
                    child: GestureDetector(
                      onTap: canUpload && !_isUploading ? _pickFile : null,
                      child: Opacity(
                        opacity: canUpload ? 1 : 0.45,
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color:
                                canUpload
                                    ? ColorConstants.primary.withOpacity(0.3)
                                    : ColorConstants.iconDisabled,
                            radius: Radius.circular(12),
                            dashPattern: [5, 5],
                            strokeWidth: 2,
                            padding: EdgeInsets.all(0),
                            stackFit: StackFit.expand,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            padding: EdgeInsets.all(32 * scale),
                            decoration: BoxDecoration(
                              color: ColorConstants.scaffoldGradientTop,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  AssetConstants.binFolderIcon,
                                  width: 48 * scale,
                                  height: 48 * scale,
                                ),
                                SizedBox(height: 16 * scale),
                                Text(
                                  _selectedFile == null
                                      ? StringConstants.tapToSelectFirmwareFile
                                      : _selectedFile!.name,
                                  style: StyleConstants.primary18w700Style,
                                  textAlign: TextAlign.center,
                                ),
                                if (_selectedFile != null) ...[
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    style: StyleConstants.primary14w500Style,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  LinearProgressIndicator(
                    backgroundColor:
                        _isUploading
                            ? ColorConstants.progressTrack
                            : Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isUploading
                          ? ColorConstants.primary
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24 * scale),
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
                        _selectedFirmwareType == null ||
                                _selectedFile == null ||
                                _isUploading
                            ? null
                            : _goToFileDetails,
                    isDisabled:
                        _selectedFirmwareType == null ||
                        _selectedFile == null ||
                        _isUploading,
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
      },
    );
  }

  Widget _buildFirmwareTypeOption({
    required String title,
    required String description,
    required String iconAsset,
    required FirmwareType type,
    bool enabled = true,
    double scale = 1,
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24 * scale),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFFE8E9) : Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(color: ColorConstants.primary, width: 1)
                  : null,
          boxShadow:
              isSelected
                  ? null
                  : const [
                    BoxShadow(
                      offset: Offset(0, 13),
                      blurRadius: 4,
                      color: Color.fromRGBO(0, 0, 0, 0),
                    ),
                    BoxShadow(
                      offset: Offset(0, 8),
                      blurRadius: 3,
                      color: Color.fromRGBO(0, 0, 0, 0.01),
                    ),
                    BoxShadow(
                      offset: Offset(0, 5),
                      blurRadius: 3,
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                    ),
                    BoxShadow(
                      offset: Offset(0, 2),
                      blurRadius: 2,
                      color: Color.fromRGBO(0, 0, 0, 0.09),
                    ),
                    BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 1,
                      color: Color.fromRGBO(0, 0, 0, 0.10),
                    ),
                  ],
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 72 * scale,
              height: 72 * scale,
              color:
                  enabled
                      ? ColorConstants.primary
                      : ColorConstants.textDisabled,
            ),
            SizedBox(height: 16 * scale),
            Text(
              title,
              textAlign: TextAlign.center,
              style: StyleConstants.textDark16w700Style,
            ),
            SizedBox(height: 6 * scale),
            Text(
              description,
              textAlign: TextAlign.center,
              style: StyleConstants.textDisabled14w400Style.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileDetails() {
    if (_selectedFile == null) return SizedBox();

    final result = _validationResult;
    final isCrcMatched = _controller.isFileCrcMatched.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = _firmwareHeightScale(constraints);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 140 * scale,
                  maxHeight: 140 * scale,
                ),
                child: Image.asset(
                  AssetConstants.firmwareDetailsIcon,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Text(
              StringConstants.firmwareDetails,
              style: StyleConstants.primary18w700Style,
            ),
            SizedBox(height: 24 * scale),
            _buildDetailRow(StringConstants.fileName, _selectedFile!.name),
            // SizedBox(height: 12),
            _buildDetailRow(
              StringConstants.fileSize,
              '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
            ),
            // SizedBox(height: 12),
            _buildDetailRow(
              StringConstants.firmwareTypeLabel,
              _selectedFirmwareType == FirmwareType.mainPanel
                  ? StringConstants.mainPanelFirmware
                  : StringConstants.bleChipFirmware,
            ),
            if (result != null) ...[
              // SizedBox(height: 12),
              _buildDetailRow(
                StringConstants.firmwareVersion2,
                _emptyToDash(result.firmwareVersion),
              ),
              // SizedBox(height: 12),
              _buildDetailRow(
                StringConstants.hardwareVersion2,
                _emptyToDash(result.hardwareVersion),
              ),
              // SizedBox(height: 12),
              _buildDetailRow(
                StringConstants.buildDate,
                _emptyToDash(result.date),
              ),
              // SizedBox(height: 12),
              _buildDetailRow(
                StringConstants.productId,
                _emptyToDash(result.productId),
              ),
            ],
            _buildDetailRow(
              isLast: true,
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
              valueIconAsset:
                  _isValidating
                      ? null
                      : isCrcMatched
                      ? AssetConstants.validBinFileIcon
                      : AssetConstants.invalidBinFileIcon,
            ),
            if (_isValidating) ...[
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator()),
            ],
            // if (!_isValidating && !isCrcMatched)
            //   Container(
            //     margin: EdgeInsets.only(top: 24),
            //     padding: EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: ColorConstants.primary.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(Icons.warning, color: ColorConstants.primary),
            //         SizedBox(width: 12),
            //         Expanded(
            //           child: Text(
            //             _validationResult?.error ??
            //                 StringConstants.fileCrcValidationFailedSelectValidFile,
            //             style: StyleConstants.primary14w400Style,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            Spacer(),
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
                                _currentStep = FirmwareUpgradeStep.chooseType;
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
                //                 _currentStep = FirmwareUpgradeStep.chooseType;
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
      },
    );
  }

  String _emptyToDash(String s) => s.isEmpty ? '-' : s;

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    String? valueIconAsset,
    bool? isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: StyleConstants.textDisabled14w500Style.copyWith(
                  color: ColorConstants.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (valueIconAsset != null) ...[
                      SvgPicture.asset(valueIconAsset, width: 16, height: 16),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
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
                ),
              ),
            ],
          ),
        ),
        if (!isLast!) Divider(color: Color(0xFFBDBDBD)),
      ],
    );
  }

  Widget _buildProgress() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = _firmwareHeightScale(constraints);
        final double availableRadius = (constraints.maxHeight - 80) / 2;
        final double radius =
            availableRadius < 80
                ? availableRadius.clamp(48, 80).toDouble()
                : (200 * scale).clamp(80, availableRadius).toDouble();
        return Obx(() {
          final progress = _controller.progressbarCount.value;
          final status = _controller.downloadingStatus.value;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child:
                    (progress * 100).toStringAsFixed(1) == '0.0'
                        ? Lottie.asset(
                          AssetConstants.bleConnectingJson,
                          height: radius * 2,
                          width: radius * 2,
                        )
                        : CircularPercentIndicator(
                          radius: radius,
                          lineWidth: 8,
                          percent: progress.clamp(0.0, 1.0),
                          center: Lottie.asset(
                            AssetConstants.firmwareUpgradeJson,
                          ),
                          progressColor: ColorConstants.primary,
                          backgroundColor: ColorConstants.progressTrack,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
              ),
              SizedBox(height: 12 * scale),
              Visibility(
                visible: !((progress * 100).toStringAsFixed(1) == '0.0'),
                child: Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: StyleConstants.primary24w700Style,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
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
      },
    );
  }

  Future<void> _onResultDone(bool isSuccess) async {
    if (isSuccess) {
      final bool? startUpgrade = await showAppStyledTwoActionDialog<bool>(
        context: context,
        title: StringConstants.firmwareUpgrade,
        message: StringConstants.doYouWantToUpdateTheFirmware,
        leadingActionLabel: StringConstants.cancel,
        trailingActionLabel: StringConstants.update,
        leadingValue: false,
        trailingValue: true,
        icon: Icons.system_update_alt,
        maxWidth: 420,
      );
      if (startUpgrade != true || !mounted) return;

      if (!DemoBle.enabled) {
        setState(() => _isConfirmingComplete = true);
        final manager =
            Get.isRegistered<BleLogController>()
                ? Get.find<BleLogController>().bleManager
                : ble;
        try {
          await manager.bleProcess.confirmFirmwareUpgradeComplete();
        } catch (error) {
          if (!mounted) return;
          setState(() => _isConfirmingComplete = false);
          showAppNotice(context, message: '$error');
          return;
        }
        if (!mounted) return;
      }
    }
    _resetFirmwareFlow();
  }

  void _resetFirmwareFlow() {
    _controller.resetState();
    _controller.selectedFirmwareFile = null;
    setState(() {
      _currentStep = FirmwareUpgradeStep.essentialSteps;
      _selectedFirmwareType = null;
      _selectedFile = null;
      _isUploading = false;
      _isUpgrading = false;
      _isValidating = false;
      _isConfirmingComplete = false;
      _upgradePromptShown = false;
      _errorMessage = null;
      _currentBleStateMessage = null;
      _validationResult = null;
    });
  }

  Widget _buildResult() {
    final isSuccess =
        _controller.downloadingStatus.value == fw.DownloadStatus.completed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = _firmwareHeightScale(constraints);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 200 * scale,
                        maxHeight: 200 * scale,
                      ),
                      child: Lottie.asset(
                        isSuccess
                            ? AssetConstants.firmwareUpgradeSuccessJson
                            : AssetConstants.firmwareUpgradeFailedJson,
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * scale),
                  Text(
                    isSuccess
                        ? StringConstants.strf910c9ffFailed
                        : StringConstants.failedLabel,
                    style: StyleConstants.primary24w700Style.copyWith(
                      color:
                          isSuccess
                              ? ColorConstants.success
                              : ColorConstants.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 82),
                    child: Text(
                      "Your firmware has been successfully uploaded.\nPlease click Done for upgrade to initiate in panel.",
                      style: StyleConstants.textDisabled14w400Style,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * scale),
            CommonCtaButton(
              onTap: _isConfirmingComplete ? null : _resetFirmwareFlow,
              isDisabled: _isConfirmingComplete,
              child: Text(
                StringConstants.doneLabel,
                style: StyleConstants.white16w600Style,
              ),
            ),
          ],
        );
      },
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
        lockParentWindow: true,
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

    logger.Logger(
      'Firmware CRC '
      'calculated=0x${result?.calculatedHex ?? '-'} '
      'expected=0x${result?.expectedHex ?? '-'} '
      'status=${result?.isValid == true ? 'valid' : 'invalid'}',
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
    if (DemoBle.enabled && _selectedFirmwareType != FirmwareType.bleChip) {
      final String fileHardware = _validationResult?.hardwareVersion ?? '';
      if (_isVersionMissing(ble.bleHardwareVersion.value) &&
          fileHardware.isNotEmpty) {
        ble.bleHardwareVersion.value = fileHardware;
      }
      if (_isVersionMissing(ble.bleFirmwareVersion.value)) {
        ble.bleFirmwareVersion.value = DemoBle.firmwareVersion;
      }
    }

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
