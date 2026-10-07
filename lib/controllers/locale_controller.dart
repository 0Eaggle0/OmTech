import 'package:flutter/material.dart';
import '../services/app_prefs.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'locale';

  Locale _locale = const Locale('ru');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = appPrefs;
    final saved = await prefs.getString(_key);
    if (saved != null) _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = appPrefs;
    await prefs.setString(_key, locale.languageCode);
  }
}
