import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/features/create_project/widgets/site_creation_form.dart';
import 'package:Technoswitch/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:get/get.dart';

class SimpleSiteCreationAppBar extends StatelessWidget {
  const SimpleSiteCreationAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: SvgPicture.asset(AssetConstants.arrowBackIcon),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Text(
            StringConstants.createSite,
            style: StyleConstants.textBodyDark20w700Style,
          ),
        ),
      ],
    );
  }
}

class SimpleSiteCreationActions extends StatelessWidget {
  const SimpleSiteCreationActions({super.key, required this.controller});

  final SimpleSiteCreationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width * 0.4,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: controller.isLoading ? null : controller.cancel,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color:
                      controller.isLoading
                          ? ColorConstants.buttonSecondaryBackground.withValues(
                            alpha: 0.5,
                          )
                          : ColorConstants.buttonSecondaryBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    StringConstants.cancel,
                    style: StyleConstants.labelText14w700Style.copyWith(
                      color:
                          controller.isLoading
                              ? ColorConstants.labelText.withValues(alpha: 0.5)
                              : ColorConstants.labelText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: controller.isLoading ? null : controller.submit,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color:
                      controller.isLoading
                          ? ColorConstants.primary.withValues(alpha: 0.5)
                          : ColorConstants.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child:
                      controller.isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorConstants.white,
                              ),
                            ),
                          )
                          : Text(
                            StringConstants.createSite,
                            style: StyleConstants.white14w700Style,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleSiteCreationContent extends StatelessWidget {
  const SimpleSiteCreationContent({super.key, required this.controller});

  final SimpleSiteCreationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Platform.isWindows ? _windowsBody() : _phoneBody(),
      ),
    );
  }

  Widget _phoneBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: SiteCreationForm(model: controller.siteCreationPageModel),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: SimpleSiteCreationActions(controller: controller),
        ),
      ],
    );
  }

  Widget _windowsBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SimpleSiteStepColumn(onClose: () => controller.cancel()),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: SiteCreationForm(
                  model: controller.siteCreationPageModel,
                  title: StringConstants.siteDetails,
                  fullWidthDescription: true,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 19),
                  child: SimpleSiteCreationActions(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleSiteStepColumn extends StatelessWidget {
  const _SimpleSiteStepColumn({required this.onClose});

  final VoidCallback onClose;

  static const _steps = <String>[
    StringConstants.siteInformation,
    StringConstants.panelSelection,
    StringConstants.panelSettings,
    StringConstants.uploadToPanel,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: ColorConstants.dividerLight)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    AssetConstants.winFolderIcon,
                    height: 22,
                    width: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      StringConstants.newSite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleConstants.textBodyDark16w600Style,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: SvgPicture.asset(
                      AssetConstants.winSidePanelCloseIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _steps.length; i++)
                _StepRow(
                  number: i + 1,
                  label: _steps[i],
                  active: i == 0,
                  showConnector: i < _steps.length - 1,
                ),
              const Spacer(),
              // const _OfflineCallout(),
              // const SizedBox(height: 10),
              // const _AddPanelLabel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.label,
    required this.active,
    required this.showConnector,
  });

  final int number;
  final String label;
  final bool active;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final circleColor =
        active ? ColorConstants.primary : ColorConstants.surfaceMuted;
    final numberColor =
        active ? ColorConstants.white : ColorConstants.textDisabled;
    final labelStyle =
        active
            ? StyleConstants.primary14w600Style
            : StyleConstants.textGray14w500Style;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 28,
              width: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: StyleConstants.white14w600Style.copyWith(
                  color: numberColor,
                ),
              ),
            ),
            if (showConnector)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color:
                            active
                                ? ColorConstants.primary
                                : ColorConstants.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(
                      height: 12,
                      child: VerticalDivider(
                        color:
                            active
                                ? ColorConstants.primary
                                : ColorConstants.surfaceMuted,
                        thickness: 1,
                        width: 1,
                      ),
                    ),
                    Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color:
                            active
                                ? ColorConstants.primary
                                : ColorConstants.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            // const SizedBox(
            //   height: 28,
            //   width: 28,
            //   child: CustomPaint(painter: _DottedConnectorPainter()),
            // ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(label, style: labelStyle),
        ),
      ],
    );
  }
}

class _DottedConnectorPainter extends CustomPainter {
  const _DottedConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = ColorConstants.iconDisabled
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    const gap = 3.0;
    var y = 2.0;
    final x = size.width / 2;
    while (y < size.height - 2) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfflineCallout extends StatelessWidget {
  const _OfflineCallout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ColorConstants.backgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StringConstants.offline,
                style: StyleConstants.textBodyDark14w700Style,
              ),
              const SizedBox(height: 4),
              Text(
                StringConstants.byConnectingBluetooth,
                style: StyleConstants.textGray14w400Style,
              ),
            ],
          ),
        ),
        CustomPaint(size: const Size(16, 8), painter: _CalloutTailPainter()),
      ],
    );
  }
}

class _CalloutTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();
    canvas.drawPath(path, Paint()..color = ColorConstants.backgroundGray);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddPanelLabel extends StatelessWidget {
  const _AddPanelLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add, color: ColorConstants.primary, size: 16),
        const SizedBox(width: 4),
        Text(
          StringConstants.addPanel,
          style: StyleConstants.primary14w600Style,
        ),
      ],
    );
  }
}
