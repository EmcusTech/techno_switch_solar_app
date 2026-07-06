import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class LogRetrievalListItem extends StatelessWidget {
  const LogRetrievalListItem({
    super.key,
    required this.logRetrieval,
    required this.onTap,
  });

  final LogRetrievalModel logRetrieval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateRetrieved = logRetrieval.retrievalDate;
    final formattedDate =
        '${dateRetrieved.day.toString().padLeft(2, '0')}/'
        '${dateRetrieved.month.toString().padLeft(2, '0')}/'
        '${dateRetrieved.year} - '
        '${dateRetrieved.hour.toString().padLeft(2, '0')}:'
        '${dateRetrieved.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.surfaceCard),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorConstants.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                color: ColorConstants.danger,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logRetrieval.sessionName,
                    style: StyleConstants.blackMaterial14w700Style,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log Records : ${logRetrieval.logCount}',
                    style: StyleConstants.textSecondary12w400Style,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Date Retrieved : $formattedDate',
                    style: StyleConstants.textMediumGray12w400Style,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
