import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'lk/lk_credentials_storage.dart';
import 'lk/lk_session.dart';
import 'notification_service.dart';

/// Имя задачи осталось с часовых времён: по нему WorkManager находит уже
/// зарегистрированную задачу и обновляет её, а не заводит вторую.
const String lkCheckTask = 'campus_hourly_check';

/// Как часто фон проверяет ЛК. Android может сдвигать запуск (Doze).
const Duration backgroundCheckInterval = Duration(minutes: 30);

/// Метка последней активности UI-изолята.
const String _uiHeartbeatKey = 'ui_heartbeat_ms';

/// Время и итог последнего прогона фоновой проверки — для экрана настроек
/// и отчёта об ошибке: иначе не понять, запускает ли система воркер вообще.
const String bgLastRunKey = 'bg_last_run_ms';
const String bgLastResultKey = 'bg_last_result';

/// Пока приложение открыто, воркер не лезет в сеть: оба изолята пишут в одну
/// папку cookies, и параллельный логин затирает сессию UI.
const Duration _uiActiveWindow = Duration(minutes: 2);

/// Вызывается из UI-изолята при старте, при возврате на экран и раз в минуту,
/// пока приложение открыто.
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
    WidgetsFlutterBinding.ensureInitialized();
    final result = await _runChecks();
    debugPrint('[BG] проверка ЛК: $result');
    await _recordRun(result);
    return true;
  });
}

/// Итог прогона: ok / ui_active / no_creds / auth_failed / network / error.
Future<String> _runChecks() async {
  try {
    if (await _uiRecentlyActive()) return 'ui_active';

    final storage = LkCredentialsStorage();
    if (await storage.read() == null) return 'no_creds';

    await NotificationService.instance.init();
    final session = await LkSession.create(credentials: storage.read);

    // Сначала пробуем доехать с уже сохранёнными cookies — это бесплатно.
    // Протухшую сессию дальше восстановит сама LkSession на первом запросе,
    // но если сеть недоступна, нет смысла дёргать три страницы впустую.
    final check = await session.checkSession();
    if (check == SessionCheck.unknown) return 'network';
    if (check == SessionCheck.invalid) {
      try {
        if (!await session.reauthenticate()) return 'no_creds';
      } on LkLoginException catch (e) {
        return e.result == LkLoginResult.invalidCredentials
            ? 'auth_failed'
            : 'network';
      }
    }

    await NotificationService.instance.runBackgroundChecks(session);
    return 'ok';
  } catch (e) {
    // Любая ошибка в фоне — best-effort, не падаем.
    debugPrint('[BG] ошибка: $e');
    return 'error';
  }
}

Future<void> _recordRun(String result) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bgLastRunKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(bgLastResultKey, result);
  } catch (_) {}
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
