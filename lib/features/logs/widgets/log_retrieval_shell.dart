import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalShell extends StatelessWidget {
  const LogRetrievalShell({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.canPop,
    this.onPopInvoked,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final bool? canPop;
  final PopInvokedWithResultCallback<bool>? onPopInvoked;

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
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
              padding: EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: SvgPicture.asset(
                            AssetConstants.arrowBackIcon,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          title,
                          style: StyleConstants.black20w700Style,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.white,
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (canPop != null || onPopInvoked != null) {
      content = PopScope(
        canPop: canPop ?? false,
        onPopInvokedWithResult: onPopInvoked,
        child: content,
      );
    }

    return content;
  }
}
