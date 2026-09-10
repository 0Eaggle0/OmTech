import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group.dart';
import '../models/schedule_entity.dart';
import '../models/schedule_event.dart';
import 'schedule_cache.dart';

/// Расписание вместе с отметкой о том, откуда оно взялось.
class ScheduleSnapshot {
  final List<ScheduleEvent> events;
  final DateTime? fetchedAt;

  /// true — данные из кэша, свежие ещё едут (или сеть недоступна).
  final bool fromCache;

  const ScheduleSnapshot({
    required this.events,
    this.fetchedAt,
    this.fromCache = false,
  });
}

/// Клиент реального API расписания ОМГТУ (rasp.omgtu.ru).
class ScheduleApi {
  static const _host = 'rasp.omgtu.ru';

  /// Общий экземпляр: держит один http-клиент, общий кэш и общий список
  /// запросов «в полёте», поэтому главный экран и расписание не дублируют сеть.
  static final ScheduleApi instance = ScheduleApi();

  static const _freshTtl = Duration(minutes: 30);
  static const _pastTtl = Duration(hours: 12);

  final http.Client _client;
  final ScheduleCache _cache;
  final Map<String, Future<String>> _inFlight = {};

  ScheduleApi({http.Client? client, ScheduleCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? ScheduleCache();

  // ─────────────────────────────── Поиск ─────────────────────────────────

  /// Поиск групп по части названия.
  Future<List<Group>> searchGroups(String term) async {
    final uri = Uri.https(_host, '/api/search', {'term': term, 'type': 'group'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Ошибка поиска групп (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(Group.fromJson)
        .toList(growable: false);
  }

  Future<List<ScheduleEntity>> searchTeachers(String term) =>
      _searchEntities(term, 'lecturer', EntityType.teacher);

  Future<List<ScheduleEntity>> searchAuditoriums(String term) =>
      _searchEntities(term, 'auditorium', EntityType.auditorium);

  Future<List<ScheduleEntity>> _searchEntities(
    String term,
    String type,
    EntityType entityType,
  ) async {
    final uri = Uri.https(_host, '/api/search', {'term': term, 'type': type});
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Ошибка поиска ($type): ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map((j) => ScheduleEntity.fromJson(j, entityType))
        .toList(growable: false);
  }

  /// Универсальный поиск: группы + преподаватели + аудитории одновременно.
  Future<List<ScheduleEntity>> universalSearch(String term) async {
    final results = await Future.wait([
      searchGroups(term)
          .then((gs) => gs
              .map((g) => ScheduleEntity(
                    id: g.id,
                    label: g.label,
                    description: g.description,
                    type: EntityType.group,
                  ))
              .toList())
          .catchError((_) => <ScheduleEntity>[]),
      searchTeachers(term).catchError((_) => <ScheduleEntity>[]),
      searchAuditoriums(term).catchError((_) => <ScheduleEntity>[]),
    ]);
    final seen = <String>{};
    return results
        .expand((x) => x)
        .where((e) => seen.add('${e.type}|${e.label}|${e.description}'))
        .toList();
  }

  // ───────────────────────────── Расписание ──────────────────────────────

  /// Расписание за диапазон дат: сначала кэш, затем свежие данные из сети.
  ///
  /// Кэш отдаётся сразу, даже просроченный, чтобы экран не мигал спиннером.
  /// Если кэш свежий (см. TTL) — сеть не трогаем вовсе. Если сеть упала, а
  /// кэш был показан, стрим просто закрывается без ошибки.
  Stream<ScheduleSnapshot> watchSchedule({
    required EntityType type,
    required int id,
    required DateTime start,
    required DateTime finish,
  }) async* {
    final key = ScheduleCache.keyFor(type, id, start, finish);
    final cached = await _cache.read(key);
    var servedCache = false;

    if (cached != null) {
      yield ScheduleSnapshot(
        events: _parseRaw(cached.rawJson),
        fetchedAt: cached.savedAt,
        fromCache: true,
      );
      servedCache = true;
      final age = DateTime.now().difference(cached.savedAt);
      if (!age.isNegative && age < _ttlFor(finish)) return;
    }

    try {
      final raw = await _fetchRaw(type, id, start, finish, key);
      yield ScheduleSnapshot(events: _parseRaw(raw), fetchedAt: DateTime.now());
    } catch (_) {
      // Кэш на экране уже есть — молчим и живём на нём.
      if (!servedCache) rethrow;
    }
  }

  /// Сеть с дедупликацией: пока запрос за тем же ключом в полёте,
  /// второй вызов подписывается на тот же Future.
  Future<String> _fetchRaw(
    EntityType type,
    int id,
    DateTime start,
    DateTime finish,
    String cacheKey,
  ) {
    final existing = _inFlight[cacheKey];
    if (existing != null) return existing;

    final future = _requestRaw(type, id, start, finish).then((raw) async {
      await _cache.write(cacheKey, raw);
      return raw;
    }).whenComplete(() => _inFlight.remove(cacheKey));

    _inFlight[cacheKey] = future;
    return future;
  }

  Future<String> _requestRaw(
    EntityType type,
    int id,
    DateTime start,
    DateTime finish,
  ) async {
    final uri = Uri.https(_host, '/api/schedule/${_apiType(type)}/$id', {
      'start': _fmt(start),
      'finish': _fmt(finish),
      'lng': '1',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Ошибка загрузки расписания (${res.statusCode})');
    }
    return utf8.decode(res.bodyBytes);
  }

  static String _apiType(EntityType type) => switch (type) {
        EntityType.group => 'group',
        EntityType.teacher => 'lecturer',
        EntityType.auditorium => 'auditorium',
      };

  /// Прошедшие недели меняются редко — их кэш живёт дольше.
  static Duration _ttlFor(DateTime finish) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeEnd = DateTime(finish.year, finish.month, finish.day);
    return rangeEnd.isBefore(today) ? _pastTtl : _freshTtl;
  }

  static List<ScheduleEvent> _parseRaw(String rawJson) {
    final events = (jsonDecode(rawJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScheduleEvent.fromJson)
        .toList();
    events.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.beginLesson.compareTo(b.beginLesson);
    });
    return events;
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
