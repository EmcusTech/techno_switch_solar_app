import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/sites/site_detail_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteScreen extends StatefulWidget {
  final SiteModel site;
  final SiteWithLogCount siteWithLogCount;
  const SiteScreen({
    super.key,
    required this.site,
    required this.siteWithLogCount,
  });

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  final SiteService _siteService = SiteService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  final PanelService _panelService = PanelService();
  List<PanelModel> _panels = [];
  bool _isLoading = true;
  bool _isDeletingSite = false;
  int? _lastRetrievalLogCount;
  DateTime? _lastRetrievalDate;

  @override
  void initState() {
    super.initState();
    _loadPanels();
    _loadLatestRetrievalInfo();
  }

  Future<void> _loadPanels() async {
    try {
      final panels = await _siteService.getSitePanels(widget.site.id!);

      setState(() {
        _panels = panels;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLatestRetrievalInfo() async {
    try {
      final latest = await _logRetrievalService.getMostRecentLogRetrieval(
        widget.site.id!,
      );
      if (!mounted) return;
      setState(() {
        _lastRetrievalLogCount = latest?.logCount;
        _lastRetrievalDate = latest?.retrievalDate;
      });
    } catch (error) {
      Logger('Error loading latest retrieval info: $error');
    }
  }

  Future<void> _refreshSites() async {
    setState(() {
      _isLoading = true;
    });
    await _loadPanels();
  }

  Future<void> _confirmDeleteSite() async {
    if (widget.site.id == null || _isDeletingSite) return;

    final shouldDelete = await showDialog<bool>(
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
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  StringConstants.deleteSite,
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  UiStrings.deleteSiteConfirmMessage(widget.site.siteName),
                  style: StyleConstants.textMuted14w400Style,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(
                            color: ColorConstants.borderLight,
                            width: 1,
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          StringConstants.cancel,
                          style: StyleConstants.textGray14w500Style,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          StringConstants.delete,
                          style: StyleConstants.white14w600Style,
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

    if (shouldDelete == true) {
      await _deleteSite();
    }
  }

  Future<void> _deleteSite() async {
    setState(() {
      _isDeletingSite = true;
    });

    try {
      final deleted = await _siteService.deleteSite(widget.site.id!);
      if (!mounted) return;

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              StringConstants.siteDeletedMessage(widget.site.siteName),
            ),
            backgroundColor: ColorConstants.primary,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(StringConstants.unableToDeleteSite),
            backgroundColor: ColorConstants.primary,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${StringConstants.errorDeletingSitePrefix}$error'),
          backgroundColor: ColorConstants.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingSite = false;
        });
      }
    }
  }

  Future<void> _confirmDeletePanel(PanelModel panel) async {
    final shouldDelete = await showDialog<bool>(
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
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  StringConstants.removePanel,
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  StringConstants.removePanelConfirmationMessage(
                    panel.panelName,
                    panel.panelId,
                  ),
                  style: StyleConstants.textMuted14w400Style,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(
                            color: ColorConstants.borderLight,
                            width: 1,
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          StringConstants.cancel,
                          style: StyleConstants.textGray14w500Style,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          StringConstants.remove,
                          style: StyleConstants.white14w600Style,
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

    if (shouldDelete == true) {
      await _deletePanel(panel);
    }
  }

  Future<void> _deletePanel(PanelModel panel) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deleted = await _panelService.deletePanel(panel.panelId);
      if (!mounted) return;

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(StringConstants.panelDeletedMessage(panel.panelName)),
            backgroundColor: ColorConstants.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(StringConstants.unableToDeletePanel),
            backgroundColor: ColorConstants.primary,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${StringConstants.errorDeletingPanelPrefix}$error'),
          backgroundColor: ColorConstants.primary,
        ),
      );
    } finally {
      if (mounted) {
        await _loadPanels();
      }
    }
  }

  Widget _buildLastLogSummary() {
    final int? lastLogCount = _lastRetrievalLogCount;
    final DateTime? lastLogDate =
        _lastRetrievalDate ?? widget.siteWithLogCount.lastLogRetrieved;

    if ((lastLogCount ?? 0) <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          StringConstants.noLogsYet,
          style: StyleConstants.textMuted11w400Style,
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.timeline, size: 12, color: ColorConstants.success),
        const SizedBox(width: 4),
        Text(
          '$lastLogCount log${lastLogCount == 1 ? '' : 's'}',
          style: StyleConstants.success11w500Style,
        ),
        if (lastLogDate != null) ...[
          const SizedBox(width: 8),
          Text(
            'Last: ${DateFormat('MMM d').format(lastLogDate)}',
            style: StyleConstants.textMuted11w400Style,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(children: [_buildHeader(context)]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset(AssetConstants.background1),
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              _buildSiteDetails(),
              SizedBox(height: 20),
              _buildPanels(),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
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
              SizedBox(width: 12),
              Text(
                StringConstants.siteInformation,
                style: StyleConstants.black20w700Style,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSiteDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.errorTint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 15,
                bottom: 15,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(AssetConstants.locationIcon),
                          SizedBox(width: 8),
                          Text(
                            widget.site.siteName,
                            style: StyleConstants.textBodyDark20boldStyle,
                          ),
                        ],
                      ),
                      Text(
                        StringConstants.siteInformation,
                        style: StyleConstants.textNeutral12w400Style,
                      ),
                    ],
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      _confirmDeleteSite();
                    },
                    child: SvgPicture.asset(
                      AssetConstants.deleteIcon,
                      colorFilter: ColorFilter.mode(
                        ColorConstants.errorBright,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(AssetConstants.siteCalenderIcon),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringConstants.created,
                            style: StyleConstants.textNeutral12w400Style,
                          ),
                          Text(
                            DateFormat(
                              'MMM d, y',
                            ).format(widget.siteWithLogCount.site.createdAt),
                            style: StyleConstants.textNeutral12w400Style,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  CommonCtaButton(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => SiteDetailScreen(
                                siteWithLogCount: widget.siteWithLogCount,
                              ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(AssetConstants.detailsIcon),
                        SizedBox(width: 8),
                        Text(
                          StringConstants.viewSiteDetails,
                          style: StyleConstants.white14w500Style,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StringConstants.panels,
            style: StyleConstants.textDark14w500Style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20),
          _buildPanelItem(),
        ],
      ),
    );
  }

  Widget _buildPanelItem() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: ColorConstants.primary),
        ),
      );
    }

    if (_panels.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          border: Border.all(
            color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              AssetConstants.newProjectIcon,
              height: 48,
              width: 48,
              colorFilter: ColorFilter.mode(
                ColorConstants.primary.withValues(alpha: 0.5),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 16),
            Text(
              StringConstants.noPanelsYet,
              style: StyleConstants.textDark16w600Style,
            ),
            SizedBox(height: 8),
            Text(
              StringConstants.connectToAPanelToAssociateItWithThisSite,
              style: StyleConstants.textGray14w400Style,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.45,
      child: RefreshIndicator(
        color: ColorConstants.primary,
        onRefresh: _refreshSites,
        child: ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _panels.length,
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final panel = _panels[index];
            final panelName = panel.panelName;

            void onTap() {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ProjectDashboardScreen(
                        selectedDevice: DiscoveredDevice(
                          name: panelName,
                          id: panel.panelId,
                          rssi: 0,
                          serviceData: {},
                          manufacturerData: Uint8List(0),
                          serviceUuids: [],
                        ),
                        panelName: panelName,
                        panelVersionNo: panel.deviceDisplayInfo,
                        siteId: widget.site.id!,
                        siteName: widget.site.siteName,
                      ),
                ),
              );
            }

            return _PanelListItemWidget(
              panel: panel,
              lastLogSummary: _buildLastLogSummary(),
              onTap: onTap,
              onDelete: () => _confirmDeletePanel(panel),
              isAutomated: index == 0,
            );
          },
        ),
      ),
    );
  }
}

class _PanelListItemWidget extends StatefulWidget {
  final PanelModel panel;
  final Widget lastLogSummary;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isAutomated;

  const _PanelListItemWidget({
    required this.panel,
    required this.lastLogSummary,
    required this.onTap,
    required this.onDelete,
    required this.isAutomated,
  });

  @override
  State<_PanelListItemWidget> createState() => _PanelListItemWidgetState();
}

class _PanelListItemWidgetState extends State<_PanelListItemWidget>
    with SingleTickerProviderStateMixin {
  SlidableController? _slidableController;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    if (widget.isAutomated) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _slidableController == null) return;
        await _slidableController!.openEndActionPane();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _slidableController?.close();
        }
      });
    }
  }

  @override
  void dispose() {
    _slidableController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    return GestureDetector(
      onLongPress: () {
        _slidableController?.openEndActionPane();
      },
      child: Slidable(
        controller: _slidableController,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              onPressed: (BuildContext context) {
                widget.onDelete();
              },
              backgroundColor: const Color.fromARGB(255, 245, 63, 57),
              foregroundColor: ColorConstants.white,
              icon: CupertinoIcons.delete,
              label: StringConstants.delete,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: ColorConstants.white,
              border: Border.all(
                color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Image.asset(
                    AssetConstants.panelIconImage,
                    height: 62,
                    width: 62,
                  ),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          panel.deviceType == 'bluetooth'
                              ? BleNameUtils.getDisplayPrefixFromBleName(
                                panel.panelName,
                              )
                              : panel.panelName,
                          style: StyleConstants.textDark14w700Style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          panel.deviceType == 'bluetooth'
                              ? BleNameUtils.getDisplayIdFromBleName(
                                panel.panelName,
                              )
                              : panel.panelId,
                          style: StyleConstants.textMuted12w400Style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // widget.lastLogSummary,
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ColorConstants.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
