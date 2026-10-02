import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/grade.dart';
import '../../models/student_record.dart';
import 'lk_parse_utils.dart';

/// Парсит HTML страницы `up.omgtu.ru/index.php?r=student/index` в
/// [StudentRecord]. Чистая функция — не делает сетевых запросов.
StudentRecord parseStudentRecord(String html) {
  final doc = html_parser.parse(html);

  final profile = _parseProfile(doc);
  final accessList = _parseSemesterAccess(doc);
  final panels = _parsePanels(doc);

  // Достраиваем «пустые» семестры по правой колонке допусков, чтобы
  // в UI всегда были видны все доступные семестры, даже без оценок.
  final byNumber = {for (final p in panels) p.number: p};
  for (final a in accessList) {
    byNumber.putIfAbsent(
      a.number,
      () => SemesterPanel(number: a.number),
    );
  }
  final allPanels = byNumber.values.toList()
    ..sort((a, b) => a.number.compareTo(b.number));

  return StudentRecord(
    profile: profile,
    semesters: accessList,
    panels: allPanels,
  );
}

// ───────────────────────────── PROFILE ──────────────────────────────

StudentProfile _parseProfile(Document doc) {
  final fullName = _firstNonEmpty([
    doc.querySelector('.jumbotron h1')?.text,
    doc.querySelector('h1')?.text,
    doc.querySelector('h2')?.text,
  ]);
  return StudentProfile(
    fullName: normalizeSpaces(fullName),
    bookNumber: normalizeSpaces(_extractAfterLabel(doc, ['Номер книжки'])),
    specialty: normalizeSpaces(_extractAfterLabel(doc, ['Специальность'])),
    groupLabel: normalizeSpaces(_extractAfterLabel(doc, ['Группа'])),
    studyForm: normalizeSpaces(_extractAfterLabel(doc, ['Форма обучения'])),
    libraryCardNumber: normalizeSpaces(_extractLibraryCard(doc)),
  );
}

String _extractAfterLabel(Document doc, List<String> labels) {
  for (final b in doc.querySelectorAll('b, strong')) {
    final t = b.text.trim().replaceAll(':', '');
    if (!labels.any((l) => t.contains(l))) continue;
    final parent = b.parent;
    if (parent == null) continue;
    // Берём текст у родителя, отрезаем сам лейбл и всё до него,
    // а потом останавливаемся на следующем переводе строки/<br>.
    final raw = parent.text;
    final idx = raw.indexOf(b.text);
    if (idx < 0) continue;
    final after = raw.substring(idx + b.text.length);
    final cut = after.split(RegExp(r'(?:\r?\n|\s{2,})')).first;
    return cut.trim();
  }
  return '';
}

String _extractLibraryCard(Document doc) {
  final text = doc.body?.text ?? '';
  final m = RegExp(r'Читательский билет:\s*№?\s*(\d+)').firstMatch(text);
  return m?.group(1) ?? '';
}

// ──────────────────────── SEMESTER ACCESS (right) ────────────────────

List<SemesterAccess> _parseSemesterAccess(Document doc) {
  final result = <SemesterAccess>[];
  final seen = <int>{};
  for (final el in doc.querySelectorAll('a, li, div, span')) {
    final raw = el.text.trim();
    final m = RegExp(r'^Семестр\s+(\d+)\s*\(([^)]+)\)').firstMatch(raw);
    if (m == null) continue;
    final n = int.tryParse(m.group(1)!);
    if (n == null || !seen.add(n)) continue;
    final marker = m.group(2)!.toLowerCase();
    final hasAccess = marker.contains('допуск есть') ||
        (marker.contains('есть') && !marker.contains('нет'));
    result.add(SemesterAccess(number: n, hasAccess: hasAccess));
  }
  result.sort((a, b) => a.number.compareTo(b.number));
  return result;
}

// ───────────────────── SEMESTER PANELS (.tab-pane) ───────────────────

List<SemesterPanel> _parsePanels(Document doc) {
  final panels = <SemesterPanel>[];
  // На сайте id="semestr1", "semestr2" и т.д. (русский транслит, без 'e').
  final regex = RegExp(r'^semestr(\d+)$', caseSensitive: false);
  for (final el in doc.querySelectorAll('div.tab-pane[id]')) {
    final id = el.attributes['id'] ?? '';
    final m = regex.firstMatch(id);
    if (m == null) continue;
    final number = int.tryParse(m.group(1)!);
    if (number == null) continue;
    final sections = _parseSections(el);
    panels.add(SemesterPanel(
      number: number,
      isActive: el.classes.contains('active'),
      sections: sections,
    ));
  }
  panels.sort((a, b) => a.number.compareTo(b.number));
  return panels;
}

List<Semester> _parseSections(Element panel) {
  final result = <Semester>[];
  for (final h3 in panel.querySelectorAll('h3')) {
    final title = h3.text.trim().replaceAll(RegExp(r':\s*$'), '');
    if (title.isEmpty) continue;
    final table = _nextTable(h3);
    if (table == null) continue;
    final rows = _parseTable(table, title);
    result.add(Semester(title: title, grades: rows));
  }
  return result;
}

Element? _nextTable(Element start) {
  Element? cur = start;
  while (cur != null) {
    final parent = cur.parent;
    if (parent == null) break;
    final children = parent.children;
    final idx = children.indexOf(cur);
    for (var i = idx + 1; i < children.length; i++) {
      final el = children[i];
      if (el.localName == 'table') return el;
      final inner = el.querySelector('table');
      if (inner != null) return inner;
    }
    if (parent.localName == 'body') break;
    cur = parent;
  }
  return null;
}

// ───────────────────────── TABLE PARSING ─────────────────────────────

/// Парсим таблицу по заголовкам колонок, а не по фиксированным индексам,
/// потому что у "Курсовые работы" появляется колонка "Тип работ" вместо
/// "Рейтинг по КН" — индексы съезжают.
List<Grade> _parseTable(Element table, String sectionTitle) {
  final headers = table
      .querySelectorAll('thead th')
      .map((th) => normalizeSpaces(th.text).toLowerCase())
      .toList();
  if (headers.isEmpty) return const [];

  int? colOf(List<String> needles) {
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (needles.any((n) => h.contains(n))) return i;
    }
    return null;
  }

  final iName = colOf(['название']);
  final iHours = colOf(['кол. час', 'часов']);
  final iRank = colOf(['рейтинг', 'балл']);
  // Берём первое вхождение «рейтинг», а второе (если оно отдельное) — score.
  // Чаще на сайте две колонки: «Рейтинг по КН» и «Рейтинг».
  int? iRankCK = colOf(['рейтинг по кн']);
  int? iScore;
  if (iRankCK != null) {
    // Ищем «рейтинг» после iRankCK как итоговый балл.
    for (var i = iRankCK + 1; i < headers.length; i++) {
      if (headers[i].contains('рейтинг')) {
        iScore = i;
        break;
      }
    }
  } else {
    iScore = iRank;
  }
  final iMark = colOf(['оценка']);
  final iDate = colOf(['дата']);
  final iTeacher = colOf(['преподават']);
  final iDiploma = colOf(['в дип']);

  final controlType = _controlTypeForSection(sectionTitle);
  final rows = <Grade>[];

  for (final tr in table.querySelectorAll('tbody tr')) {
    final cells = tr.children
        .where((c) => c.localName == 'td' || c.localName == 'th')
        .toList();
    if (cells.length < headers.length - 1) continue;

    String cell(int? i) =>
        (i == null || i >= cells.length) ? '' : normalizeSpaces(cells[i].text);

    final discipline = cell(iName);
    if (discipline.isEmpty) continue;

    final hours = int.tryParse(cell(iHours));
    final rankByCK = iRankCK == null ? null : int.tryParse(cell(iRankCK));
    final score = int.tryParse(cell(iScore));
    final mark = cell(iMark);
    final date = parseSiteDate(cell(iDate));
    final teacher = cell(iTeacher);
    final inDiploma = cell(iDiploma).toLowerCase().contains('да');

    final status = gradeStatusFromCss(
      cells.expand((c) => c.classes).toSet(),
    );

    rows.add(Grade(
      discipline: discipline,
      controlType: controlType,
      mark: mark.isEmpty ? '—' : mark,
      score: score,
      hours: hours,
      rankByCK: rankByCK,
      date: date,
      teacher: teacher.isEmpty ? null : teacher,
      inDiploma: inDiploma,
      status: status,
    ));
  }

  return rows;
}

String _controlTypeForSection(String title) {
  final t = title.toLowerCase();
  if (t.contains('экзам')) return 'Экзамен';
  if (t.contains('дифференц')) return 'Дифф. зачёт';
  if (t.contains('зач')) return 'Зачёт';
  if (t.contains('курс')) return 'Курсовая';
  if (t.contains('практ')) return 'Практика';
  if (t.contains('вкр') || t.contains('квалиф')) return 'ВКР';
  return title;
}


String _firstNonEmpty(Iterable<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

