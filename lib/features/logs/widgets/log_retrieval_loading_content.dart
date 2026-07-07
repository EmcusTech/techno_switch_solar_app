import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalLoadingContent extends StatelessWidget {
  const LogRetrievalLoadingContent({
    super.key,
    required this.ble,
    required this.onCancel,
  });

  final BleManager ble;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: SvgPicture.asset(AssetConstants.background2),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 45),
            child: Text(
              StringConstants.retrievingLogs,
              style: StyleConstants.textMuted24w600Style,
            ),
          ),
        ),
        Lottie.asset(
          AssetConstants.fetchingLogJson,
          height: 320,
          width: 320,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: ValueListenableBuilder<String>(
            valueListenable: ble.processDesc,
            builder: (context, value, _) {
              return Text(
                value,
                style: StyleConstants.textMuted12w400Style,
                textAlign: TextAlign.center,
                maxLines: 2,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<int>(
              valueListenable: ble.bleProcess.read1000LogsCount,
              builder: (context, readCount, _) {
                final percent =
                    (readCount / 1000.0).clamp(0.0, 1.0).toDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}%',
                      style: StyleConstants.black32w700Style,
                      maxLines: 1,
                    ),
                    SizedBox(height: 23),
                    LinearPercentIndicator(
                      lineHeight: 11.0,
                      percent: percent,
                      backgroundColor: ColorConstants.progressTrack,
                      progressColor: ColorConstants.primary,
                      barRadius: Radius.circular(20),
                    ),
                    SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  borderRadius: BorderRadius.circular(28.5),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    StringConstants.cancel,
                    style: StyleConstants.white16w600Style,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
