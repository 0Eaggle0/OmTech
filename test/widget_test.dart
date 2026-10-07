import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:campus2_0/app.dart';
import 'package:campus2_0/controllers/app_nav_controller.dart';
import 'package:campus2_0/controllers/group_controller.dart';
import 'package:campus2_0/controllers/lk_controller.dart';
import 'package:campus2_0/controllers/locale_controller.dart';
import 'package:campus2_0/controllers/schedule_nav_controller.dart';
import 'package:campus2_0/controllers/settings_controller.dart';
import 'package:campus2_0/controllers/theme_controller.dart';
import 'package:campus2_0/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('Приложение запускается и показывает нижнее меню', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await initializeDateFormatting('ru');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => GroupController()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => LkController()),
          ChangeNotifierProvider(create: (_) => AppNavController()),
          ChangeNotifierProvider(create: (_) => ScheduleNavController()),
          ChangeNotifierProvider(create: (_) => SettingsController()),
        ],
        child: const CampusApp(),
      ),
    );
    // Проверяем каркас до завершения фоновых загрузок (заглушки с задержкой).
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);

    // Даём отработать таймерам заглушек, чтобы не осталось pending-таймеров.
    await tester.pump(const Duration(seconds: 1));
  });
}
