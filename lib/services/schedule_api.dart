import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  final Dio _client;
  final ScheduleCache _cache;
  final Map<String, Future<String>> _inFlight = {};

  ScheduleApi({Dio? client, ScheduleCache? cache})
      : _client = client ?? Dio(),
        _cache = cache ?? ScheduleCache();

  /// Тело ответа всегда забираем байтами и декодим сами: API отдаёт UTF-8,
  /// но заголовок charset бывает пустым, и dio тогда гадает по-своему.
  /// [errorPrefix] попадает в текст исключения, видимый на экране ошибки.
  Future<String> _getText(Uri uri, Duration timeout, String errorPrefix) async {
    final res = await _client.getUri<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        validateStatus: (_) => true,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('$errorPrefix (${res.statusCode})');
    }
    return utf8.decode(res.data ?? const <int>[]);
  }

  // ─────────────────────────────── Поиск ─────────────────────────────────

  /// Поиск групп по части названия.
  Future<List<Group>> searchGroups(String term) async {
    final uri = Uri.https(_host, '/api/search', {'term': term, 'type': 'group'});
    final body = await _getText(
        uri, const Duration(seconds: 15), 'Ошибка поиска групп');
    final data = jsonDecode(body) as List<dynamic>;
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
    final body = await _getText(
        uri, const Duration(seconds: 15), 'Ошибка поиска ($type)');
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map((j) => ScheduleEntity.fromJson(j, entityType))
        .toList(growable: false);
  }

  /// Поиск сущностей одного типа в общем виде [ScheduleEntity].
  Future<List<ScheduleEntity>> searchByType(EntityType type, String term) =>
      switch (type) {
        EntityType.group => searchGroups(term).then((gs) => gs
            .map((g) => ScheduleEntity(
                  id: g.id,
                  label: g.label,
                  description: g.description,
                  type: EntityType.group,
                ))
            .toList()),
        EntityType.teacher => searchTeachers(term),
        EntityType.auditorium => searchAuditoriums(term),
      };

  /// Универсальный поиск: группы + преподаватели + аудитории одновременно.
  Future<List<ScheduleEntity>> universalSearch(String term) async {
    final results = await Future.wait([
      for (final type in EntityType.values)
        searchByType(type, term).catchError((_) => <ScheduleEntity>[]),
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
      // Разбор кэша тоже может упасть (битая запись) — тогда просто идём
      // в сеть, а не роняем весь стрим.
      List<ScheduleEvent>? cachedEvents;
      try {
        cachedEvents = parseRaw(cached.rawJson);
      } catch (_) {
        cachedEvents = null;
      }
      if (cachedEvents != null) {
        yield ScheduleSnapshot(
          events: cachedEvents,
          fetchedAt: cached.savedAt,
          fromCache: true,
        );
        servedCache = true;
        final age = DateTime.now().difference(cached.savedAt);
        if (!age.isNegative && age < _ttlFor(finish)) return;
      }
    }

    try {
      final raw = await _fetchRaw(type, id, start, finish, key);
      yield ScheduleSnapshot(events: parseRaw(raw), fetchedAt: DateTime.now());
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
      // Тело блоком, а не стрелкой: `_inFlight.remove` возвращает этот же
      // Future, и `whenComplete` стал бы ждать его завершения — то есть
      // самого себя. Запрос тогда не завершается никогда.
    }).whenComplete(() {
      _inFlight.remove(cacheKey);
    });

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
    return _getText(
        uri, const Duration(seconds: 20), 'Ошибка загрузки расписания');
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

  /// API повторяет одну и ту же пару отдельной строкой на каждый поток или
  /// группу — дубли склеиваем, а их группы собираем в одну карточку.
  @visibleForTesting
  static List<ScheduleEvent> parseRaw(String rawJson) {
    final indexByKey = <String, int>{};
    final events = <ScheduleEvent>[];
    for (final json in (jsonDecode(rawJson) as List<dynamic>)
        .whereType<Map<String, dynamic>>()) {
      final e = ScheduleEvent.fromJson(json);
      final key = [
        e.date.toIso8601String(),
        e.beginLesson,
        e.endLesson,
        e.discipline,
        e.lecturer,
        e.auditorium,
        e.building,
        e.kindOfWork,
        e.rawSubgroup,
      ].join('|');
      final existing = indexByKey[key];
      if (existing == null) {
        indexByKey[key] = events.length;
        events.add(e);
      } else {
        events[existing] = events[existing].withGroups(e.groups);
      }
    }
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
