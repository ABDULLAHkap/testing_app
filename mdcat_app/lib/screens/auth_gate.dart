import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import 'auth/landing_screen.dart';
import 'auth/mobile_auth_flow.dart';
import 'home/home_screen.dart';

/// Shown briefly on app start while we check whether a saved token
/// is still valid, then routes to the signed-out experience or Home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return const LandingScreen();
            }
            return const MobileWelcomeScreen();
          },
        );
    }
  }
}
