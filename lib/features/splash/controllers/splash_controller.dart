import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/splash/controllers/splash_ui_delegate.dart';

class SplashController extends GetxController {
  static const Duration splashDuration = Duration(seconds: 4);

  SplashUiDelegate? _ui;

  void attachUi(SplashUiDelegate ui) {
    _ui = ui;
    startSplash();
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
