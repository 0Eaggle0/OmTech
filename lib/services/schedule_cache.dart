import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_entity.dart';

class CachedSchedule {
  final String rawJson;
  final DateTime savedAt;

  const CachedSchedule({required this.rawJson, required this.savedAt});
}

/// Кэш ответов API расписания в SharedPreferences.
///
/// Храним СЫРОЕ тело ответа: у [ScheduleEvent] есть только `fromJson`, и он
/// уже умеет читать формат API — отдельная сериализация модели не нужна.
/// Неделя занимает 10-20 КБ, поэтому prefs достаточно, sqlite тут избыточен.
class ScheduleCache {
  static const _prefix = 'sched_v1';
  static const _indexKey = 'sched_index_v1';
  static const _maxEntries = 40;

  static String keyFor(
    EntityType type,
    int id,
    DateTime start,
    DateTime finish,
  ) =>
      '$_prefix|${type.name}|$id|${_day(start)}|${_day(finish)}';

  Future<CachedSchedule?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final ms = prefs.getInt('$key|at');
    if (raw == null || raw.isEmpty || ms == null) return null;
    return CachedSchedule(
      rawJson: raw,
      savedAt: DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  Future<void> write(String key, String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, rawJson);
    await prefs.setInt('$key|at', DateTime.now().millisecondsSinceEpoch);
    await _touchIndex(prefs, key);
  }

  /// Держит индекс ключей и выбрасывает самые старые записи.
  Future<void> _touchIndex(SharedPreferences prefs, String key) async {
    final index = prefs.getStringList(_indexKey) ?? <String>[];
    index
      ..remove(key)
      ..add(key);
    while (index.length > _maxEntries) {
      final stale = index.removeAt(0);
      await prefs.remove(stale);
      await prefs.remove('$stale|at');
    }
    await prefs.setStringList(_indexKey, index);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getStringList(_indexKey) ?? const <String>[]) {
      await prefs.remove(key);
      await prefs.remove('$key|at');
    }
    await prefs.remove(_indexKey);
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
