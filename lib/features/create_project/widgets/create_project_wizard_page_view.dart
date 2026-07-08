import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/panel_selection_form.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/site_creation_form.dart';
import 'package:techno_switch_solar_app/features/peripherals/ext_out/sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/general/sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/inputs/sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/l_bus/sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/panel_info/sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/relays/sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/service_due/sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/sounders/sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/zones/sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateProjectWizardPageView extends StatefulWidget {
  const CreateProjectWizardPageView({
    super.key,
    required this.controller,
    required this.pageController,
    required this.onPageChanged,
  });

  final CreateProjectController controller;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  CreateProjectWizardPageViewState createState() =>
      CreateProjectWizardPageViewState();
}

class CreateProjectWizardPageViewState extends State<CreateProjectWizardPageView> {
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

  static void _noop() {}

  Future<bool> commitCurrentStep(int currentStep) async {
    switch (currentStep) {
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

  Future<bool> commitPanelInfo() async {
    final panelState = _panelInfoSheetKey.currentState;
    if (panelState == null) return false;
    return panelState.commitLocal();
  }

  Widget _embeddedSheetPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final id = controller.wizardDeviceId;

    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: widget.onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: CreateProjectController.totalSteps,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return SiteCreationForm(model: controller.siteCreationPageModel);
          case 1:
            return PanelSelectionForm(model: controller.panelSelectionPageModel);
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
                    projectPanelName: controller.panelNameController.text,
                    preferFactoryDefaults: !controller.bulkDownloadCompleted,
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
}
