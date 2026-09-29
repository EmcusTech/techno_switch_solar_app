import 'package:get/get.dart';
import 'package:Technoswitch/features/splash/controllers/splash_ui_delegate.dart';

class SplashController extends GetxController {
  static const Duration splashDuration = Duration(seconds: 5);

  SplashUiDelegate? _ui;

  void attachUi(SplashUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  Future<void> startSplash() async {
    await Future.delayed(splashDuration);
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    ui.openHome();
  }

  @override
  void onClose() {
    detachUi();
    super.onClose();
  }
}
