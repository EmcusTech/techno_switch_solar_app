import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

Future<T?> showDashboardPeripheralSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context) builder,
  VoidCallback? whenComplete,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorConstants.transparent,
    barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
    builder: builder,
  ).whenComplete(whenComplete ?? () {});
}
