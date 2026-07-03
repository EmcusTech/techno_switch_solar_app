import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

class SiteArgs {
  const SiteArgs({
    required this.site,
    required this.siteWithLogCount,
  });

  final SiteModel site;
  final SiteWithLogCount siteWithLogCount;
}

class SiteDetailArgs {
  const SiteDetailArgs({required this.siteWithLogCount});

  final SiteWithLogCount siteWithLogCount;
}

class SimpleSiteCreationArgs {
  const SimpleSiteCreationArgs({
    required this.retrievedLogs,
    this.panelName,
    this.panelVersionNo,
    this.panelId,
    this.returnCreatedSiteId = false,
  });

  final List<LogModel> retrievedLogs;
  final String? panelName;
  final String? panelVersionNo;
  final String? panelId;
  final bool returnCreatedSiteId;
}
