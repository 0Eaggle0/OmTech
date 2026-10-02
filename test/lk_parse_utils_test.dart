import 'package:campus2_0/services/lk/lk_parse_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  group('textOneLine', () {
    test('<br> не склеивает соседние слова', () {
      final el = html_parser
          .parse('<table><tr><td>Первая<br>вторая</td></tr></table>')
          .querySelector('td')!;
      expect(textOneLine(el), 'Первая вторая');
    });

    test('переводы строк, табы и &nbsp; схлопываются в один пробел', () {
      final el = html_parser
          .parse('<div>  Основы\n\t российской&nbsp;&nbsp;государственности '
              '</div>')
          .querySelector('div')!;
      expect(textOneLine(el), 'Основы российской государственности');
    });

    test('вложенные теги не теряются', () {
      final el = html_parser
          .parse('<table><tr><td><span>Физика</span> <i>(лаб.)</i>'
              '</td></tr></table>')
          .querySelector('td')!;
      expect(textOneLine(el), 'Физика (лаб.)');
    });
  });

  group('parseSiteDate', () {
    test('основной формат сайта с секундами', () {
      expect(parseSiteDate('2026-04-17 15:28:44'),
          DateTime(2026, 4, 17, 15, 28, 44));
    });

    test('основной формат без секунд', () {
      expect(parseSiteDate('2026-04-17 15:28'), DateTime(2026, 4, 17, 15, 28));
    });

    test('запасной формат с временем и без', () {
      expect(parseSiteDate('17.04.2026 15:28'), DateTime(2026, 4, 17, 15, 28));
      expect(parseSiteDate('17.04.2026'), DateTime(2026, 4, 17));
      expect(parseSiteDate('7.4.2026'), DateTime(2026, 4, 7));
    });

    test('дата внутри текста находится', () {
      expect(parseSiteDate('Сдано 17.04.2026, проверено'),
          DateTime(2026, 4, 17));
    });

    test('пустая строка и мусор дают null', () {
      expect(parseSiteDate(''), isNull);
      expect(parseSiteDate('не указана'), isNull);
    });
  });

  test('normalizeSpaces', () {
    expect(normalizeSpaces('  a \n b\t\tc  '), 'a b c');
    expect(normalizeSpaces('   '), '');
  });
}
