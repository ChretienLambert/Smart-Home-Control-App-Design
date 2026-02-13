import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app/router/app_router.dart';
import 'app/providers/theme_provider.dart';
import 'app/providers/auth_provider.dart';
import 'core/services/app_service.dart';
import 'core/bloc/device_bloc.dart';
import 'core/bloc/room_bloc.dart';
import 'core/bloc/alert_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app service
  final appService = AppService();
  await appService.initialize(simulationMode: true); // Start in simulation mode

  // Initialize AuthProvider
  final authProvider = AuthProvider();
  await authProvider.initialize();

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E7F5C),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E7F5C),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter(authProvider).router,
        );
      },
    );
  }
}
