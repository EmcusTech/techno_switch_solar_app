import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class SiteCreationDialog extends StatelessWidget {
  final VoidCallback onCreateSite;
  final VoidCallback onSkip;
  final int logCount;

  const SiteCreationDialog({
    super.key,
    required this.onCreateSite,
    required this.onSkip,
    required this.logCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorConstants.errorIconBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AssetConstants.newProjectIcon,
                  height: 32,
                  width: 32,
                  colorFilter: ColorFilter.mode(
                    ColorConstants.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Title
            Text(
              StringConstants.createSiteForLogs,
              style: StyleConstants.textDark20w700Style,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: StyleConstants.textGray16w400Style,
                children: [
                  TextSpan(text: StringConstants.youRetrieved),
                  TextSpan(
                    text: '$logCount log${logCount == 1 ? '' : 's'}',
                    style: StyleConstants.primary16w600Style,
                  ),
                  TextSpan(
                    text:
                        ' from the device, but they are not associated with any site.\n\n',
                  ),
                  TextSpan(
                    text:
                        UiStrings.wouldYouLikeToCreateSiteToSaveLogsMessage,
                  ),
                  TextSpan(
                    text: StringConstants.ifYouSkipThisStepTheLogsWillBeLost,
                    style: StyleConstants.primary16w600Style,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Skip Button
                Expanded(
                  child: GestureDetector(
                    onTap: onSkip,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorConstants.buttonSecondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ColorConstants.borderLight, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          StringConstants.skip,
                          style: StyleConstants.textGray16w600Style,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Create Site Button
                Expanded(
                  child: GestureDetector(
                    onTap: onCreateSite,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Create Site',
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
  }
}

/// Show the site creation dialog
Future<bool?> showSiteCreationDialog(
  BuildContext context, {
  required int logCount,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      return SiteCreationDialog(
        logCount: logCount,
        onCreateSite: () {
          Navigator.of(dialogContext, rootNavigator: true).pop(true);
        },
        onSkip: () {
          Navigator.of(dialogContext, rootNavigator: true).pop(false);
        },
      );
    },
  );
}
