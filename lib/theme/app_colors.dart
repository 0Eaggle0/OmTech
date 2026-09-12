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
  static const Color darkFaint = Color(0xFF6E6B7C);

  /// Заливка карточки — темнее `darkSurface`, чтобы карточка читалась
  /// как отдельный слой поверх фона.
  static const Color darkCard = Color(0xFF17151F);

  /// Вложенный блок внутри карточки (плитки, поля, чипы).
  static const Color darkElevated = Color(0xFF221F2E);

  // Светлая тема
  static const Color lightBackground = Color(0xFFF5F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightMuted = Color(0xFF6B6878);
  static const Color lightFaint = Color(0xFF9A97A8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF2F1F7);

  // Статусные цвета — те же, что и у типов занятий, чтобы палитра была одна.
  static const Color statusInfo = Color(0xFF4F9DDE);
  static const Color statusSuccess = Color(0xFF49C18B);
  static const Color statusWarning = Color(0xFFE0A03A);
  static const Color statusDanger = Color(0xFFE05A6B);

  /// Градиент акцентов (шапки, выделенные карточки).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );

  /// Цвета для типов занятий (чипы в расписании).
  static Color forKindOfWork(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('лекц')) return statusInfo;
    if (k.contains('практ') || k.contains('семинар')) return statusSuccess;
    if (k.contains('лаб')) return statusWarning;
    if (k.contains('экзам') || k.contains('зачёт') || k.contains('зачет')) {
      return statusDanger;
    }
    return violet;
  }
}
