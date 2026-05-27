import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group.dart';
import '../models/schedule_event.dart';

/// Клиент реального API расписания ОМГТУ (rasp.omgtu.ru).
class ScheduleApi {
  static const _host = 'rasp.omgtu.ru';

  final http.Client _client;
  ScheduleApi({http.Client? client}) : _client = client ?? http.Client();

  /// Поиск групп по части названия (например, «ИВТ-221»).
  Future<List<Group>> searchGroups(String term) async {
    final uri = Uri.https(_host, '/api/search', {
      'term': term,
      'type': 'group',
    });
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
