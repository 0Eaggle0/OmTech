import 'package:flutter/material.dart';

/// Палитра приложения ОМГТУ Campus.
/// Базовый стиль — тёмный молодёжный с фиолетовыми акцентами;
/// светлая тема использует тот же фиолетовый seed.
class AppColors {
  AppColors._();

  /// Основной акцент (неоновый фиолетовый).
  static const Color violet = Color(0xFF8B5CF6);

  /// Вторичный акцент (индиго) — используется в градиентах.
  static const Color indigo = Color(0xFF6C5CE7);

  // Тёмная тема
  static const Color darkBackground = Color(0xFF121018);
  static const Color darkSurface = Color(0xFF1C1A24);
  static const Color darkSurfaceHigh = Color(0xFF232030);
  static const Color darkText = Color(0xFFECECF1);
  static const Color darkMuted = Color(0xFF9A97A8);

  // Светлая тема
  static const Color lightBackground = Color(0xFFF5F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightMuted = Color(0xFF6B6878);

  /// Градиент акцентов (шапки, выделенные карточки).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );

  /// Цвета для типов занятий (чипы в расписании).
  static Color forKindOfWork(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('лекц')) return const Color(0xFF4F9DDE);
    if (k.contains('практ') || k.contains('семинар')) return const Color(0xFF49C18B);
    if (k.contains('лаб')) return const Color(0xFFE0A03A);
    if (k.contains('экзам') || k.contains('зачёт') || k.contains('зачет')) {
      return const Color(0xFFE05A6B);
    }
    return violet;
  }
}
