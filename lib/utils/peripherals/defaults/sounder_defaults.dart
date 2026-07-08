import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for Sounder configuration (main outputs, advanced tabs).
abstract final class SounderDefaults {
  static const String outputText = '';
  static const String typeLabel = PanelValues.sounderTypeNormal;
  static const bool normalBle = true;
  static const String enabledLabel = PanelValues.yesOption;
  static const bool enabledBle = true;
  static const bool testBle = false;

  static const int groupGeneralBle = 1;
  static const int groupExtOutBle = 3;
  static const int functionFireSndBle = 0;
  static const int functionExtSnd1Ble = 0;
  static const int functionExtSnd2Ble = 1;
  static const int extOutFunctionNoBle = 1;

  static const String groupGeneralLabel = 'General';
  static const String groupExtOutLabel = StringConstants.extOut;
  static const String functionFireSndLabel = StringConstants.fireSnd;
  static const String functionExtSnd1Label = StringConstants.extSnd1;
  static const String functionExtSnd2Label = 'Ext. Snd 2';

  static const String zoneEnabledLabel = PanelValues.yesOption;
  static const String zoneTestLabel = PanelValues.noOption;
  static const String actionContinuousLabel = 'Continuous';
  static const int actionContinuousBle = 0;

  static const String extOutEnabledLabel = PanelValues.yesOption;
  static const String extOutTestLabel = PanelValues.noOption;
  static const String countdownActionLabel =
      StringConstants.pulsing2sOn500msOff;
  static const String holdActionLabel = StringConstants.pulsing1sOn4sOff;
  static const String releaseActionLabel = 'Continuous';
  static const int countdownActionBle = 3;
  static const int holdActionBle = 2;
  static const int releaseActionBle = 0;

  static const bool generalEnabledBle = true;
  static const bool generalTestBle = false;
  static const int generalActionBle = 0;
  static const int delayBle = 0;
  static const bool delayedBle = true;
  static const String delayedLabel = PanelValues.yesOption;

  static Map<String, dynamic> sounder1() => {
    'enabled': enabledBle,
    'test': testBle,
    'normal': normalBle,
    'outputText': outputText,
    'group': groupGeneralBle,
    'function': functionFireSndBle,
    'functionNo': 0,
  };

  static Map<String, dynamic> sounder2() => {
    'enabled': enabledBle,
    'test': testBle,
    'normal': normalBle,
    'outputText': outputText,
    'group': groupExtOutBle,
    'function': functionExtSnd1Ble,
    'functionNo': extOutFunctionNoBle,
  };

  static Map<String, dynamic> sounder3() => {
    'enabled': enabledBle,
    'test': testBle,
    'normal': normalBle,
    'outputText': outputText,
    'group': groupExtOutBle,
    'function': functionExtSnd2Ble,
    'functionNo': extOutFunctionNoBle,
  };

  static Map<String, dynamic> mainSounderEntry(int index) {
    switch (index) {
      case 0:
        return sounder1();
      case 1:
        return sounder2();
      default:
        return sounder3();
    }
  }

  static Map<String, dynamic> zoneEntry() => {
    'enabled': enabledBle,
    'test': testBle,
    'action': actionContinuousBle,
  };

  static Map<String, dynamic> extOutEntry() => {
    'enabled': enabledBle,
    'test': testBle,
    'countdownAction': countdownActionBle,
    'holdAction': holdActionBle,
    'releaseAction': releaseActionBle,
  };

  static Map<String, dynamic> general() => {
    'enabled': generalEnabledBle,
    'test': generalTestBle,
    'action': generalActionBle,
    'delay': delayBle,
    'delayed': delayedBle,
  };

  static Map<String, dynamic> toCacheMap() => {
    's1': sounder1(),
    's2': sounder2(),
    's3': sounder3(),
    'z1': zoneEntry(),
    'z2': zoneEntry(),
    'z3': zoneEntry(),
    'e1': extOutEntry(),
    'e2': extOutEntry(),
    'e3': extOutEntry(),
    'general': general(),
  };

  static String typeLabelFromNormal(bool normal) =>
      normal ? typeLabel : StringConstants.isMTL5525;
}
