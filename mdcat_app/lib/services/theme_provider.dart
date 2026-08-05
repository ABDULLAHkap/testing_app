import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _key = "theme_mode";

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final stored = await _storage.read(key: _key);
    switch (stored) {
      case "light":
        _mode = ThemeMode.light;
        break;
      case "dark":
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _storage.write(
      key: _key,
      value: switch (mode) {
        ThemeMode.light => "light",
        ThemeMode.dark => "dark",
        ThemeMode.system => "system",
      },
    );
  }
}
