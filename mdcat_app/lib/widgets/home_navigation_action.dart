import 'package:flutter/material.dart';

/// A consistent shortcut back to the signed-in home dashboard.
///
/// Feature screens are pushed above HomeScreen, so returning to the first
/// route avoids creating duplicate dashboards in the navigation stack.
class HomeNavigationAction extends StatelessWidget {
  const HomeNavigationAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back to Home',
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      icon: const Icon(Icons.home_outlined),
    );
  }
}
