import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppAppearance { standard, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = "theme_mode";

  AppAppearance _appearance = AppAppearance.standard;
  AppAppearance get appearance => _appearance;

  ThemeMode get mode =>
      _appearance == AppAppearance.light ? ThemeMode.light : ThemeMode.dark;

  Future<void> load() async {
    final stored = await _storage.read(key: _key);
    switch (stored) {
      case "light":
        _appearance = AppAppearance.light;
        break;
      case "dark":
        _appearance = AppAppearance.dark;
        break;
      default:
        _appearance = AppAppearance.standard;
    }
    notifyListeners();
  }

  Future<void> setAppearance(AppAppearance appearance) async {
    _appearance = appearance;
    notifyListeners();
    await _storage.write(
      key: _key,
      value: switch (appearance) {
        AppAppearance.light => "light",
        AppAppearance.dark => "dark",
        AppAppearance.standard => "default",
      },
    );
  }
}
