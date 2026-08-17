import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:high_custom_frontend/main.dart';
import 'package:high_custom_frontend/models/user_model.dart';
import 'package:high_custom_frontend/screens/auth/login_screen.dart';
import 'package:high_custom_frontend/screens/dashboard/dashboard_screen.dart';
import 'package:high_custom_frontend/screens/dashboard/master/create_sequence_form.dart';
import 'package:high_custom_frontend/services/auth_api.dart';
import 'package:high_custom_frontend/widgets/dashboard/dashboard_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'High Custom app loads dashboard when a valid auth token exists',
    (WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'test-token',
      });

      await tester.pumpWidget(
        const HighCustomApp(),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(DashboardScreen),
        findsOneWidget,
      );

      expect(
        find.byType(LoginScreen),
        findsNothing,
      );
    },
  );

  testWidgets(
    'High Custom app loads login screen when no token is saved',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const HighCustomApp(),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );

      expect(
        find.text('HIGH CUSTOM JEWELLERS'),
        findsOneWidget,
      );

      expect(
        find.text('WELCOME BACK'),
        findsOneWidget,
      );
    },
  );

  test('Auth logout API returns a structured result and clears auth storage', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'test-token',
      'user_email': 'john@example.com',
    });

    final result = await AuthApi.logout();

    expect(result, isA<Map<String, dynamic>>());
    expect(result.containsKey('message'), isTrue);

    final storage = const FlutterSecureStorage();
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'user_email'), isNull);
  });

  testWidgets(
    'Dashboard header hides username completely',
    (WidgetTester tester) async {
      final user = UserModel(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        employerCode: 'HC-100',
        email: 'john@example.com',
        phone: '1234567890',
        isEmailVerified: true,
        isLogIn: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardHeader(
            isSidebarOpen: false,
            onMenuPressed: () {},
            onProfileMenuSelected: (_) {},
            user: user,
          ),
        ),
      );

      expect(find.text('John Doe'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardHeader(
            isSidebarOpen: true,
            onMenuPressed: () {},
            onProfileMenuSelected: (_) {},
            user: user,
          ),
        ),
      );

      expect(find.text('John Doe'), findsNothing);
    },
  );

  testWidgets(
    'Create sequence form shows the live preview panel',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateSequenceForm(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Live Preview'), findsOneWidget);
      expect(find.textContaining('No subject'), findsOneWidget);
    },
  );
}