import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/splash_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/widgets/ble_session_idle_timeout.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<BleManager>(BleManager(), permanent: true);

  // Initialize app services
  await AppServices.initialize();

  // Seed mock site + panel for testing (skips if already exists)
  // await seedMockData();

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
    "----------------------setUpLogs: Setting up logs..-----------------",
  );

  // SystemChrome.setSystemUIOverlayStyle(
  //   SystemUiOverlayStyle(
  //     systemNavigationBarColor: Color(
  //       0xffEC1D24,
  //     ), // Match your bottom nav color
  //     systemNavigationBarIconBrightness: Brightness.light, // For white icons
  //     // statusBarBrightness: Brightness.light,
  //     // statusBarColor: Colors.transparent,
  //     statusBarIconBrightness: Brightness.dark,
  //   ),
  // );
  Get.put(BleLogController());

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppServices.dispose(); // Clean up services when app is disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      // App is being terminated
      AppServices.dispose();
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BleSessionIdleTimeout(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorObservers: <NavigatorObserver>[appRouteObserver],
          title: 'Techno Switch Solar',
          theme: ThemeData(
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
