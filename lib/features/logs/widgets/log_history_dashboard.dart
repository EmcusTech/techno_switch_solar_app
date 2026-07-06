import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/widgets/log_retrieval_list_item.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogHistoryDashboard extends StatelessWidget {
  const LogHistoryDashboard({
    super.key,
    required this.history,
    required this.controller,
  });

  final LogHistoryArgs history;
  final LogController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    AssetConstants.panelIcon,
                    height: 62,
                    width: 62,
                  ),
                  SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BleNameUtils.getDisplayPrefixFromBleName(
                          history.panelName,
                        ),
                        style: StyleConstants.black16w700Style,
                      ),
                      Text(
                        BleNameUtils.getDisplayIdFromBleName(history.panelName),
                        style: StyleConstants.textDisabled14w500Style,
                      ),
                      ValueListenableBuilder(
                        valueListenable:
                            controller.bleManager.isConnectedNotifier,
                        builder: (context, isConnected, child) {
                          return Text(
                            isConnected
                                ? StringConstants.connected
                                : StringConstants.disconnected,
                            style: StyleConstants.primary14w500Style.copyWith(
                              color:
                                  isConnected
                                      ? ColorConstants.success
                                      : ColorConstants.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(
                color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
                thickness: 1,
              ),
              SizedBox(height: 10),
              _LogHistoryListSection(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogHistoryListSection extends StatelessWidget {
  const _LogHistoryListSection({required this.controller});

  final LogController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.logRetrievalHistory,
          style: StyleConstants.textDark16w700Style,
        ),
        SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.sizeOf(context).height - 350,
          child:
              controller.isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primary,
                    ),
                  )
                  : controller.logRetrievals.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: ColorConstants.borderGray,
                        ),
                        SizedBox(height: 16),
                        Text(
                          StringConstants.noLogHistory,
                          style: StyleConstants.textGray18w600Style,
                        ),
                        SizedBox(height: 8),
                        Text(
                          UiStrings.logRetrievalsEmptyHintMessage,
                          textAlign: TextAlign.center,
                          style: StyleConstants.textPlaceholder14w400Style,
                        ),
                      ],
                    ),
                  )
                  : ListView.separated(
                    itemCount: controller.logRetrievals.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final logRetrieval = controller.logRetrievals[index];
                      return LogRetrievalListItem(
                        logRetrieval: logRetrieval,
                        onTap: () => controller.openLogSession(logRetrieval),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
