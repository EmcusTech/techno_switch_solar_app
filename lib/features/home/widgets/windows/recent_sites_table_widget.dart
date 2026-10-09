import 'package:Technoswitch/utils/constants/style_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/site_service.dart';

class RecentSitesTableWidget extends StatelessWidget {
  const RecentSitesTableWidget({super.key, required this.controller});

  final HomeScreenController controller;

  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.recentSites,
          style: StyleConstants.textBodyDark20boldStyle,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: ColorConstants.primary),
        ),
      );
    }

    if (controller.sites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          StringConstants.noSitesYet,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF717171),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: controller.sites.length + 1,
          separatorBuilder:
              (_, _) => const Divider(height: 1, color: Color(0xFFE4E4E7)),
          itemBuilder: (context, index) {
            if (index == 0) return _headerRow();
            return _siteRow(controller.sites[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _headerRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _HeaderLabel('Project')),
          SizedBox(width: 240, child: Center(child: _HeaderLabel('Location'))),
          SizedBox(
            width: 240,
            child: Center(child: _HeaderLabel('Date Created')),
          ),
          SizedBox(width: 220, child: Center(child: _HeaderLabel('Status'))),
          SizedBox(width: 172, child: Center(child: _HeaderLabel('Action'))),
        ],
      ),
    );
  }

  Widget _siteRow(SiteWithLogCount siteWithLogCount) {
    final site = siteWithLogCount.site;
    return InkWell(
      // onTap: () => controller.openSite(siteWithLogCount),
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                site.siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleConstants.siteTextColor16w600Style,
              ),
            ),
            SizedBox(
              width: 240,
              child: Center(
                child: Text(
                  '-',
                  style: StyleConstants.siteTextColor216w400Style,
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: Center(
                child: Text(
                  _dateFormat.format(site.createdAt),
                  style: StyleConstants.siteTextColor216w400Style,
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConstants.borderGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 5.0,
                    ),
                    child: Text(
                      'Completed',
                      style: StyleConstants.siteTextColor216w400Style,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 172,
              child: Center(child: Icon(Icons.more_vert, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: StyleConstants.black16w600Style);
  }
}
