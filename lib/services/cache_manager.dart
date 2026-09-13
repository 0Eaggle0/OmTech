import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/lk_controller.dart';
import 'news_database.dart';
import 'schedule_cache.dart';
import 'search_history.dart';
import 'teacher_contacts_service.dart';

/// Подсчёт и очистка того, что приложение накопило на устройстве.
///
/// Осознанно НЕ трогает: логин и пароль в secure storage, cookies сессии,
/// выбранную группу и подгруппу, тему, язык, имя и аватар. Очистка кэша
/// не должна выкидывать пользователя из ЛК и сбрасывать его настройки.
class CacheManager {
  /// Префиксы ключей `SharedPreferences`, которые считаем кэшем.
  /// Дублируют приватные константы владельцев (`ScheduleCache`,
  /// `Lk*Api`, `SearchHistoryService`) — при переименовании там
  /// поправить и здесь, иначе размер будет занижен.
  static const _cachePrefixes = [
    'sched_v1|',
    'sched_index_v1',
    'lk_grades_cache',
    'lk_report_works_cache',
    'lk_work_',
    'search_recent_v1',
    TeacherContactsService.cachePrefix,
  ];

  /// Снимки для уведомлений: без них следующая проверка просто заново
  /// зафиксирует baseline и не станет спамить «новым» старьём.
  static const _snapshotKeys = [
    'notif_report_snapshot',
    'notif_grades_snapshot',
  ];

  final NewsDatabase newsDb;

  CacheManager({required this.newsDb});

  Future<int> totalSize() async {
    var total = 0;

    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!_isCacheKey(key)) continue;
      final value = prefs.get(key);
      if (value is String) total += value.length;
      if (value is List<String>) {
        total += value.fold<int>(0, (sum, s) => sum + s.length);
      }
    }

    total += await newsDb.fileSizeBytes();
    total += await _tempFilesSize();
    return total;
  }

  Future<void> clearAll(LkController lk) async {
    await ScheduleCache().clear();
    await lk.gradesApi.clearCache();
    await lk.contactWorkApi.clearCache();
    await lk.reportWorkApi.clearCache();
    await TeacherContactsService.clearCache();
    await newsDb.deleteAll();
    await SearchHistoryService().clearAll();

    final prefs = await SharedPreferences.getInstance();
    for (final key in _snapshotKeys) {
      await prefs.remove(key);
    }

    await _clearTempFiles();
  }

  static bool _isCacheKey(String key) =>
      _cachePrefixes.any((prefix) => key.startsWith(prefix));

  /// Скачанные из ЛК файлы лежат прямо в корне временной папки.
  /// Подкаталоги не трогаем — они принадлежат плагинам.
  Future<int> _tempFilesSize() async {
    try {
      final dir = await getTemporaryDirectory();
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _clearTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {
            // Файл может быть занят — пропускаем, очистка не должна падать.
          }
        }
      }
    } catch (_) {}
  }

  /// «1.2 MB» / «340 KB» — для подписи в настройках. Единицы латиницей:
  /// они одинаково читаются в обеих локалях и не требуют своих ключей.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
