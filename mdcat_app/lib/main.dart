import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_provider.dart';
import 'services/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth_gate.dart';
import 'screens/onboarding/mobile_onboarding_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.bootstrap();
  runApp(const MdcatApp());
}

class MdcatApp extends StatelessWidget {
  const MdcatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'BrainBoost',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            darkTheme: themeProvider.appearance == AppAppearance.standard
                ? AppTheme.standardTheme
                : AppTheme.darkTheme,
            themeMode: themeProvider.mode,
            home: const MobileOnboardingGate(child: AuthGate()),
          );
        },
      ),
    );
  }
}
