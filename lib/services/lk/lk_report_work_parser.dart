import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/report_work.dart';

/// Парсер страницы https://omgtu.ru/ecab/vkr2.php — список загруженных
/// студентом отчётных работ.
///
/// Чистый разбор HTML — никакого I/O.
ReportWorksResult parseReportWorks(String html) {
  final doc = html_parser.parse(html);
  return ReportWorksResult(
    courseWorks: parseCourseWorks(doc),
    otherWorks: parseOtherWorks(doc),
    academicYear: detectActiveYear(doc),
  );
}

// ───────────────────────── курсовые ─────────────────────────

/// Курсовые работы (секция «Курсовые работы») — для активного учебного года.
/// Берём `tbody > tr` под заголовком «Курсовые работы».
List<ReportCourseWork> parseCourseWorks(Document doc) {
  // Заголовок секции — div с текстом «Курсовые работы».
  Element? header;
  for (final el in doc.querySelectorAll('div')) {
    final t = _textOneLine(el);
    if (t == 'Курсовые работы') {
      header = el;
      break;
    }
  }
  if (header == null) return const [];

  // Идём вверх и ищем следующий после header `<table>`.
  Element? table;
  Element? cur = header;
  while (cur != null) {
    final next = _nextSibling(cur);
    if (next == null) {
      cur = cur.parent;
      continue;
    }
    final t = next.localName == 'table'
        ? next
        : next.querySelector('table');
    if (t != null) {
      table = t;
      break;
    }
    cur = next;
  }
  if (table == null) return const [];

  final result = <ReportCourseWork>[];
  for (final tr in table.querySelectorAll('tr.altr')) {
    final tds = tr.children.where((c) => c.localName == 'td').toList();
    if (tds.length < 3) continue;

    final hexnrec =
        _extractCallId(tr, 'getvkrpage') ?? _stripTrPrefix(tr.id);
    if (hexnrec == null || hexnrec.isEmpty) continue;

    final group = _textOneLine(tds[0]);
    final student = _textOneLine(tds[1]);

    // td[2]: <span italic>тип</span><br>название
    final typeSpan = tds[2].querySelector('span');
    final workType = typeSpan != null ? _textOneLine(typeSpan) : '';
    final title = _afterBreakText(tds[2]);

    result.add(ReportCourseWork(
      hexnrec: hexnrec,
      groupName: group,
      studentName: student,
      workType: workType,
      title: title,
    ));
  }
  return result;
}

// ───────────────────────── прочие ─────────────────────────

/// «Прочие работы» (за все годы) — таблица внутри `#othercont`.
/// Если контейнера нет, делаем фолбэк на любой `tr.altr` с onclick getotherpage.
List<ReportWork> parseOtherWorks(Document doc) {
  // Контейнер может быть вложен глубоко; ищем все строки с onclick=getotherpage,
  // это надёжнее, чем привязываться к id контейнера (на сайте `#othercont`
  // встречается и как пустой контейнер, и как заполненный).
  final rows = doc
      .querySelectorAll('tr.altr')
      .where((tr) => _hasInlineCall(tr, 'getotherpage'))
      .toList();
  if (rows.isEmpty) return const [];

  final result = <ReportWork>[];
  for (final tr in rows) {
    final tds = tr.children.where((c) => c.localName == 'td').toList();
    if (tds.length < 2) continue;

    final ids = _extractCallArgs(tr, 'getotherpage', count: 2);
    if (ids.isEmpty || ids[0].isEmpty) continue;
    final fileId = ids[0];
    final fnpp = ids.length > 1 ? ids[1] : '';

    final date = _parseDdMmYyyy(_textOneLine(tds[0]));

    // td[1] устроен так:
    //   <span style="font-style: italic; font-size: 80%;">
    //       {Дисциплина}    ({N} сем.) № {WorkNumber}
    //   </span>
    //   <br>
    //   {Название работы}
    //   <div style="font-style: italic; font-size: 80%;">  ← статус (опц.)
    //       Статус:
    //       <span style="color: green/red;">…</span>
    //       (<i>{ФИО препода}</i>)
    //   </div>
    //   <div …>Комментарий: {текст} (<i>{ФИО}</i>)</div>  ← опц.
    final infoTd = tds[1];
    final headerSpan = infoTd.querySelector('span');
    final headerText = headerSpan != null ? _textOneLine(headerSpan) : '';
    final (discipline, semester, workNumber) = _parseHeader(headerText);

    final title = _afterBreakText(infoTd);

    // div'ы внутри ячейки: первый — статус, второй (если есть) — комментарий.
    final inlineDivs = infoTd.querySelectorAll('div');
    String teacher = '';
    String? comment;
    ReportWorkStatus status = ReportWorkStatus.pending;

    for (final div in inlineDivs) {
      final raw = _textOneLine(div);
      if (raw.startsWith('Статус')) {
        status = _statusFromDiv(div);
        teacher = _lastItalic(div);
      } else if (raw.startsWith('Комментарий')) {
        comment = _commentBody(div);
        if (teacher.isEmpty) teacher = _lastItalic(div);
      }
    }

    result.add(ReportWork(
      fileId: fileId,
      fnpp: fnpp,
      date: date,
      discipline: discipline,
      semester: semester,
      workNumber: workNumber,
      title: title,
      status: status,
      teacher: teacher,
      comment: comment,
    ));
  }
  return result;
}

// ───────────────────────── helpers ─────────────────────────

bool _hasInlineCall(Element scope, String fn) {
  // Кнопка-onclick может стоять на любом td в строке.
  for (final el in [scope, ...scope.querySelectorAll('[onclick]')]) {
    final on = el.attributes['onclick'] ?? '';
    if (on.contains('$fn(')) return true;
  }
  return false;
}

String? _extractCallId(Element scope, String fn) {
  final args = _extractCallArgs(scope, fn, count: 1);
  return args.isEmpty ? null : args.first;
}

/// Извлекает первые [count] позиционных аргументов из onclick'а вида
/// `fn('a', 'b', ...)` (одинарные или двойные кавычки). Возвращает пустой
/// список, если вызов не найден. Если аргументов меньше [count] — возвращает
/// сколько нашлось.
List<String> _extractCallArgs(Element scope, String fn, {int count = 1}) {
  final argRe = RegExp(r"""\s*(?:'([^']*)'|"([^"]*)")\s*""");
  final callRe = RegExp('$fn\\(([^)]*)\\)');
  for (final el in [scope, ...scope.querySelectorAll('[onclick]')]) {
    final on = el.attributes['onclick'] ?? '';
    final call = callRe.firstMatch(on);
    if (call == null) continue;
    final body = call.group(1) ?? '';
    final parts = body.split(',');
    final out = <String>[];
    for (final p in parts.take(count)) {
      final am = argRe.firstMatch(p);
      out.add(am == null ? p.trim() : (am.group(1) ?? am.group(2) ?? ''));
    }
    return out;
  }
  return const [];
}

/// `id="trXXXX"` → `XXXX` (используется в курсовых, где hexnrec кладут в id строки).
String? _stripTrPrefix(String? id) {
  if (id == null || !id.startsWith('tr')) return null;
  final v = id.substring(2);
  return v.isEmpty ? null : v;
}

/// «Программное и техническое обеспечение цифровых систем и технологий
///  (1 сем.) № 2514745» →
/// discipline = «Программное и техническое обеспечение цифровых систем и технологий»,
/// semester = 1, workNumber = «2514745».
(String discipline, int? semester, String workNumber) _parseHeader(String raw) {
  if (raw.isEmpty) return ('', null, '');
  // Семестр.
  int? sem;
  final semMatch = RegExp(r'\((\d+)\s*сем\.?\)').firstMatch(raw);
  if (semMatch != null) sem = int.tryParse(semMatch.group(1)!);

  // Номер работы.
  String number = '';
  final numMatch = RegExp(r'№\s*(\d+)').firstMatch(raw);
  if (numMatch != null) number = numMatch.group(1)!;

  // Дисциплина — то, что до первой открывающей скобки.
  String discipline = raw;
  final parenIdx = raw.indexOf('(');
  if (parenIdx > 0) discipline = raw.substring(0, parenIdx);
  return (discipline.trim(), sem, number);
}

ReportWorkStatus _statusFromDiv(Element div) {
  for (final span in div.querySelectorAll('span')) {
    final style = (span.attributes['style'] ?? '').toLowerCase();
    if (style.contains('color: green') || style.contains('color:green')) {
      return ReportWorkStatus.accepted;
    }
    if (style.contains('color: red') || style.contains('color:red')) {
      return ReportWorkStatus.rejected;
    }
  }
  return ReportWorkStatus.pending;
}

String _lastItalic(Element scope) {
  Element? last;
  for (final el in scope.querySelectorAll('i')) {
    last = el;
  }
  return last == null ? '' : _textOneLine(last);
}

/// Тело комментария: «Комментарий: <текст> (<i>ФИО</i>)» → <текст>.
String _commentBody(Element div) {
  final full = _textMultiline(div);
  // Отрезаем хвост `(ФИО)`.
  final fioStart = full.lastIndexOf('(');
  String body = fioStart > 0 ? full.substring(0, fioStart) : full;
  // Отрезаем префикс «Комментарий:».
  body = body.replaceFirst(RegExp(r'^Комментарий\s*:\s*'), '');
  return body.trim();
}

DateTime? _parseDdMmYyyy(String raw) {
  final m =
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(raw);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(3)!),
    int.parse(m.group(2)!),
    int.parse(m.group(1)!),
  );
}

/// Активный учебный год: в HTML у активной вкладки `<div id="laYYYY" class="ytd aytd">`.
int? detectActiveYear(Document doc) {
  for (final el in doc.querySelectorAll('div.ytd.aytd')) {
    final id = el.id;
    final m = RegExp(r'la(\d{4})').firstMatch(id);
    if (m != null) {
      final y = int.tryParse(m.group(1)!);
      if (y != null) return y;
    }
  }
  return null;
}

Element? _nextSibling(Element el) {
  final parent = el.parent;
  if (parent == null) return null;
  final idx = parent.children.indexOf(el);
  if (idx < 0 || idx >= parent.children.length - 1) return null;
  return parent.children[idx + 1];
}

/// Текст, идущий после первого `<br>` внутри элемента.
/// До первого `<br>` обычно стоит заголовок-`<span>` или «лейбл», нам нужно тело.
String _afterBreakText(Element el) {
  final inner = el.innerHtml;
  final brIdx = inner.indexOf(RegExp(r'<br\s*/?>'));
  if (brIdx < 0) return _textOneLine(el);
  // Берём всё после первого <br>, но обрезаем первый встретившийся <div>
  // (это, например, статус-блок или комментарий — они не часть названия).
  String tail = inner.substring(brIdx);
  tail = tail.replaceFirst(RegExp(r'^<br\s*/?>'), '');
  final divIdx = tail.indexOf('<div');
  if (divIdx >= 0) tail = tail.substring(0, divIdx);
  final fragment = html_parser.parseFragment(tail);
  return _normalize(fragment.text ?? '');
}

String _textOneLine(Element el) {
  final inner = el.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), ' ');
  final tmp = html_parser.parseFragment(inner);
  return _normalize(tmp.text ?? '');
}

String _textMultiline(Element el) {
  final inner = el.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), '\n');
  final tmp = html_parser.parseFragment(inner);
  final raw = tmp.text ?? '';
  return raw
      .split('\n')
      .map((s) => s.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((s) => s.isNotEmpty)
      .join('\n');
}

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
