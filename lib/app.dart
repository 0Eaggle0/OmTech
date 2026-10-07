import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/lk_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_shell.dart';
import 'services/background_worker.dart';
import 'services/screen_capture.dart';
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
    _startHeartbeat();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _startHeartbeat();
        unawaited(context.read<LkController>().refreshIfStale());
      },
      onPause: () => _heartbeat?.cancel(),
    );
  }

  /// Пока приложение на экране, раз в минуту обновляем метку активности —
  /// одной отметки при старте хватало только на первые 2 минуты.
  Timer? _heartbeat;

  void _startHeartbeat() {
    _heartbeat?.cancel();
    unawaited(markUiActive());
    _heartbeat = Timer.periodic(
        const Duration(minutes: 1), (_) => unawaited(markUiActive()));
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
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
      // Граница перерисовки над навигатором — чтобы отчёт об ошибке мог
      // снять экран вместе с открытыми шторками.
      builder: (context, child) =>
          RepaintBoundary(key: ScreenCapture.boundaryKey, child: child),
      home: const HomeShell(),
    );
  }
}
