import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/report_work.dart';
import 'lk_report_work_parser.dart';
import 'lk_session.dart';

/// API раздела «Загрузка отчётных работ студентов».
///
/// На сайте omgtu.ru/ecab/vkr2.php содержимое секций («Курсовые работы»
/// и «Прочие работы») не приходит в HTML страницы — они подгружаются
/// отдельными AJAX-запросами на эндпоинты `modules/vkr2/works.php` и
/// `modules/vkr2/otherlist.php`. Поэтому здесь делаем три запроса:
///   1) shell `vkr2.php` — чтобы узнать активный учебный год;
///   2) GET `modules/vkr2/otherlist.php` — «Прочие работы» (за все годы);
///   3) POST `modules/vkr2/works.php` с year=YYYY — «Курсовые работы»
///      выбранного учебного года.
///
/// Все ответы в windows-1251. Декод и анти-«сессия истекла» уже сделаны
/// в [LkSession].
class LkReportWorkApi {
  static const _cacheKey = 'lk_report_works_cache_v1';
  static const _cacheTimeKey = 'lk_report_works_cache_time_v1';

  static const _shellPath = 'vkr2.php';
  static const _otherListPath = 'modules/vkr2/otherlist.php';
  static const _worksPath = 'modules/vkr2/works.php';

  final LkSession _session;

  LkReportWorkApi(this._session);

  /// Стрим, отдающий сначала кэш (если есть), затем свежий результат.
  Stream<ReportWorksResult> watch({bool forceRefresh = false}) async* {
    if (!forceRefresh) {
      final cached = await readCache();
      if (cached != null) yield cached;
    }
    final fresh = await fetchFresh();
    yield fresh;
  }

  Future<ReportWorksResult> fetchFresh() async {
    // 1) shell: тянем основную страницу, чтобы вытащить активный учебный год.
    final shellHtml = await _session.fetchEcabHtml(_shellPath);
    final year = detectActiveYear(html_parser.parse(shellHtml)) ??
        _currentAcademicYearStart();

    // 2) Прочие работы — простой GET.
    final othersHtml = await _session.fetchEcabHtml(_otherListPath);
    final others = parseOtherWorks(html_parser.parse(othersHtml));

    // 3) Курсовые работы — POST `year=YYYY` (как делает jQuery .load
    // на сайте). Если упадёт — не валим всю загрузку, отдадим то, что есть.
    List<ReportCourseWork> courses = const [];
    try {
      final coursesHtml = await _session.postEcabForm(
        _worksPath,
        {'year': '$year'},
      );
      courses = parseCourseWorks(html_parser.parse(coursesHtml));
    } catch (_) {
      // ignore — не критично, остальные данные уже есть.
    }

    final result = ReportWorksResult(
      courseWorks: courses,
      otherWorks: others,
      academicYear: year,
    );
    await _save(result);
    return result;
  }

  /// Грубая эвристика: учебный год начинается в сентябре. До сентября мы
  /// ещё в году N-1/N, после — в N/N+1.
  int _currentAcademicYearStart() {
    final now = DateTime.now();
    return now.month >= 9 ? now.year : now.year - 1;
  }

  Future<ReportWorksResult?> readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReportWorksResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> readCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_cacheTimeKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _save(ReportWorksResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }
}
