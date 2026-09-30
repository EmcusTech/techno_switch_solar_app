import 'package:flutter/material.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/widgets/common/peripheral_sheet_chrome.dart';

import 'package:Technoswitch/utils/constants/style_constants.dart';

/// First step: user picks Sounders or Relays for test configuration.
class TestModeChoiceBottomSheet extends StatelessWidget {
  final VoidCallback onSounders;
  final VoidCallback onRelays;

  const TestModeChoiceBottomSheet({
    super.key,
    required this.onSounders,
    required this.onRelays,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
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
            // padding: EdgeInsets.only(
            //   left: 24,
            //   right: 24,
            //   top: 16,
            //   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            // ),
            child: Stack(
              children: [
                const PeripheralSheetHeaderRow(),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dragHandle(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          StringConstants.testMode,
                          style: StyleConstants.textDark20w700Style,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          StringConstants.chooseWhatToTest,
                          style: StyleConstants.textSubtle13w500Style,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _optionTile(
                        title: StringConstants.sounders,
                        onTap: onSounders,
                      ),
                      const SizedBox(height: 12),
                      _optionTile(
                        title: StringConstants.relays,
                        onTap: onRelays,
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

  Widget _optionTile({required String title, required VoidCallback onTap}) {
    return Material(
      color: ColorConstants.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorConstants.borderMuted),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: StyleConstants.textDark15w600Style),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return const PeripheralSheetDragHandle();
  }
}
