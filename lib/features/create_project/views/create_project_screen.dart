import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_ui_delegate.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/features/create_project/views/panel_selection_page.dart';
import 'package:techno_switch_solar_app/features/create_project/views/site_creation_page.dart';
import 'package:techno_switch_solar_app/features/dashboard/bindings/project_dashboard_binding.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard.dart';
import 'package:techno_switch_solar_app/features/scan/bindings/scan_binding.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/features/peripherals/general/sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/inputs/sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/l_bus/sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/panel_info/sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/relays/sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/service_due/sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/ext_out/sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/sounders/sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/zones/sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/app_styled_dialogs.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateSiteScreen extends GetView<CreateProjectController> {
  const CreateSiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CreateProjectPageHost(controller: controller);
  }
}

class _CreateProjectPageHost extends StatefulWidget {
  const _CreateProjectPageHost({required this.controller});

  final CreateProjectController controller;

  @override
  State<_CreateProjectPageHost> createState() => _CreateProjectPageHostState();
}

class _CreateProjectPageHostState extends State<_CreateProjectPageHost>
    implements CreateProjectUiDelegate {
  late PageController _pageController;
  final BleLogController _bleController = Get.find<BleLogController>();

  final GlobalKey<GeneralModuleBottomSheetState> _generalSheetKey =
      GlobalKey<GeneralModuleBottomSheetState>();
  final GlobalKey<ServiceDueBottomSheetState> _serviceDueSheetKey =
      GlobalKey<ServiceDueBottomSheetState>();
  final GlobalKey<ZoneBottomSheetState> _zoneSheetKey =
      GlobalKey<ZoneBottomSheetState>();
  final GlobalKey<SounderModeBottomSheetState> _sounderSheetKey =
      GlobalKey<SounderModeBottomSheetState>();
  final GlobalKey<InputModeBottomSheetState> _inputSheetKey =
      GlobalKey<InputModeBottomSheetState>();
  final GlobalKey<RelayModeBottomSheetState> _relaySheetKey =
      GlobalKey<RelayModeBottomSheetState>();
  final GlobalKey<ExtOutBottomSheetState> _extOutSheetKey =
      GlobalKey<ExtOutBottomSheetState>();
  final GlobalKey<LBusBottomSheetState> _lBusSheetKey =
      GlobalKey<LBusBottomSheetState>();
  final GlobalKey<PanelInfoBottomSheetState> _panelInfoSheetKey =
      GlobalKey<PanelInfoBottomSheetState>();

  CreateProjectController get _controller => widget.controller;

  void _noop() {}

  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  Future<void> dismissKeyboardFully() async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<Object>(
      StringConstants.textinputHide,
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Future<void> settleImeBeforeShowingDialog() async {
    await dismissKeyboardFully();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await dismissKeyboardFully();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  @override
  void showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? ColorConstants.primary : ColorConstants.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Future<bool?> showCreateSiteConfirmDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: UiStrings.createSiteDialogTitle,
      message: UiStrings.createSiteConfirmMessage,
      leadingActionLabel: UiStrings.cancelButton,
      trailingActionLabel: UiStrings.createButton,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> showApplyPanelSettingsConfirmDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: UiStrings.applyPanelSettingsDialogTitle,
      message: UiStrings.applyPanelSettingsConfirmMessage,
      leadingActionLabel: UiStrings.cancelButton,
      trailingActionLabel: UiStrings.nextButton,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> showDisconnectConfirmDialog() {
    return showDialog<bool>(
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
                  StringConstants.disconnectDevice,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
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
                              'Disconnect',
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
  }

  @override
  Future<String?> showEnterPanelIdDialog({String? initialValue}) {
    return showAppStyledTextInputDialog(
      context: context,
      title: UiStrings.enterPanelIdDialogTitle,
      message:
          'Enter the panel ID for this site (e.g. AB12). It should match the ID in the panel BLE name TECHNOSWITCH_XXXX when you connect later.',
      hintText: UiStrings.panelIdLabel,
      initialValue: initialValue,
      validator: (value) {
        if (!BleNameUtils.isValidManualPanelId(value)) {
          return StringConstants.enterAValidPanelIDLettersNumbersOr;
        }
        return null;
      },
    );
  }

  @override
  Future<void> showPanelAlreadyAssignedDialog() {
    return showAppStyledOneActionDialog(
      context: context,
      title: StringConstants.panelAlreadyAssigned,
      message: UiStrings.panelIdAlreadyLinkedMessage,
    );
  }

  @override
  Future<String?> showPanelAlreadyOnSiteDialog() {
    return showAppStyledTwoActionDialog<String>(
      context: context,
      title: StringConstants.panelAlreadyOnASite,
      message:
          'This panel is assigned to another site. Move it to the new site you are creating, or skip and return home.',
      leadingActionLabel: 'Skip',
      trailingActionLabel: StringConstants.replace,
      leadingValue: 'skip',
      trailingValue: 'move',
    );
  }

  @override
  Future<bool?> showBulkDownloadDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: StringConstants.downloadPanelConfiguration,
      message:
          'Download the full configuration from the panel now? This matches the dashboard “download all” flow and fills local caches before you edit.',
      leadingActionLabel: 'No',
      trailingActionLabel: StringConstants.yes,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> openScanningScreen(String? expectedPanelType) {
    ScanBinding(
      args: ScanFlowArgs.scanning(
        createProjectExpectedPanelType: expectedPanelType,
      ),
    ).dependencies();
    return Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ScanningScreen()));
  }

  @override
  void popScreen() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void popToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void openProjectDashboard({
    required DiscoveredDevice device,
    required int siteId,
    required String siteName,
  }) {
    ProjectDashboardBinding(
      args: ProjectDashboardArgs(
        panelVersionNo: device.id,
        panelName: device.name,
        selectedDevice: device,
        siteId: siteId,
        siteName: siteName,
      ),
    ).dependencies();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  @override
  void openSiteScreen({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) {
    SiteBinding(
      args: SiteArgs(site: site, siteWithLogCount: siteWithLogCount),
    ).dependencies();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SiteScreen()));
  }

  Future<bool> _commitConfigStepForCurrentPage() async {
    switch (_controller.currentStep) {
      case 3:
        return await _generalSheetKey.currentState?.commitLocal() ?? false;
      case 4:
        return await _serviceDueSheetKey.currentState?.commitLocal() ?? false;
      case 5:
        return await _zoneSheetKey.currentState?.commitLocal() ?? false;
      case 6:
        return await _sounderSheetKey.currentState?.commitLocal() ?? false;
      case 7:
        return await _inputSheetKey.currentState?.commitLocal() ?? false;
      case 8:
        return await _relaySheetKey.currentState?.commitLocal() ?? false;
      case 9:
        return await _extOutSheetKey.currentState?.commitLocal() ?? false;
      case 10:
        return await _lBusSheetKey.currentState?.commitLocal() ?? false;
      default:
        return true;
    }
  }

  Future<bool> _commitPanelInfo() async {
    final panelState = _panelInfoSheetKey.currentState;
    if (panelState == null) return false;
    return panelState.commitLocal();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller.attachUi(this);
    _controller.setupPageNavigation(
      animateNext:
          () => _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
      animatePrevious:
          () => _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
    );
    _controller.commitCurrentStepHandler = _commitConfigStepForCurrentPage;
    _controller.commitPanelInfoHandler = _commitPanelInfo;
  }

  @override
  void dispose() {
    _controller.detachUi();
    _pageController.dispose();
    if (Get.isRegistered<CreateProjectController>()) {
      Get.delete<CreateProjectController>();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    _controller.setCurrentStep(page + 1);
  }

  Widget _embeddedSheetPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CreateProjectController>(
      init: _controller,
      builder:
          (controller) => PopScope(
            canPop: !_bleController.isConnected,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final disconnect = await controller.confirmAndDisconnect();
              if (disconnect && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorConstants.scaffoldGradientTop,
                      ColorConstants.white,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    SvgPicture.asset(AssetConstants.background1),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAppBar(controller),
                          const SizedBox(height: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorConstants.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 22,
                                  bottom: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildPageView(controller)),
                                    const SizedBox(height: 20),
                                    _buildNavigation(controller),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildAppBar(CreateProjectController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.onLeadingBackPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorConstants.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: ColorConstants.textDark,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          StringConstants.createSite,
          style: StyleConstants.textBodyDark20w700Style,
        ),
        const Spacer(),
        Text(StringConstants.step, style: StyleConstants.black16w500Style),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 7,
              right: 6,
              top: 2,
              bottom: 3,
            ),
            child: Text(
              '${controller.currentStep}/${CreateProjectController.totalSteps}',
              style: StyleConstants.white14w700Style,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageView(CreateProjectController controller) {
    final id = controller.wizardDeviceId;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: CreateProjectController.totalSteps,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return const SiteCreationPage();
          case 1:
            return const PanelSelectionPage();
          case 2:
          case 3:
          case 4:
          case 5:
          case 6:
          case 7:
          case 8:
          case 9:
          case 10:
            if (id.isEmpty) {
              return Center(
                child: Text(
                  StringConstants.connectAPanelToConfigurePeripherals,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
              );
            }
            switch (index) {
              case 2:
                return _embeddedSheetPadding(
                  child: GeneralModuleBottomSheet(
                    key: _generalSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.generalModuleRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 3:
                return _embeddedSheetPadding(
                  child: ServiceDueBottomSheet(
                    key: _serviceDueSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.serviceDueRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 4:
                return _embeddedSheetPadding(
                  child: ZoneBottomSheet(
                    key: _zoneSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.zoneRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 5:
                return _embeddedSheetPadding(
                  child: SounderModeBottomSheet(
                    key: _sounderSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.sounderRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 6:
                return _embeddedSheetPadding(
                  child: InputModeBottomSheet(
                    key: _inputSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.inputRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 7:
                return _embeddedSheetPadding(
                  child: RelayModeBottomSheet(
                    key: _relaySheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.relayRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 8:
                return _embeddedSheetPadding(
                  child: ExtOutBottomSheet(
                    key: _extOutSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.extOutRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 9:
                return _embeddedSheetPadding(
                  child: LBusBottomSheet(
                    key: _lBusSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.zoneRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 10:
                return _embeddedSheetPadding(
                  child: PanelInfoBottomSheet(
                    key: _panelInfoSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: controller.panelInfoRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildNavigation(CreateProjectController controller) {
    return Column(
      children: [
        if (controller.currentStep == 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: controller.skipPanelConnectAndContinue,
              child: Text(
                StringConstants.skipConnectionEnterPanelIDManually,
                style: StyleConstants.primary13w600Style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Row(
          children: [
            Opacity(
              opacity: controller.currentStep == 1 ? 0.2 : 1.0,
              child: GestureDetector(
                onTap: controller.goToPreviousStep,
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.buttonSecondaryBackground,
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 34,
                      top: 18,
                      bottom: 18,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: ColorConstants.labelText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          StringConstants.back,
                          style: StyleConstants.labelText14w700Style,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.goToNextStep,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 28,
                    right: 23,
                    top: 18,
                    bottom: 18,
                  ),
                  child: Row(
                    children: [
                      Text(
                        controller.nextButtonLabel,
                        style: StyleConstants.white14w700Style,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: ColorConstants.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
