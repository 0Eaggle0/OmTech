import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group.dart';
import '../models/schedule_entity.dart';
import '../models/schedule_event.dart';

/// Клиент реального API расписания ОМГТУ (rasp.omgtu.ru).
class ScheduleApi {
  static const _host = 'rasp.omgtu.ru';

  final http.Client _client;
  ScheduleApi({http.Client? client}) : _client = client ?? http.Client();

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

  /// Расписание группы за диапазон дат.
  Future<List<ScheduleEvent>> getSchedule(
    int groupId, {
    required DateTime start,
    required DateTime finish,
  }) async {
    final uri = Uri.https(_host, '/api/schedule/group/$groupId', {
      'start': _fmt(start),
      'finish': _fmt(finish),
      'lng': '1',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Ошибка загрузки расписания (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return _parseEvents(data);
  }

  Future<List<ScheduleEvent>> getTeacherSchedule(
    int id, {
    required DateTime start,
    required DateTime finish,
  }) =>
      _getEntitySchedule('lecturer', id, start: start, finish: finish);

  Future<List<ScheduleEvent>> getAuditoriumSchedule(
    int id, {
    required DateTime start,
    required DateTime finish,
  }) =>
      _getEntitySchedule('auditorium', id, start: start, finish: finish);

  Future<List<ScheduleEvent>> _getEntitySchedule(
    String type,
    int id, {
    required DateTime start,
    required DateTime finish,
  }) async {
    final uri = Uri.https(_host, '/api/schedule/$type/$id', {
      'start': _fmt(start),
      'finish': _fmt(finish),
      'lng': '1',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Ошибка загрузки расписания ($type): ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return _parseEvents(data);
  }

  static List<ScheduleEvent> _parseEvents(List<dynamic> data) {
    final events = data
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
