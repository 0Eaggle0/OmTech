import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

/// Корневой виджет приложения: тема, локализация ru, домашний экран.
class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    final locale = context.watch<LocaleController>().locale;
    return MaterialApp(
      title: 'OmTech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const HomeShell(),
    );
  }
}
