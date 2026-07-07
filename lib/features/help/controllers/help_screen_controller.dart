import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/help/models/help_faq_item.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class HelpScreenController extends GetxController {
  HelpScreenUiDelegate? _ui;

  static const List<HelpFaqItem> faqItems = [
    HelpFaqItem(
      question: StringConstants.faqHowDoICreateNewProject,
      answer: UiStrings.faqHowDoICreateNewProjectAnswer,
    ),
    HelpFaqItem(
      question: StringConstants.faqHowCanIRetrieveProjectLogs,
      answer: UiStrings.faqHowCanIRetrieveProjectLogsAnswer,
    ),
    HelpFaqItem(
      question: StringConstants.faqWhatMaintenanceTasksAvailable,
      answer: UiStrings.faqWhatMaintenanceTasksAvailableAnswer,
    ),
  ];

  void attachUi(HelpScreenUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  Future<void> callSupport() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    await ui.launchPhone(StringConstants.s18001234567);
  }

  Future<void> emailSupport() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    await ui.launchEmail(StringConstants.supportTechnoswitchCom);
  }

  Future<void> openUserManual() async {
    await _launchExternalUrl(StringConstants.helpUserManualUrl);
  }

  Future<void> openVideoTutorials() async {
    await _launchExternalUrl(StringConstants.helpVideoTutorialsUrl);
  }

  Future<void> openCommunityForum() async {
    await _launchExternalUrl(StringConstants.helpCommunityForumUrl);
  }

  Future<void> _launchExternalUrl(String url) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    await ui.launchExternalUrl(url);
  }
}
