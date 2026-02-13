import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/device_detail_screen.dart';
import '../screens/add_device_screen.dart';
import '../screens/automation_screen.dart';
import '../screens/create_automation_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/energy_screen.dart';
import '../screens/security_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/root_layout.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final hasSeenOnboarding = authProvider.hasSeenOnboarding;

      if (!isLoggedIn &&
          !hasSeenOnboarding &&
          state.uri.toString() != '/onboarding') {
        return '/onboarding';
      }

      if (!isLoggedIn &&
          hasSeenOnboarding &&
          state.uri.toString() != '/login' &&
          state.uri.toString() != '/register' &&
          state.uri.toString() != '/forgot-password' &&
          state.uri.toString() != '/onboarding') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RootLayout(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RootLayout(
          child: OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const RootLayout(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RootLayout(
          child: RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const RootLayout(
          child: ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const RootLayout(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const RootLayout(
          child: DevicesScreen(),
        ),
      ),
      GoRoute(
        path: '/devices/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RootLayout(
            child: DeviceDetailScreen(deviceId: id),
          );
        },
      ),
      GoRoute(
        path: '/add-device',
        builder: (context, state) => const RootLayout(
          child: AddDeviceScreen(),
        ),
      ),
      GoRoute(
        path: '/automation',
        builder: (context, state) => const RootLayout(
          child: AutomationScreen(),
        ),
      ),
      GoRoute(
        path: '/automation/create',
        builder: (context, state) => const RootLayout(
          child: CreateAutomationScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const RootLayout(
          child: NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/energy',
        builder: (context, state) => const RootLayout(
          child: EnergyScreen(),
        ),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const RootLayout(
          child: SecurityScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const RootLayout(
          child: ProfileScreen(),
        ),
      ),
    ],
  );
}
