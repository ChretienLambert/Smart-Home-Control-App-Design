import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:smart_home_control/app/providers/auth_provider.dart';
import 'package:smart_home_control/app/providers/hardware_controller_provider.dart';
import 'package:smart_home_control/app/providers/theme_provider.dart';
import 'package:smart_home_control/app/screens/dashboard_screen.dart';
import 'package:smart_home_control/core/bloc/alert_bloc.dart';
import 'package:smart_home_control/core/bloc/device_bloc.dart';

void main() {
  testWidgets('Dashboard renders offline hardware banner and cached sections',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DeviceBloc>(create: (_) => DeviceBloc()),
          BlocProvider<AlertBloc>(create: (_) => AlertBloc()),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => HardwareControllerProvider()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hardware Disconnected'), findsOneWidget);
    expect(find.text('Live Hardware LCD'), findsOneWidget);
    expect(find.textContaining('cached data'), findsWidgets);
  });
}
