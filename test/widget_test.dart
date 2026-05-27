import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campus2_0/app.dart';
import 'package:campus2_0/controllers/group_controller.dart';
import 'package:campus2_0/controllers/theme_controller.dart';

void main() {
  testWidgets('Приложение запускается и показывает нижнее меню', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ru');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => GroupController()),
        ],
        child: const CampusApp(),
      ),
    );
    // Проверяем каркас до завершения фоновых загрузок (заглушки с задержкой).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);

    // Даём отработать таймерам заглушек, чтобы не осталось pending-таймеров.
    await tester.pump(const Duration(seconds: 1));
  });
}
