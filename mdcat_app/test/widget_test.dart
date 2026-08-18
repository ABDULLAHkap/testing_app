import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mdcat_app/screens/auth/login_screen.dart';
import 'package:mdcat_app/screens/auth/landing_screen.dart';
import 'package:mdcat_app/screens/quiz/quiz_screen.dart';
import 'package:mdcat_app/services/auth_provider.dart';
import 'package:mdcat_app/services/theme_provider.dart';

void main() {
  test('quiz cannot advance until the current question is answered', () {
    expect(canAdvanceQuizQuestion(<int, String>{}, 0), isFalse);
    expect(canAdvanceQuizQuestion(<int, String>{0: 'B'}, 0), isTrue);
    expect(canAdvanceQuizQuestion(<int, String>{0: 'B'}, 1), isFalse);
  });

  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('New here? Create Account'), findsOneWidget);
    expect(find.text('Server settings'), findsNothing);
  });

  testWidgets('desktop landing page opens the existing login screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    expect(find.text('Prepare Smarter,\nScore Better'), findsOneWidget);
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('How It Works'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Login').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
