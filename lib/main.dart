import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'controllers/group_controller.dart';
import 'controllers/lk_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/background_worker.dart';
import 'services/news_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  final themeController = ThemeController();
  final groupController = GroupController();
  final localeController = LocaleController();
  final newsService = NewsService();
  final lkController = await LkController.create();

  // До первого кадра ждём только то, без чего интерфейс мигнёт неверной
  // темой, языком или пустым расписанием. Всё остальное — в фоне.
  await Future.wait([
    themeController.load(),
    groupController.load(),
    localeController.load(),
  ]);

  if (localeController.locale.languageCode == 'en') {
    await initializeDateFormatting('en');
  } else {
    unawaited(initializeDateFormatting('en'));
  }

  unawaited(NotificationService.instance.init());
  unawaited(newsService.init());

  // Ежечасная фоновая проверка уведомлений. На Android реальная периодичность
  // соблюдается приближённо (Doze, App Standby). На iOS — best-effort.
  unawaited(_initBackgroundWorker());

  // При первом входе в ЛК — запрашиваем разрешение и проверяем обновления.
  var notifChecked = false;
  lkController.addListener(() {
    if (!notifChecked && lkController.isConnected) {
      notifChecked = true;
      unawaited(NotificationService.instance.requestPermission());
      unawaited(NotificationService.instance.checkAll(lkController));
    }
  });

  // Тихий авто-логин в ЛК — не блокирует запуск.
  unawaited(lkController.tryAutoLogin());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: groupController),
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: lkController),
        Provider<NewsService>.value(value: newsService),
      ],
      child: const CampusApp(),
    ),
  );
}

Future<void> _initBackgroundWorker() async {
  try {
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      hourlyCheckTask,
      hourlyCheckTask,
      frequency: const Duration(hours: 1),
      // Без задержки WorkManager выполняет первый прогон сразу после
      // регистрации — параллельно с авто-логином, в одну папку cookies.
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (_) {
    // На неподдерживаемых платформах (desktop) workmanager не работает —
    // это ОК, приложение всё ещё запускается.
  }
}
