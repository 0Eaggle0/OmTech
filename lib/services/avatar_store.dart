import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Путь к фото профиля — один на всё приложение. Профиль его меняет,
/// главная слушает, иначе шапка дашборда не узнаёт о новом фото.
class AvatarStore {
  static const key = 'user_avatar_path';
  static final path = ValueNotifier<String?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    path.value = prefs.getString(key);
  }

  static Future<void> set(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    path.value = value;
  }
}
