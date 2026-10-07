import 'dart:io';

import 'package:flutter/services.dart';
import 'app_prefs.dart';

/// Исключение приложения из оптимизации батареи Android. Без него MIUI,
/// EMUI и One UI часто вообще не запускают фоновую проверку ЛК, и
/// уведомления приходят только при открытии приложения.
///
/// Нативная часть — `MainActivity.kt`, канал `omtech/battery`. На других
/// платформах ограничений нет: [isIgnoring] всегда `true`.
class BatteryOptimization {
  static const _channel = MethodChannel('omtech/battery');
  static const _hintShownKey = 'battery_hint_shown';

  static Future<bool> isIgnoring() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoring') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Открывает системный диалог. Итог узнаём по [isIgnoring] после возврата.
  static Future<void> request() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('request');
    } catch (_) {}
  }

  /// Подсказку показываем один раз — дальше пункт есть в настройках.
  static Future<bool> shouldShowHint() async {
    if (await isIgnoring()) return false;
    final prefs = appPrefs;
    return !(await prefs.getBool(_hintShownKey) ?? false);
  }

  static Future<void> markHintShown() async {
    final prefs = appPrefs;
    await prefs.setBool(_hintShownKey, true);
  }
}
