import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_glass.dart';
import 'app_metrics.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.violet,
      secondary: AppColors.indigo,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
    );
    return _base(scheme, AppColors.darkBackground, AppColors.darkCard);
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.indigo,
      secondary: AppColors.violet,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
    );
    return _base(scheme, AppColors.lightBackground, AppColors.lightCard);
  }

  /// Единая шкала размеров. Задаём только роли, которые реально повторяются
  /// в макетах — остальное подмешивается из стандартной типографики Material.
  /// Цвета намеренно не трогаем: их и раньше давала типографика, а экраны
  /// всюду задают цвет текста сами.
  static const TextTheme _textTheme = TextTheme(
    // Заголовок экрана.
    headlineSmall:
        TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
    // Крупная цифра: GPA, счётчик в плитке.
    titleLarge:
        TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    // Заголовок карточки.
    titleMedium:
        TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    bodyMedium:
        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35),
    // Мета-строка: дата, преподаватель, «N б. · N ч.».
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    // Капс-подпись секции.
    labelSmall:
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
  );

  static ThemeData _base(ColorScheme scheme, Color background, Color cardColor) {
    final isDark = scheme.brightness == Brightness.dark;
    final glass = isDark
        ? AppGlass.dark(scheme.primary)
        : AppGlass.light(scheme.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme,
      extensions: [glass],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: _textTheme.headlineSmall!.copyWith(
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: glass.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: glass.elevatedFill,
        labelStyle: _textTheme.bodySmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.tile)),
        ),
        iconColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.elevatedFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: glass.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide(color: glass.hairline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: scheme.onSurface.withValues(alpha: 0.2),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
