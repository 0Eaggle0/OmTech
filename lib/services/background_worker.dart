import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'lk/lk_credentials_storage.dart';
import 'lk/lk_session.dart';
import 'notification_service.dart';

const String hourlyCheckTask = 'campus_hourly_check';

/// Точка входа в изолят WorkManager. Должна быть top-level и помечена
/// `@pragma('vm:entry-point')`, иначе AOT-компилятор её выпиливает.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.instance.init();

      final session = await LkSession.create();

      // Сначала пробуем доехать с уже сохранёнными cookies — это бесплатно.
      var authed = await session.isAuthenticated();
      if (!authed) {
        final creds = await LkCredentialsStorage().read();
        if (creds == null) return true;
        try {
          await session.login(creds.username, creds.password);
          authed = true;
        } catch (_) {
          return true;
        }
      }
      if (!authed) return true;

      await NotificationService.instance.runBackgroundChecks(session);
    } catch (_) {
      // Любая ошибка в фоне — best-effort, не падаем.
    }
    return true;
  });
}
