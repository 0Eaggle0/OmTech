import 'package:flutter/material.dart';
import '../services/app_prefs.dart';

/// Управляет режимом темы (system/light/dark) и сохраняет выбор.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  /// Загружает сохранённый режим. Вызывать до runApp.
  Future<void> load() async {
    final prefs = appPrefs;
    final stored = await prefs.getString(_prefsKey);
    _mode = _fromString(stored);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = appPrefs;
    await prefs.setString(_prefsKey, mode.name);
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }
}
