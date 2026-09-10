import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_shell.dart';
import 'services/background_worker.dart';
import 'theme/app_theme.dart';

/// Корневой виджет приложения: тема, локализация ru, домашний экран.
class CampusApp extends StatefulWidget {
  const CampusApp({super.key});

  @override
  State<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends State<CampusApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Отмечаем активность UI, чтобы фоновый воркер не логинился параллельно
    // и не портил cookie-jar, общий у двух изолятов.
    unawaited(markUiActive());
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(markUiActive()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

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
