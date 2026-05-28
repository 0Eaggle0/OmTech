import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/grade.dart';
import '../../models/student_record.dart';

/// Парсит HTML страницы `up.omgtu.ru/index.php?r=student/index` в
/// [StudentRecord]. Чистая функция — не делает сетевых запросов.
StudentRecord parseStudentRecord(String html) {
  final doc = html_parser.parse(html);

  final profile = _parseProfile(doc);
  final semesters = _parseSemesterAccess(doc);
  final sections = _parseSections(doc);

  return StudentRecord(
    profile: profile,
    semesters: semesters,
    sections: sections,
  );
}

StudentProfile _parseProfile(Document doc) {
  // ФИО — обычно крупным заголовком сверху.
  String fullName = _firstNonEmpty([
    doc.querySelector('h1')?.text,
    doc.querySelector('h2')?.text,
  ]);

  String bookNumber = _extractAfterLabel(doc, ['Номер книжки']);
  String specialty = _extractAfterLabel(doc, ['Специальность']);
  String groupLabel = _extractAfterLabel(doc, ['Группа']);
  String studyForm = _extractAfterLabel(doc, ['Форма обучения']);
  String libraryCard = _extractLibraryCard(doc);

  return StudentProfile(
    fullName: _normalize(fullName),
    bookNumber: _normalize(bookNumber),
    specialty: _normalize(specialty),
    groupLabel: _normalize(groupLabel),
    studyForm: _normalize(studyForm),
    libraryCardNumber: _normalize(libraryCard),
  );
}

/// Ищет шаблон `<b>Label:</b> value` и возвращает value.
String _extractAfterLabel(Document doc, List<String> labels) {
  for (final b in doc.querySelectorAll('b, strong')) {
    final t = b.text.trim().replaceAll(':', '');
    if (!labels.any((l) => t.contains(l))) continue;
    // Берём текст у родителя, отрезаем сам лейбл.
    final parent = b.parent;
    if (parent == null) continue;
    final raw = parent.text;
    final idx = raw.indexOf(b.text);
    if (idx < 0) continue;
    final after = raw.substring(idx + b.text.length);
    // Останавливаемся на следующем переводе строки или метке.
    final cut = after.split(RegExp(r'(?:\r?\n|\s{2,})')).first;
    return cut.trim();
  }
  return '';
}

String _extractLibraryCard(Document doc) {
  // Шаблон: "Читательский билет: № 54297 для доступа в ЭБС"
  final text = doc.body?.text ?? '';
  final m = RegExp(r'Читательский билет:\s*№?\s*(\d+)').firstMatch(text);
  return m?.group(1) ?? '';
}

List<SemesterAccess> _parseSemesterAccess(Document doc) {
  final result = <SemesterAccess>[];
  final seen = <int>{};
  // Ищем все элементы, чей текст начинается с "Семестр N".
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

List<Semester> _parseSections(Document doc) {
  final sections = <Semester>[];

  // Ищем все <h3> в основной части страницы и берём ближайшую таблицу после.
  for (final h3 in doc.querySelectorAll('h3')) {
    final title = h3.text.trim().replaceAll(RegExp(r':\s*$'), '');
    if (title.isEmpty) continue;
    final table = _nextTable(h3);
    if (table == null) continue;
    final rows = _parseTable(table, title);
    if (rows.isEmpty) continue;
    sections.add(Semester(title: title, grades: rows));
  }

  return sections;
}

Element? _nextTable(Element start) {
  // Поднимаемся по предкам, ищем таблицу среди следующих сиблингов на каждом
  // уровне. Это устойчиво к тому, что таблица обёрнута в .table-responsive.
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

List<Grade> _parseTable(Element table, String sectionTitle) {
  final rows = <Grade>[];
  final controlType = _controlTypeForSection(sectionTitle);

  for (final tr in table.querySelectorAll('tbody tr')) {
    final cells = tr.children
        .where((c) => c.localName == 'td' || c.localName == 'th')
        .toList();
    if (cells.length < 2) continue;

    // Ожидаемая структура: # | Название | Кол.часов | Рейтинг по КН |
    // Рейтинг | Оценка | Дата сдачи | Преподаватель | В дип
    // Первая ячейка — порядковый номер (<th scope="row">), пропускаем.
    final startIdx = cells.first.localName == 'th' ? 1 : 0;
    final data = cells.sublist(startIdx);
    if (data.isEmpty) continue;

    String at(int i) => i < data.length ? _normalize(data[i].text) : '';

    final discipline = at(0);
    if (discipline.isEmpty) continue;

    final hours = int.tryParse(at(1));
    final rankByCK = int.tryParse(at(2));
    final rank = int.tryParse(at(3));
    final mark = at(4);
    final date = _parseDate(at(5));
    final teacher = at(6);
    final inDiploma = at(7).toLowerCase().contains('да');

    final status = gradeStatusFromCss(
      data.expand((c) => c.classes).toSet(),
    );

    rows.add(Grade(
      discipline: discipline,
      controlType: controlType,
      mark: mark.isEmpty ? '—' : mark,
      score: rank,
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
  if (t.contains('зач')) return 'Зачёт';
  if (t.contains('курс')) return 'Курсовая';
  if (t.contains('практ')) return 'Практика';
  if (t.contains('вкр') || t.contains('квалиф')) return 'ВКР';
  return title;
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) return null;
  final m = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(raw);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(3)!),
    int.parse(m.group(2)!),
    int.parse(m.group(1)!),
  );
}

String _firstNonEmpty(Iterable<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();
