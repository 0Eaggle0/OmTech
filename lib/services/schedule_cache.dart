import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/schedule_entity.dart';

class CachedSchedule {
  final String rawJson;
  final DateTime savedAt;

  const CachedSchedule({required this.rawJson, required this.savedAt});
}

/// Кэш ответов API расписания — по файлу на запрос в `<appSupport>/schedule/`.
///
/// Храним СЫРОЕ тело ответа: у [ScheduleEvent] есть только `fromJson`, и он
/// уже умеет читать формат API — отдельная сериализация модели не нужна.
/// Раньше кэш жил в SharedPreferences, но неделя аудитории весит до 75 КБ,
/// и 40 таких записей грузились в память целиком при каждом запуске.
/// Время сохранения — mtime файла.
class ScheduleCache {
  static const _maxEntries = 40;

  /// Старые ключи в SharedPreferences — их удаляет миграция prefs.
  static const legacyPrefsPrefixes = ['sched_v1|', 'sched_index_v1'];

  final Future<Directory> Function() _dir;

  ScheduleCache({Future<Directory> Function()? dir})
      : _dir = dir ?? _defaultDir;

  static Future<Directory> _defaultDir() async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'schedule'));

  static String keyFor(
    EntityType type,
    int id,
    DateTime start,
    DateTime finish,
  ) =>
      '${type.name}_${id}_${_day(start)}_${_day(finish)}';

  Future<File> _file(String key) async => File(p.join((await _dir()).path, '$key.json'));

  /// Битый или недоступный кэш — не ошибка: просто идём в сеть.
  Future<CachedSchedule?> read(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return CachedSchedule(rawJson: raw, savedAt: await file.lastModified());
    } catch (e) {
      debugPrint('[ScheduleCache] чтение $key: $e');
      return null;
    }
  }

  /// Пишет через временный файл и rename: UI и фоновый изолят могут
  /// писать одну неделю одновременно, и читатель не должен увидеть половину.
  Future<void> write(String key, String rawJson) async {
    try {
      final file = await _file(key);
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
      await tmp.writeAsString(rawJson, flush: true);
      await tmp.rename(file.path);
      await _evict(file.parent);
    } catch (e) {
      debugPrint('[ScheduleCache] запись $key: $e');
    }
  }

  /// Оставляет [_maxEntries] самых свежих записей.
  Future<void> _evict(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    if (files.length <= _maxEntries) return;
    final dated = [
      for (final f in files) (f, await f.lastModified()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (file, _) in dated.take(dated.length - _maxEntries)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  Future<int> sizeBytes() async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final e in dir.list()) {
        if (e is File) total += await e.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clear() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
