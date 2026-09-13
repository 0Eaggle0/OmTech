import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contact_work.dart';
import '../../models/report_work.dart';
import 'lk_report_work_parser.dart';
import 'lk_session.dart';

/// Сайт отклонил действие с отчётной работой (загрузку, удаление).
/// [serverMessage] — ответ сервера как есть (он уже человеческий);
/// `null` — причина не из ответа сервера.
class ReportSiteException implements Exception {
  final String? serverMessage;

  const ReportSiteException([this.serverMessage]);

  @override
  String toString() => 'ReportSiteException(${serverMessage ?? '-'})';
}

/// Страница существующей «прочей» работы (`otherpage.php`).
class OtherWorkPage {
  final List<WorkFile> files;

  /// Аргумент кнопки `otherdel('…')`. `null` — кнопки удаления на странице
  /// нет, и приложение удалить работу тоже не предлагает.
  final String? deleteId;

  const OtherWorkPage({required this.files, required this.deleteId});
}

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
  static const _otherPagePath = 'modules/vkr2/otherpage.php';
  static const _uploadPath = 'modules/vkr2/otherupl.php';
  static const _deletePath = 'modules/vkr2/otherdel.php';

  /// Ограничение формы на сайте: «в формате PDF, не более 10 мегабайт».
  static const maxUploadBytes = 10 * 1024 * 1024;

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
    await _saveHtmlDump('vkr2_shell', shellHtml);
    final year = detectActiveYear(html_parser.parse(shellHtml)) ??
        _currentAcademicYearStart();

    // 2) Прочие работы — простой GET.
    final othersHtml = await _session.fetchEcabHtml(_otherListPath);
    await _saveHtmlDump('otherlist', othersHtml);
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

  /// Страница «прочей» работы по её [fileId]/[fnpp]: файлы и id для удаления.
  /// Парсит модальную страницу `modules/vkr2/otherpage.php`, которая на
  /// сайте подгружается через POST `{fileid, fnpp}` (см. `getotherpage()`
  /// в `vkr2.php`). Если передать только id через GET — сервер вернёт
  /// форму создания новой работы, а не страницу существующей.
  ///
  /// Параллельно сохраняет сырой HTML во временный файл (см. [lastDumpPath]).
  Future<OtherWorkPage> fetchOtherWorkPage(String fileId, {String fnpp = ''}) async {
    if (fileId.isEmpty) return const OtherWorkPage(files: [], deleteId: null);
    final html = await _session.postEcabForm(
      _otherPagePath,
      {'fileid': fileId, 'fnpp': fnpp},
    );
    await _saveHtmlDump(fileId, html);
    final doc = html_parser.parse(html);
    final files = <WorkFile>[];
    final seen = <String>{};

    void addFile(String name, String url, String type) {
      if (url.isEmpty) return;
      if (!seen.add(url)) return;
      files.add(WorkFile(name: name.trim().isEmpty ? url.split('/').last : name.trim(), url: url, type: type));
    }

    String absolutize(String href) {
      if (href.startsWith('http')) return href;
      return 'https://omgtu.ru${href.startsWith('/') ? '' : '/ecab/'}$href';
    }

    String typeOf(String url) {
      final lower = url.toLowerCase();
      if (lower.contains('.pdf')) return 'pdf';
      if (lower.contains('.pptx') || lower.contains('.ppt')) return 'pptx';
      if (lower.contains('.docx') || lower.contains('.doc')) return 'docx';
      if (lower.contains('.xlsx') || lower.contains('.xls')) return 'xlsx';
      if (lower.contains('.zip') || lower.contains('.rar') || lower.contains('.7z')) return 'zip';
      if (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg')) return 'image';
      return 'link';
    }

    // 1) Прямые <a href="..."> на файлы.
    //    Реальная страница otherpage.php отдаёт ссылку вида
    //    `/ecab/modules/vkr2/getf.php?id=<fileId>` (без расширения файла
    //    в URL) — её ловим по `getf.php` и `modules/vkr2/get`.
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      final lower = href.toLowerCase();
      final looksLikeFile = lower.contains('/files/') ||
          lower.contains('download') ||
          lower.contains('getf.php') ||
          lower.contains('getfile') ||
          lower.contains('modules/vkr2/get') ||
          lower.contains('.pdf') ||
          lower.contains('.doc') ||
          lower.contains('.docx') ||
          lower.contains('.xls') ||
          lower.contains('.xlsx') ||
          lower.contains('.ppt') ||
          lower.contains('.pptx') ||
          lower.contains('.zip') ||
          lower.contains('.rar') ||
          lower.contains('.7z') ||
          lower.contains('.png') ||
          lower.contains('.jpg') ||
          lower.contains('.jpeg') ||
          lower.contains('.txt') ||
          lower.contains('.rtf');
      if (!looksLikeFile) continue;
      final url = absolutize(href);
      // Тип берём из имени файла в `<a>` (например, «ЛР 3.pdf»),
      // т.к. URL вида `getf.php?id=...` расширения не содержит.
      final displayName = a.text.trim();
      addFile(displayName, url, typeOf(displayName.isEmpty ? url : displayName));
    }

    // 2) onclick-обработчики вида getotherfile('id') / downloadFile('id').
    // На сайте список работ открывается через onclick="getotherpage('id')",
    // а файлы внутри модалки, по аналогии, скорее всего идут через
    // onclick="getotherfile('id')" → modules/vkr2/getotherfile.php?id=<id>.
    for (final el in doc.querySelectorAll('[onclick]')) {
      final onclick = el.attributes['onclick'] ?? '';
      final m = RegExp(
        r"""(getotherfile|getfile|downloadFile|downloadfile|getotherattach|getotherdoc)\(\s*['"]([^'"]+)['"]""",
      ).firstMatch(onclick);
      if (m == null) continue;
      final fn = m.group(1)!;
      final id = m.group(2)!;
      final url = 'https://omgtu.ru/ecab/modules/vkr2/$fn.php?id=$id';
      final name = el.text.trim();
      addFile(name.isEmpty ? id : name, url, typeOf(name.isEmpty ? id : name));
    }

    // 3) iframe/embed/object со ссылками на файлы.
    for (final el in doc.querySelectorAll('iframe[src], embed[src], object[data]')) {
      final src = el.attributes['src'] ?? el.attributes['data'] ?? '';
      if (src.isEmpty) continue;
      final lower = src.toLowerCase();
      if (!lower.contains('.pdf') &&
          !lower.contains('.doc') &&
          !lower.contains('/files/') &&
          !lower.contains('download')) {
        continue;
      }
      final url = absolutize(src);
      addFile(src.split('/').last.split('?').first, url, typeOf(url));
    }

    return OtherWorkPage(files: files, deleteId: parseOtherDeleteId(doc));
  }

  // ─────────────────────── загрузка новой работы ───────────────────────

  /// «Номер портфолио» студента (`fnpp`) нужен форме загрузки. Он одинаков
  /// у всех работ, поэтому берём его из кэша, а если работ ещё нет — из
  /// вызовов `getotherpage('…','<fnpp>')` на страницах раздела.
  Future<String> resolveFnpp() async {
    final cached = await readCache();
    for (final w in cached?.otherWorks ?? const <ReportWork>[]) {
      if (w.fnpp.isNotEmpty) return w.fnpp;
    }
    final re = RegExp(r"""getotherpage\(\s*['"][^'"]*['"]\s*,\s*['"](\d+)['"]""");
    for (final path in [_otherListPath, _shellPath]) {
      final m = re.firstMatch(await _session.fetchEcabHtml(path));
      if (m != null) return m.group(1)!;
    }
    debugPrint('[Reports] fnpp не найден ни в кэше, ни на страницах');
    throw const ReportSiteException();
  }

  /// Дисциплины, в которые можно загрузить «прочую» работу. Это форма
  /// `otherpage.php` с `fileid=0` — та же, что открывается на сайте.
  Future<List<ReportUploadDiscipline>> fetchUploadDisciplines() async {
    final fnpp = await resolveFnpp();
    final html = await _session.postEcabForm(
      _otherPagePath,
      {'fileid': '0', 'fnpp': fnpp},
    );
    await _saveHtmlDump('upload_form', html);
    final list = parseUploadDisciplines(html_parser.parse(html));
    if (list.isEmpty) {
      debugPrint('[Reports] в форме загрузки нет дисциплин (${html.length} симв.)');
    }
    return list;
  }

  /// Загружает PDF в «Прочие работы». Поля — как у `FormData` в скрипте
  /// формы на сайте: `file`, `dischexnrec`, `itext`, `semester`. Сервер
  /// отвечает ровно `ok`, иначе — текстом ошибки.
  Future<void> uploadOtherWork({
    required ReportUploadDiscipline discipline,
    required String title,
    required String filePath,
    String? fileName,
    ProgressCallback? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName ?? p.basename(filePath),
        contentType: DioMediaType('application', 'pdf'),
      ),
      'dischexnrec': discipline.hexnrec,
      'itext': title,
      'semester': discipline.semester,
    });
    final body = await _session.postEcabMultipart(
      _uploadPath,
      form,
      onSendProgress: onProgress,
    );
    await _saveHtmlDump('upload_result', body);

    final answer = body.trim();
    if (_isOk(answer)) return;
    final text = html_parser.parseFragment(answer).text?.trim() ?? '';
    debugPrint('[Reports] загрузка отклонена: ${text.isEmpty ? '(пусто)' : text}');
    throw ReportSiteException(text.isEmpty ? null : text);
  }

  /// Удаляет «прочую» работу так же, как кнопка на сайте: POST `otherdel.php`
  /// с `del=<id>`. Сервер отвечает `ok` или текстом ошибки.
  Future<void> deleteOtherWork(String deleteId) async {
    final body = await _session.postEcabForm(_deletePath, {'del': deleteId});
    final answer = body.trim();
    if (_isOk(answer)) {
      debugPrint('[Reports] работа $deleteId удалена');
      return;
    }
    final text = html_parser.parseFragment(answer).text?.trim() ?? '';
    debugPrint('[Reports] удаление отклонено: ${text.isEmpty ? '(пусто)' : text}');
    throw ReportSiteException(text.isEmpty ? null : text);
  }

  /// Ответ AJAX-эндпоинтов vkr2 — ровно `ok`. Короткий хвост перед ним —
  /// возможный BOM, прочитанный как cp1251.
  static bool _isOk(String answer) =>
      answer == 'ok' || (answer.length <= 6 && answer.endsWith('ok'));

  /// Путь к сохранённому дампу HTML страницы otherpage.php для [fileId].
  /// Возвращает `null`, если дамп ещё не сохранён.
  Future<String?> lastDumpPath(String fileId) async {
    if (fileId.isEmpty) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}otherpage_$fileId.html';
    final f = File(path);
    if (!await f.exists()) return null;
    return path;
  }

  Future<void> _saveHtmlDump(String fileId, String html) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}${Platform.pathSeparator}otherpage_$fileId.html';
      await File(path).writeAsString(html, flush: true);
    } catch (_) {
      // Дамп — best-effort; если упало — это не должно ломать загрузку файлов.
    }
  }
}
