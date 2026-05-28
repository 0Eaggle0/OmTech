import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/student_record.dart';
import 'lk_grades_parser.dart';
import 'lk_session.dart';

/// Высокоуровневый сервис: ходит за HTML зачётки через [LkSession],
/// парсит её, кэширует JSON в SharedPreferences.
class LkGradesApi {
  static const _cacheKey = 'lk_grades_cache_v1';
  static const _cacheTimeKey = 'lk_grades_cache_time_v1';
  static const _route = 'student/index';

  final LkSession _session;

  LkGradesApi(this._session);

  /// Сначала отдаёт кэш (если есть), затем — свежие данные с сервера.
  /// Подписчик получит до двух уведомлений: cached, fresh.
  Stream<StudentRecord> watch({bool forceRefresh = false}) async* {
    if (!forceRefresh) {
      final cached = await readCache();
      if (cached != null) yield cached;
    }
    final fresh = await fetchFresh();
    yield fresh;
  }

  Future<StudentRecord> fetchFresh() async {
    final html = await _session.fetchHtml(_route);
    final record = parseStudentRecord(html);
    await _saveCache(record);
    return record;
  }

  Future<StudentRecord?> readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return StudentRecord.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> readCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_cacheTimeKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }

  Future<void> _saveCache(StudentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(record.toJson()));
    await prefs.setInt(
        _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
}
