import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../models/contact_work.dart';

/// Парсер HTML страниц раздела «Контактная работа» ЛК ОмГТУ.
///
/// Чистый разбор — без сети.
/// Структура страниц важна: и список дисциплин, и список заданий —
/// одна и та же `<table id="List">`, заголовки лежат в первой `<tr>`
/// внутри `<tbody>` (без отдельного `<thead>`).

/// Главная страница `r=remote/read`.
/// Колонки таблицы (по индексам):
///   0 — Дисциплина
///   1 — Преподаватели (через запятую)
///   2 — Количество заданий (целое)
///   3 — Кнопка-лупа: <a href="...&discipline=ID...">
List<WorkDiscipline> parseDisciplines(String html) {
  final doc = html_parser.parse(html);
  final table = _pickTable(doc, expectedHeader: 'дисциплин');
  if (table == null) return const [];

  final result = <WorkDiscipline>[];
  final rows = _dataRows(table);

  for (final tr in rows) {
    final tds = _tds(tr);
    if (tds.length < 4) continue;

    final discipline = _textOneLine(tds[0]);
    if (discipline.isEmpty) continue;

    final teachers = _splitTeachers(_textOneLine(tds[1]));
    final taskCount = int.tryParse(_textOneLine(tds[2])) ?? 0;

    final id = _disciplineIdIn(tds[3]) ?? _disciplineIdIn(tr);
    if (id == null) continue;

    result.add(WorkDiscipline(
      id: id,
      discipline: discipline,
      teachers: teachers,
      items: const [],
      taskCountHint: taskCount,
    ));
  }

  return result;
}

/// Страница `r=remote/read/taskList&discipline=...`.
/// Колонки:
///   0 — Номер
///   1 — Комментарий (внутри `<div class="form-control force-select-all">`)
///   2 — Файлы — несколько `<a href=".../downloadFile&id=...&name=..."><h4>имя.pdf</h4></a>`
///   3 — Дата создания: «YYYY-MM-DD HH:MM:SS»
///   4 — Преподаватель
List<ContactWorkItem> parseTasks(String html) {
  final doc = html_parser.parse(html);
  final table = _pickTable(doc, expectedHeader: 'комментар');
  if (table == null) return const [];

  final result = <ContactWorkItem>[];
  final rows = _dataRows(table);

  for (final tr in rows) {
    final tds = _tds(tr);
    if (tds.length < 5) continue;

    final number =
        int.tryParse(_textOneLine(tds[0])) ?? (result.length + 1);

    // Комментарий: предпочтительно из <div class="force-select-all">,
    // т.к. там лежит сам текст; иначе — всё содержимое ячейки.
    final commentEl = tds[1].querySelector('.force-select-all') ?? tds[1];
    final comment = _textMultiline(commentEl);

    final files = _parseFiles(tds[2]);
    final createdAt = _parseDate(_textOneLine(tds[3]));
    final teacher = _textOneLine(tds[4]);

    // Совсем пустые строки пропускаем.
    if (comment.isEmpty && files.isEmpty && teacher.isEmpty) continue;

    result.add(ContactWorkItem(
      number: number,
      comment: comment,
      files: files,
      createdAt: createdAt,
      teacher: teacher,
    ));
  }

  return result;
}

// ────────────────────────────── helpers ──────────────────────────────

/// Берём таблицу, у которой в первой строке (`<tr>`) есть `<th>` с нужным
/// заголовком. На сайте таких таблиц может быть две одинаковых
/// (вкладки «Текущий семестр» / «Прошлые»), и первая — нужная.
Element? _pickTable(Document doc, {required String expectedHeader}) {
  for (final t in doc.querySelectorAll('table')) {
    final headerRow = t.querySelector('tbody > tr') ?? t.querySelector('tr');
    if (headerRow == null) continue;
    final ths = headerRow.querySelectorAll('th');
    final found = ths.any(
        (th) => _textOneLine(th).toLowerCase().contains(expectedHeader));
    if (found && _dataRows(t).isNotEmpty) return t;
  }
  // Фолбэк: явно table#List.
  return doc.querySelector('table#List');
}

/// Все строки таблицы кроме первой (которая с `<th>`).
List<Element> _dataRows(Element table) {
  final all = table.querySelectorAll('tbody > tr');
  final rows = all.isNotEmpty
      ? all
      : table.querySelectorAll('tr'); // на случай если tbody нет
  if (rows.isEmpty) return const [];
  final result = <Element>[];
  for (final tr in rows) {
    // Пропускаем строку, в которой только <th> (это заголовки).
    final tds = tr.children.where((c) => c.localName == 'td').toList();
    if (tds.isEmpty) continue;
    result.add(tr);
  }
  return result;
}

List<Element> _tds(Element tr) =>
    tr.children.where((c) => c.localName == 'td').toList();

/// Текст в одну строку: схлопывает любые пробелы (включая переводы строк
/// и `&nbsp;`) в один пробел и обрезает пробельные края. Также корректно
/// «склеивает» содержимое, разорванное тегами `<br>`.
String _textOneLine(Element el) {
  // dom.text не вставляет пробел вокруг <br>, поэтому соседние слова
  // могут слипнуться: добавляем пробел перед текстом каждого <br>.
  final inner = el.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), ' ');
  final tmp = html_parser.parseFragment(inner);
  return tmp.text!.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Многострочный текст: `<br>` → перевод строки, лишние пробелы в каждой
/// строке схлопываются.
String _textMultiline(Element el) {
  final inner = el.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), '\n');
  final tmp = html_parser.parseFragment(inner);
  final raw = tmp.text ?? '';
  final lines = raw
      .split('\n')
      .map((s) => s.replaceAll(RegExp(r'[ \t]+'), ' ').trim());
  // Подряд идущие пустые строки схлопываем в одну.
  final out = <String>[];
  for (final line in lines) {
    if (line.isEmpty && out.isNotEmpty && out.last.isEmpty) continue;
    out.add(line);
  }
  while (out.isNotEmpty && out.first.isEmpty) {
    out.removeAt(0);
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return out.join('\n');
}

List<String> _splitTeachers(String raw) {
  return raw
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String? _disciplineIdIn(Element scope) {
  for (final a in scope.querySelectorAll('a[href]')) {
    final id = _extractIdFromUrl(a.attributes['href'] ?? '');
    if (id != null) return id;
  }
  return null;
}

String? _extractIdFromUrl(String href) {
  if (href.isEmpty) return null;
  final m = RegExp(r'discipline=([^&"\s]+)').firstMatch(href);
  if (m == null) return null;
  return Uri.decodeQueryComponent(m.group(1)!);
}

List<WorkFile> _parseFiles(Element scope) {
  final files = <WorkFile>[];
  // Уникальность — по паре (url, name): один и тот же id может
  // повторяться у нескольких файлов разных name (как у ЛР1..ЛР6 в задании №4),
  // поэтому ключ — связка.
  final seen = <String>{};
  for (final a in scope.querySelectorAll('a[href]')) {
    final href = a.attributes['href'] ?? '';
    if (!href.contains('downloadFile')) continue;
    final url = href.startsWith('http')
        ? href
        : (href.startsWith('/')
            ? 'https://up.omgtu.ru$href'
            : 'https://up.omgtu.ru/$href');

    final h4 = _textOneLine(a.querySelector('h4') ?? a);
    final tooltip =
        a.querySelector('span[data-original-title]')?.attributes['data-original-title'];
    final name = h4.isNotEmpty
        ? h4
        : (tooltip?.trim().isNotEmpty == true
            ? tooltip!.trim()
            : _fileNameFromUrl(url) ?? 'file');

    final key = '$url|$name';
    if (!seen.add(key)) continue;

    final ext = _extension(name);
    files.add(WorkFile(name: name, url: url, type: _typeFromExt(ext)));
  }
  return files;
}

String? _fileNameFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final raw = uri.queryParameters['name'];
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
  } catch (_) {
    // ignore
  }
  return null;
}

String _extension(String name) {
  final i = name.lastIndexOf('.');
  if (i < 0 || i >= name.length - 1) return '';
  return name.substring(i + 1).toLowerCase();
}

String _typeFromExt(String ext) {
  const known = {
    'pdf',
    'docx',
    'doc',
    'pptx',
    'ppt',
    'xlsx',
    'xls',
    'jpg',
    'jpeg',
    'png',
    'zip',
    'rar',
  };
  if (known.contains(ext)) return ext;
  return 'link';
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) return null;
  // Формат сайта: «2026-04-17 15:28:44».
  var m = RegExp(
          r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?')
      .firstMatch(raw);
  if (m != null) {
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      m.group(6) != null ? int.parse(m.group(6)!) : 0,
    );
  }
  // Запасной формат: «17.04.2026 15:28».
  m = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})(?:\s+(\d{1,2}):(\d{2}))?')
      .firstMatch(raw);
  if (m != null) {
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
      m.group(4) != null ? int.parse(m.group(4)!) : 0,
      m.group(5) != null ? int.parse(m.group(5)!) : 0,
    );
  }
  return null;
}
