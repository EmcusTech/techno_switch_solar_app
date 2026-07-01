import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import '../../models/log_model.dart';
import '../../utils/site_service.dart';
import '../../utils/panel_service.dart';
import '../create_project/site_creation_page.dart';
import '../home_screen.dart';
import 'site_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SimpleSiteCreationScreen extends StatefulWidget {
  final List<LogModel> retrievedLogs;
  final String? panelName;
  final String? panelVersionNo;
  final String? panelId;
  final bool returnCreatedSiteId;

  const SimpleSiteCreationScreen({
    super.key,
    required this.retrievedLogs,
    this.panelName,
    this.panelVersionNo,
    this.panelId,
    this.returnCreatedSiteId = false,
  });

  @override
  State<SimpleSiteCreationScreen> createState() =>
      _SimpleSiteCreationScreenState();
}

class _SimpleSiteCreationScreenState extends State<SimpleSiteCreationScreen> {
  final BleManager ble = Get.find<BleManager>();
  late TextEditingController _siteNameController;
  late TextEditingController _installerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _saqccRegNumberController;
  late TextEditingController _buildingNameController;
  late TextEditingController _installerContactNumberController;
  late TextEditingController _installerEmailController;
  late TextEditingController _siteDescriptionController;

  final SiteService _siteService = SiteService();
  final PanelService _panelService = PanelService();
  bool _isLoading = false;
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController();
    _installerNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _saqccRegNumberController = TextEditingController();
    _buildingNameController = TextEditingController();
    _installerContactNumberController = TextEditingController();
    _installerEmailController = TextEditingController();
    _siteDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _installerNameController.dispose();
    _companyNameController.dispose();
    _saqccRegNumberController.dispose();
    _buildingNameController.dispose();
    _installerContactNumberController.dispose();
    _installerEmailController.dispose();
    _siteDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createSiteAndSaveLogs() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _validationErrors.clear();
    });

    try {
      final panelIdToCheck = widget.panelId;

      if (panelIdToCheck != null) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToCheck,
        );

        if (existingPanel != null && existingPanel.siteId != null) {
          final existingSite = await _siteService.getSiteById(
            existingPanel.siteId!,
          );
          if (existingSite != null) {
            await _siteService.storeLogs(
              widget.retrievedLogs,
              siteId: existingSite.id!,
            );
            final allSitesWithLogCount =
                await _siteService.getSitesWithLogCount();
            final updatedSiteWithLogCount = allSitesWithLogCount.firstWhere(
              (siteWithLogCount) => siteWithLogCount.site.id == existingSite.id,
              orElse:
                  () => SiteWithLogCount(
                    site: existingSite,
                    logCount: widget.retrievedLogs.length,
                    lastLogRetrieved: DateTime.now(),
                  ),
            );

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder:
                    (context) => SiteScreen(
                      site: existingSite,
                      siteWithLogCount: updatedSiteWithLogCount,
                    ),
              ),
              (route) => false,
            );
            return;
          }
        } else {
          Logger(
            'DEBUG: SimpleSiteCreation - Panel exists but no siteId, or panel not found',
          );
        }
      } else {
        Logger('DEBUG: SimpleSiteCreation - No panel ID to check');
      }

      final errors = _siteService.validateSiteData(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      if (errors.isNotEmpty) {
        setState(() {
          _validationErrors = errors;
          _isLoading = false;
        });

        return;
      }

      final site = await _siteService.createSite(
        siteName: _siteNameController.text,
        installerName: _installerNameController.text,
        companyName: _companyNameController.text,
        saqccRegNumber: _saqccRegNumberController.text,
        buildingName: _buildingNameController.text,
        installerContactNumber: _installerContactNumberController.text,
        installerEmail: _installerEmailController.text,
        siteDescription: _siteDescriptionController.text,
      );

      await _siteService.storeLogs(widget.retrievedLogs, siteId: site.id!);

      final panelIdToAssociate = widget.panelId;

      if (panelIdToAssociate != null) {
        try {
          final existingPanel = await _siteService.getPanelByPanelId(
            panelIdToAssociate,
          );
          if (existingPanel != null) {
            Logger(
              'DEBUG: Existing panel details: ${existingPanel.toString()}',
            );
          } else {
            Logger(
              'DEBUG: Panel does not exist - will be created during assignment',
            );
          }

          await _siteService.associateCurrentPanelWithSite(
            panelIdToAssociate,
            site.id!,
            panelName: widget.panelName,
          );
        } catch (_) {}
      } else {
        Logger(
          'DEBUG: No panel ID found - panel was not registered during connection or not passed to constructor',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Site created successfully! ${widget.retrievedLogs.length} logs saved.',
          ),
          backgroundColor: ColorConstants.success,
        ),
      );

      if (widget.returnCreatedSiteId) {
        Navigator.of(context).pop(site.id);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: SvgPicture.asset(AssetConstants.arrowBackIcon),
                        ),
                        SizedBox(width: 17),
                        Expanded(
                          child: Text(
                            StringConstants.createSite,
                            style: StyleConstants.textBodyDark20w700Style,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20),
                              Expanded(
                                child: SiteCreationPage(
                                  siteNameController: _siteNameController,
                                  installerNameController:
                                      _installerNameController,
                                  companyNameController: _companyNameController,
                                  saqccRegNumberController:
                                      _saqccRegNumberController,
                                  buildingNameController:
                                      _buildingNameController,
                                  installerContactNumberController:
                                      _installerContactNumberController,
                                  installerEmailController:
                                      _installerEmailController,
                                  siteDescriptionController:
                                      _siteDescriptionController,
                                  validationErrors: _validationErrors,
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          _isLoading
                                              ? null
                                              : () {
                                                if (widget
                                                    .returnCreatedSiteId) {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(null);
                                                  ble.disconnectConnectedDevice();
                                                } else {
                                                  Navigator.of(
                                                    context,
                                                  ).pushAndRemoveUntil(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              HomeScreen(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                }
                                              },
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              _isLoading
                                                  ? ColorConstants
                                                      .buttonSecondaryBackground
                                                      .withValues(alpha: 0.5)
                                                  : ColorConstants
                                                      .buttonSecondaryBackground,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            StringConstants.cancel,
                                            style: StyleConstants
                                                .labelText14w700Style
                                                .copyWith(
                                                  color:
                                                      _isLoading
                                                          ? ColorConstants
                                                              .labelText
                                                              .withValues(
                                                                alpha: 0.5,
                                                              )
                                                          : ColorConstants
                                                              .labelText,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          _isLoading
                                              ? null
                                              : _createSiteAndSaveLogs,
                                      child: Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color:
                                              _isLoading
                                                  ? ColorConstants.primary
                                                      .withValues(alpha: 0.5)
                                                  : ColorConstants.primary,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        child: Center(
                                          child:
                                              _isLoading
                                                  ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            ColorConstants
                                                                .white,
                                                          ),
                                                    ),
                                                  )
                                                  : Text(
                                                    StringConstants.createSite,
                                                    style:
                                                        StyleConstants
                                                            .white14w700Style,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
