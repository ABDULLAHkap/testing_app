import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mdcat_app/screens/auth/login_screen.dart';
import 'package:mdcat_app/services/auth_provider.dart';
import 'package:mdcat_app/services/theme_provider.dart';

void main() {
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

    expect(find.text('AI Exam Preparation'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Server settings'), findsNothing);
  });
}
