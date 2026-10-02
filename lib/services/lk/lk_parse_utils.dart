import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Мелочи, общие для всех парсеров ЛК. Раньше эти три функции жили копиями
/// в каждом из `lk_*_parser.dart` и успевали разойтись между собой.
///
/// Многострочный разбор (`<br>` → перевод строки) сюда НЕ переехал: в списке
/// заданий пустые строки схлопываются, а в отчётных работах выбрасываются
/// целиком — это разное поведение, а не дубль.

/// Схлопывает любые пробелы в один и обрезает края.
String normalizeSpaces(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Текст элемента в одну строку.
///
/// `dom.text` не вставляет пробел вокруг `<br>`, поэтому соседние слова
/// слипаются — сначала меняем `<br>` на пробел, потом разбираем фрагмент.
String textOneLine(Element el) {
  final inner = el.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), ' ');
  return normalizeSpaces(html_parser.parseFragment(inner).text ?? '');
}

/// Дата со страниц ЛК: основной формат «2026-04-17 15:28:44»,
/// запасной — «17.04.2026 15:28» (время необязательно).
DateTime? parseSiteDate(String raw) {
  if (raw.isEmpty) return null;

  var m =
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?')
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
