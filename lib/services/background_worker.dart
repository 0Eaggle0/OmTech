import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'lk/lk_credentials_storage.dart';
import 'lk/lk_session.dart';
import 'notification_service.dart';

const String hourlyCheckTask = 'campus_hourly_check';

/// Метка последней активности UI-изолята.
const String _uiHeartbeatKey = 'ui_heartbeat_ms';

/// Пока приложение открыто, воркер не лезет в сеть: оба изолята пишут в одну
/// папку cookies, и параллельный логин затирает сессию UI.
const Duration _uiActiveWindow = Duration(minutes: 2);

/// Вызывается из UI-изолята при старте и при возврате приложения на экран.
Future<void> markUiActive() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_uiHeartbeatKey, DateTime.now().millisecondsSinceEpoch);
  } catch (_) {
    // Не критично: воркер просто отработает как обычно.
  }
}

/// Точка входа в изолят WorkManager. Должна быть top-level и помечена
/// `@pragma('vm:entry-point')`, иначе AOT-компилятор её выпиливает.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      if (await _uiRecentlyActive()) return true;

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

Future<bool> _uiRecentlyActive() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_uiHeartbeatKey);
    if (ms == null) return false;
    final since =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    return !since.isNegative && since < _uiActiveWindow;
  } catch (_) {
    return false;
  }
}
