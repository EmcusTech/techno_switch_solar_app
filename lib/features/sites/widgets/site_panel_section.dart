import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SitePanelEmptyState extends StatelessWidget {
  const SitePanelEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class SitePanelListItem extends StatefulWidget {
  const SitePanelListItem({
    super.key,
    required this.panel,
    required this.onTap,
    required this.onDelete,
    required this.showSwipeHint,
  });

  final PanelModel panel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showSwipeHint;

  @override
  State<SitePanelListItem> createState() => _SitePanelListItemState();
}

class _SitePanelListItemState extends State<SitePanelListItem>
    with SingleTickerProviderStateMixin {
  SlidableController? _slidableController;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    if (widget.showSwipeHint) {
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
              onPressed: (_) => widget.onDelete(),
              backgroundColor: ColorConstants.errorBright,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

class SitePanelSection extends StatelessWidget {
  const SitePanelSection({super.key, required this.controller});

  final SiteController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
          if (controller.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: ColorConstants.primary),
              ),
            )
          else if (controller.panels.isEmpty)
            const SitePanelEmptyState()
          else
            ...List.generate(controller.panels.length, (index) {
              final panel = controller.panels[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < controller.panels.length - 1 ? 10 : 0,
                ),
                child: SitePanelListItem(
                  panel: panel,
                  showSwipeHint: index == 0,
                  onTap: () => controller.openPanelDashboard(panel),
                  onDelete: () => controller.confirmDeletePanel(panel),
                ),
              );
            }),
        ],
      ),
    );
  }
}
