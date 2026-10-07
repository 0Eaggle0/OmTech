import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

import 'schedule_cache.dart';

/// Настройки и кэши приложения.
///
/// [SharedPreferencesAsync] читает с диска при каждом обращении, без копии
/// в памяти. Старый `SharedPreferences` держал такую копию в каждом изоляте,
/// и UI не видел, что записал фоновый воркер (и наоборот), пока не позовёт
/// `reload()`. Теперь оба изолята всегда видят одно и то же.
final SharedPreferencesAsync appPrefs = SharedPreferencesAsync();

const _migratedKey = 'prefs_async_migrated_v1';

Future<void>? _migration;

/// Однократный перенос данных из старого `SharedPreferences`. Вызывается до
/// первого обращения к [appPrefs] — в `main()` и в фоновом воркере.
Future<void> migrateAppPrefs() => _migration ??= _migrate();

Future<void> _migrate() async {
  try {
    if (await appPrefs.containsKey(_migratedKey)) return;
    final legacy = await SharedPreferences.getInstance();
    // Кэш расписания переехал в файлы — тащить его в новое хранилище незачем.
    for (final key in legacy.getKeys().toList()) {
      if (ScheduleCache.legacyPrefsPrefixes.any(key.startsWith)) {
        await legacy.remove(key);
      }
    }
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacy,
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: _migratedKey,
    );
    // Старое хранилище больше не читается — освобождаем место и память.
    await legacy.clear();
    debugPrint('[Prefs] перенос в SharedPreferencesAsync: ok');
  } catch (e) {
    // Не перенеслось — следующий запуск попробует снова (метка не стоит).
    _migration = null;
    debugPrint('[Prefs] перенос не удался: $e');
  }
}
