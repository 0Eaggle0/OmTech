import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contact_work.dart';
import 'lk_contact_work_parser.dart';
import 'lk_session.dart';

/// Высокоуровневый сервис раздела «Контактная работа».
/// Делает HTTP-запросы через [LkSession], парсит HTML и кэширует
/// JSON в SharedPreferences.
///
/// Два уровня данных:
///  1) список дисциплин — один кэш-ключ;
///  2) задания дисциплины — отдельный кэш-ключ по `disciplineId`.
class LkContactWorkApi {
  static const _cacheKey = 'lk_work_cache_v1';
  static const _cacheTimeKey = 'lk_work_cache_time_v1';
  static const _tasksCachePrefix = 'lk_work_tasks_';
  static const _tasksKeysIndex = 'lk_work_tasks_index_v1';
  static const _knownCountPrefix = 'lk_work_known_count_';
  static const _knownCountIndex = 'lk_work_known_count_index_v1';

  static const _routeDisciplines = 'remote/read';
  String _routeTasks(String id) => 'remote/read/taskList&discipline=$id&time=0';

  final LkSession _session;

  LkContactWorkApi(this._session);

  // ─────────────────────── disciplines ────────────────────────

  /// Сначала отдаёт кэш (если есть), затем — свежий список с сервера.
  Stream<List<WorkDiscipline>> watchDisciplines(
      {bool forceRefresh = false}) async* {
    if (!forceRefresh) {
      final cached = await readDisciplinesCache();
      if (cached != null) yield cached;
    }
    final fresh = await fetchDisciplinesFresh();
    yield fresh;
  }

  Future<List<WorkDiscipline>> fetchDisciplinesFresh() async {
    final html = await _session.fetchHtml(_routeDisciplines);
    final list = parseDisciplines(html);
    await _saveDisciplines(list);
    return list;
  }

  Future<List<WorkDiscipline>?> readDisciplinesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final arr = jsonDecode(raw) as List;
      return arr
          .whereType<Map>()
          .map((m) => WorkDiscipline.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> readCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_cacheTimeKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _saveDisciplines(List<WorkDiscipline> list) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(list.map((d) => d.toJson()).toList());
    await prefs.setString(_cacheKey, json);
    await prefs.setInt(
        _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ──────────────────────── tasks (lazy) ──────────────────────

  /// Сначала кэш заданий конкретной дисциплины, затем свежие.
  Stream<List<ContactWorkItem>> watchTasks(String disciplineId,
      {bool forceRefresh = false}) async* {
    if (!forceRefresh) {
      final cached = await readTasksCache(disciplineId);
      if (cached != null) yield cached;
    }
    final fresh = await fetchTasksFresh(disciplineId);
    yield fresh;
  }

  Future<List<ContactWorkItem>> fetchTasksFresh(String disciplineId) async {
    final html = await _session.fetchHtml(_routeTasks(disciplineId));
    final items = parseTasks(html);
    await _saveTasks(disciplineId, items);
    return items;
  }

  Future<List<ContactWorkItem>?> readTasksCache(String disciplineId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_tasksCachePrefix$disciplineId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final arr = jsonDecode(raw) as List;
      return arr
          .whereType<Map>()
          .map((m) => ContactWorkItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTasks(
      String disciplineId, List<ContactWorkItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString('$_tasksCachePrefix$disciplineId', json);

    // Регистрируем id в индексе, чтобы очистить всё при logout.
    final index = (prefs.getStringList(_tasksKeysIndex) ?? const []).toSet();
    index.add(disciplineId);
    await prefs.setStringList(_tasksKeysIndex, index.toList());
  }

  // ──────────────── known-count (badge «новых заданий») ─────────────

  /// Возвращает запомненное число заданий, которое пользователь «видел»
  /// в последний раз. `null` — если для этой дисциплины baseline ещё
  /// не зафиксирован.
  Future<int?> getKnownTaskCount(String disciplineId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_knownCountPrefix$disciplineId');
  }

  /// Фиксирует, что пользователь увидел задания этой дисциплины
  /// (вызываем при открытии экрана деталей и после успешной загрузки).
  Future<void> setKnownTaskCount(String disciplineId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_knownCountPrefix$disciplineId', count);
    final index = (prefs.getStringList(_knownCountIndex) ?? const []).toSet();
    index.add(disciplineId);
    await prefs.setStringList(_knownCountIndex, index.toList());
  }

  /// Считает число новых заданий с момента последнего просмотра.
  /// Если baseline для дисциплины ещё не задан — фиксирует текущее
  /// значение и возвращает 0 (чтобы при первом запуске не отображать
  /// все задания как «новые»).
  Future<int> calcNewCount(WorkDiscipline d) async {
    final id = d.id;
    if (id == null) return 0;
    final known = await getKnownTaskCount(id);
    if (known == null) {
      await setKnownTaskCount(id, d.taskCount);
      return 0;
    }
    final diff = d.taskCount - known;
    return diff > 0 ? diff : 0;
  }

  // ─────────────────────────── cache ──────────────────────────

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    final tasksIndex = prefs.getStringList(_tasksKeysIndex) ?? const [];
    for (final id in tasksIndex) {
      await prefs.remove('$_tasksCachePrefix$id');
    }
    await prefs.remove(_tasksKeysIndex);
    final knownIndex = prefs.getStringList(_knownCountIndex) ?? const [];
    for (final id in knownIndex) {
      await prefs.remove('$_knownCountPrefix$id');
    }
    await prefs.remove(_knownCountIndex);
  }
}
