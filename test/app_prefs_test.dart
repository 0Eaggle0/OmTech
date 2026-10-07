import 'package:campus2_0/services/app_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('переносит старые настройки, кроме кэша расписания, и чистит старые',
      () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'selected_subgroup': 2,
      'search_recent_v1': ['{"type":0}'],
      'sched_v1|group|6|2026-10-05|2026-10-11': '[]',
      'sched_index_v1': ['sched_v1|group|6|2026-10-05|2026-10-11'],
    });
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await migrateAppPrefs();

    expect(await appPrefs.getString('theme_mode'), 'dark');
    expect(await appPrefs.getInt('selected_subgroup'), 2);
    expect(await appPrefs.getStringList('search_recent_v1'), ['{"type":0}']);
    expect(await appPrefs.containsKey('sched_index_v1'), isFalse);
    expect(
      (await appPrefs.getKeys()).where((k) => k.startsWith('sched_v1|')),
      isEmpty,
    );

    final legacy = await SharedPreferences.getInstance();
    expect(legacy.getKeys(), isEmpty);

    // Повторный вызов ничего не ломает и не переносит заново.
    await appPrefs.setString('theme_mode', 'light');
    await migrateAppPrefs();
    expect(await appPrefs.getString('theme_mode'), 'light');
  });
}
