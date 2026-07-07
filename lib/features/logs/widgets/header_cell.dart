import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_list_table_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HeaderCell extends StatelessWidget {
  final LogListTableController table;
  final String text;
  final double width;
  final String columnKey;
  const HeaderCell({
    super.key,
    required this.table,
    required this.text,
    required this.width,
    required this.columnKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = table.sortColumn == columnKey;
    return GestureDetector(
      onTap: () => table.sortByColumn(columnKey),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                style: StyleConstants.primary12w600Style.copyWith(
                  color:
                      isActive
                          ? ColorConstants.primary
                          : ColorConstants.textBodyDark,
                ),
              ),
            ),
            SizedBox(width: 4),
            if (isActive)
              Icon(
                table.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: ColorConstants.primary,
              )
            else
              Icon(
                Icons.unfold_more,
                size: 16,
                color: ColorConstants.textPlaceholder,
              ),
          ],
        ),
      ),
    );
  }
}
