import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/dashboard/bindings/project_dashboard_binding.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_detail_screen.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteScreen extends GetView<SiteController> {
  const SiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SitePageHost(controller: controller);
  }
}

class _SitePageHost extends StatefulWidget {
  const _SitePageHost({required this.controller});

  final SiteController controller;

  @override
  State<_SitePageHost> createState() => _SitePageHostState();
}

class _SitePageHostState extends State<_SitePageHost> implements SiteUiDelegate {
  SiteController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  Future<bool?> showDeleteSiteDialog({required String siteName}) {
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
                  UiStrings.deleteSiteConfirmMessage(siteName),
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
  }

  @override
  Future<bool?> showDeletePanelDialog({required PanelModel panel}) {
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
  }

  @override
  void showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? ColorConstants.primary,
      ),
    );
  }

  @override
  void popScreen([bool? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Future<void> openSiteDetail({required SiteWithLogCount siteWithLogCount}) async {
    if (!mounted) return;
    SiteDetailBinding(
      args: SiteDetailArgs(siteWithLogCount: siteWithLogCount),
    ).dependencies();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SiteDetailScreen()),
    );
  }

  @override
  void openProjectDashboard({required ProjectDashboardArgs args}) {
    if (!mounted) return;
    ProjectDashboardBinding(args: args).dependencies();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SiteController>()) {
      Get.delete<SiteController>();
    }
    super.dispose();
  }

  Widget _buildLastLogSummary(SiteController controller) {
    final int? lastLogCount = controller.lastRetrievalLogCount;
    final DateTime? lastLogDate =
        controller.lastRetrievalDate ??
        controller.siteWithLogCount.lastLogRetrieved;

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
        const Icon(Icons.timeline, size: 12, color: ColorConstants.success),
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
    return GetBuilder<SiteController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          body: Container(
            height: double.infinity,
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
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      _buildSiteDetails(controller),
                      const SizedBox(height: 20),
                      _buildPanels(controller),
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: controller.popBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.blackMaterial.withOpacity(
                                  0.1,
                                ),
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
                        StringConstants.siteInformation,
                        style: StyleConstants.black20w700Style,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiteDetails(SiteController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.errorTint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                          const SizedBox(width: 8),
                          Text(
                            controller.site.siteName,
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
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.confirmDeleteSite,
                    child: SvgPicture.asset(
                      AssetConstants.deleteIcon,
                      colorFilter: const ColorFilter.mode(
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
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
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
                      const SizedBox(width: 12),
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
                            ).format(controller.siteWithLogCount.site.createdAt),
                            style: StyleConstants.textNeutral12w400Style,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CommonCtaButton(
                    onTap: controller.openSiteDetail,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(AssetConstants.detailsIcon),
                        const SizedBox(width: 8),
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

  Widget _buildPanels(SiteController controller) {
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
          const SizedBox(height: 20),
          _buildPanelList(controller),
        ],
      ),
    );
  }

  Widget _buildPanelList(SiteController controller) {
    if (controller.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: ColorConstants.primary),
        ),
      );
    }

    if (controller.panels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 16),
            Text(
              StringConstants.noPanelsYet,
              style: StyleConstants.textDark16w600Style,
            ),
            const SizedBox(height: 8),
            Text(
              StringConstants.connectToAPanelToAssociateItWithThisSite,
              style: StyleConstants.textGray14w400Style,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final lastLogSummary = _buildLastLogSummary(controller);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.45,
      child: RefreshIndicator(
        color: ColorConstants.primary,
        onRefresh: controller.refreshPanels,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.panels.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final panel = controller.panels[index];
            return _PanelListItemWidget(
              panel: panel,
              lastLogSummary: lastLogSummary,
              onTap: () => controller.openPanelDashboard(panel),
              onDelete: () => controller.confirmDeletePanel(panel),
              isAutomated: index == 0,
            );
          },
        ),
      ),
    );
  }
}

class _PanelListItemWidget extends StatefulWidget {
  const _PanelListItemWidget({
    required this.panel,
    required this.lastLogSummary,
    required this.onTap,
    required this.onDelete,
    required this.isAutomated,
  });

  final PanelModel panel;
  final Widget lastLogSummary;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isAutomated;

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
                  const SizedBox(width: 14.31),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
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
