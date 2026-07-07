import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/features/splash/views/splash_screen.dart';
import 'package:techno_switch_solar_app/utils/app/app_services.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/ble/ble_session_idle_timeout.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class TechnoSwitchApp extends StatefulWidget {
  const TechnoSwitchApp({super.key});

  @override
  State<TechnoSwitchApp> createState() => _TechnoSwitchAppState();
}

class _TechnoSwitchAppState extends State<TechnoSwitchApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppServices.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      AppServices.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder:
        (_, _) => SafeArea(
          child: BleSessionIdleTimeout(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorObservers: <NavigatorObserver>[appRouteObserver],
              title: StringConstants.appTitle,
              theme: ThemeData(
                textTheme: GoogleFonts.interTextTheme(
                  Theme.of(context).textTheme,
                ),
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
              ),
              home: const SplashScreen(),
            ),
          ),
        ),
  );
}
