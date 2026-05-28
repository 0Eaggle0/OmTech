import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/group_controller.dart';
import 'controllers/lk_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/news_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');

  final themeController = ThemeController();
  final groupController = GroupController();
  final localeController = LocaleController();
  final lkController = LkController();
  final newsService = NewsService();
  await Future.wait([
    themeController.load(),
    groupController.load(),
    localeController.load(),
    newsService.init(),
  ]);

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
