import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Смысловой статус элемента. Определяет цвет пилюли, акцентной полосы
/// и подсветки — вместо хексов, разбросанных по экранам.
enum AppStatus { neutral, info, success, warning, danger, accent }

/// Токены оформления, которых нет в `ColorScheme`: заливки слоёв, волосяная
/// граница, приглушённый текст, фон плавающей навигации, окружающее свечение.
///
/// Именно расширение темы, а не статические константы: иначе в каждый экран
/// вернутся тернарники `isDark ? ... : ...`.
@immutable
class AppGlass extends ThemeExtension<AppGlass> {
  /// Заливка карточки.
  final Color cardFill;

  /// Вложенный блок внутри карточки: плитка, поле, чип.
  final Color elevatedFill;

  /// Полупрозрачная заливка под `BackdropFilter`.
  final Color glassFill;

  /// Волосяная граница карточек и панелей.
  final Color hairline;

  /// Второстепенный текст: подписи, мета-строки.
  final Color textMuted;

  /// Третьестепенный текст: подсказки, неактивное.
  final Color textFaint;

  /// Фон плавающей нижней панели.
  final Color navFill;

  /// Заливка «пилюли» выбранной вкладки.
  final Color navIndicator;

  /// Основной акцент темы (совпадает с `colorScheme.primary`).
  final Color accent;

  /// Градиент акцентных поверхностей: шапки, крупные плитки.
  final LinearGradient accentGradient;

  /// Верхнее и нижнее пятна окружающего свечения (см. `AmbientGlow`).
  final Color ambientTop;
  final Color ambientBottom;

  final bool isDark;

  const AppGlass({
    required this.cardFill,
    required this.elevatedFill,
    required this.glassFill,
    required this.hairline,
    required this.textMuted,
    required this.textFaint,
    required this.navFill,
    required this.navIndicator,
    required this.accent,
    required this.accentGradient,
    required this.ambientTop,
    required this.ambientBottom,
    required this.isDark,
  });

  factory AppGlass.dark(Color accent) => AppGlass(
        cardFill: AppColors.darkCard,
        elevatedFill: AppColors.darkElevated,
        glassFill: Colors.white.withValues(alpha: 0.08),
        hairline: Colors.white.withValues(alpha: 0.07),
        textMuted: AppColors.darkMuted,
        textFaint: AppColors.darkFaint,
        navFill: const Color(0xFF1A1824).withValues(alpha: 0.92),
        navIndicator: accent.withValues(alpha: 0.18),
        accent: accent,
        accentGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.violet],
        ),
        ambientTop: AppColors.violet.withValues(alpha: 0.10),
        ambientBottom: AppColors.indigo.withValues(alpha: 0.07),
        isDark: true,
      );

  factory AppGlass.light(Color accent) => AppGlass(
        cardFill: AppColors.lightCard,
        elevatedFill: AppColors.lightElevated,
        glassFill: Colors.white.withValues(alpha: 0.80),
        hairline: Colors.black.withValues(alpha: 0.06),
        textMuted: AppColors.lightMuted,
        textFaint: AppColors.lightFaint,
        navFill: Colors.white.withValues(alpha: 0.95),
        navIndicator: accent.withValues(alpha: 0.14),
        accent: accent,
        accentGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigo, AppColors.violet],
        ),
        ambientTop: AppColors.violet.withValues(alpha: 0.07),
        ambientBottom: AppColors.indigo.withValues(alpha: 0.05),
        isDark: false,
      );

  /// Цвет статуса: текст пилюли, акцентная полоса, точка фильтра.
  Color statusColor(AppStatus status) => switch (status) {
        AppStatus.neutral => textMuted,
        AppStatus.info => AppColors.statusInfo,
        AppStatus.success => AppColors.statusSuccess,
        AppStatus.warning => AppColors.statusWarning,
        AppStatus.danger => AppColors.statusDanger,
        AppStatus.accent => accent,
      };

  /// Заливка под цвет статуса — фон пилюли, тонированного блока.
  Color statusFill(AppStatus status) => tint(statusColor(status));

  /// Тонированная заливка произвольным цветом.
  Color tint(Color color) => color.withValues(alpha: isDark ? 0.14 : 0.11);

  /// Цветная подсветка под акцентной плиткой.
  List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.38 : 0.22),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  /// Тень плавающей панели: отделяет её от контента, который под ней скроллится.
  List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  @override
  AppGlass copyWith({
    Color? cardFill,
    Color? elevatedFill,
    Color? glassFill,
    Color? hairline,
    Color? textMuted,
    Color? textFaint,
    Color? navFill,
    Color? navIndicator,
    Color? accent,
    LinearGradient? accentGradient,
    Color? ambientTop,
    Color? ambientBottom,
    bool? isDark,
  }) {
    return AppGlass(
      cardFill: cardFill ?? this.cardFill,
      elevatedFill: elevatedFill ?? this.elevatedFill,
      glassFill: glassFill ?? this.glassFill,
      hairline: hairline ?? this.hairline,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      navFill: navFill ?? this.navFill,
      navIndicator: navIndicator ?? this.navIndicator,
      accent: accent ?? this.accent,
      accentGradient: accentGradient ?? this.accentGradient,
      ambientTop: ambientTop ?? this.ambientTop,
      ambientBottom: ambientBottom ?? this.ambientBottom,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppGlass lerp(covariant AppGlass? other, double t) {
    if (other == null) return this;
    return AppGlass(
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      elevatedFill: Color.lerp(elevatedFill, other.elevatedFill, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t)!,
      ambientTop: Color.lerp(ambientTop, other.ambientTop, t)!,
      ambientBottom: Color.lerp(ambientBottom, other.ambientBottom, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension GlassX on BuildContext {
  /// Токены оформления текущей темы.
  AppGlass get glass => Theme.of(this).extension<AppGlass>()!;
}
