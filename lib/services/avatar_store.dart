import 'package:flutter/foundation.dart';
import 'app_prefs.dart';

/// Путь к фото профиля — один на всё приложение. Профиль его меняет,
/// главная слушает, иначе шапка дашборда не узнаёт о новом фото.
class AvatarStore {
  static const key = 'user_avatar_path';
  static final path = ValueNotifier<String?>(null);

  static Future<void> load() async {
    final prefs = appPrefs;
    path.value = await prefs.getString(key);
  }

  static Future<void> set(String? value) async {
    final prefs = appPrefs;
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    path.value = value;
  }
}
