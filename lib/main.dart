import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app/router/app_router.dart';
import 'app/providers/hardware_controller_provider.dart';
import 'app/providers/theme_provider.dart';
import 'app/providers/auth_provider.dart';
import 'core/services/app_service.dart';
import 'core/services/logger_service.dart';
import 'core/services/mqtt_service.dart';
import 'core/bloc/device_bloc.dart';
import 'core/bloc/room_bloc.dart';
import 'core/bloc/alert_bloc.dart';

late final AppLifecycleListener appLifecycleListener;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Global error handler to catch and log UI overflows and other Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.error(
      'Flutter Error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize app service
  final appService = AppService();
  try {
    await appService.initialize();
  } catch (e) {
    debugPrint('App service initialization failed: $e');
  }

  // Initialize AuthProvider
  final authProvider = AuthProvider();
  try {
    await authProvider.initialize();
  } catch (e) {
    debugPrint('Auth initialization failed: $e');
  }

  // Gracefully release hardware resources on app exit
  appLifecycleListener = AppLifecycleListener(
    onDetach: () => MQTTService().disconnect(autoReconnect: false),
    onHide: () {},
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<DeviceBloc>.value(value: appService.deviceBloc),
        BlocProvider<RoomBloc>.value(value: appService.roomBloc),
        BlocProvider<AlertBloc>.value(value: appService.alertBloc),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => HardwareControllerProvider()),
        ],
        child: SmartHomeApp(appService: appService),
      ),
    ),
  );
}

class SmartHomeApp extends StatelessWidget {
  final AppService appService;

  const SmartHomeApp({super.key, required this.appService});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp.router(
          title: 'SmartHome',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.manropeTextTheme(
                themeProvider.lightTheme.textTheme),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme:
                GoogleFonts.manropeTextTheme(themeProvider.darkTheme.textTheme),
          ),
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter(authProvider).router,
        );
      },
    );
  }
}
