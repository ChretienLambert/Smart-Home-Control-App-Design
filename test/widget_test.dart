import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_control/main.dart';
import 'package:smart_home_control/core/services/app_service.dart';

void main() {
  testWidgets('Smart Home App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      SmartHomeApp(appService: AppService()),
    );

    // Verify app loads
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
