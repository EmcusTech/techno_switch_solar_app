import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BleManager>(BleManager(), permanent: true);
    Get.lazyPut<BleLogController>(() => BleLogController(), fenix: true);
  }

  Future<void> setAppInitials() async {
    await FlutterLogs.initLogs(
      logLevelsEnabled: <LogLevel>[
        LogLevel.INFO,
        LogLevel.WARNING,
        LogLevel.ERROR,
        LogLevel.SEVERE,
      ],
      timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
      directoryStructure: DirectoryStructure.SINGLE_FILE_FOR_DAY,
      logTypesEnabled: <String>["techno_switch", "BLELogs"],
      logFileExtension: LogFileExtension.LOG,
      logsWriteDirectoryName: "TechnoSwitchLogs",
      logsExportDirectoryName: "TechnoSwitchLogs/Exported",
      debugFileOperations: true,
      isDebuggable: true,
      logsRetentionPeriodInDays: 7,
      zipsRetentionPeriodInDays: 3,
      autoDeleteZipOnExport: true,
      autoClearLogs: true,
      enabled: true,
    );

    FlutterLogs.logInfo(
      "TechnoSwitchLogs",
      "<${DateTime.now()}>",
      StringConstants.datetimeNow,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ColorConstants.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
