import 'package:campus2_0/models/report_work.dart';
import 'package:campus2_0/services/lk/lk_report_work_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

/// Разметка повторяет структуру таблицы «Прочие работы» на vkr2.php:
/// дата в первом td, во втором — курсивная шапка «Дисциплина (N сем.) № id»,
/// затем `<br>`, название и опциональные div'ы статуса и комментария.
const _otherWorksHtml = '''
<table>
  <tr class="altr" onclick="getotherpage('2554999','12')">
    <td>17.04.2026</td>
    <td>
      <span style="font-style: italic; font-size: 80%;">Физика (3 сем.) № 2514745</span>
      <br>
      Лабораторная работа №3
      <div style="font-style: italic;">Статус: <span style="color: green;">Принята</span> (<i>Иванов И. И.</i>)</div>
    </td>
  </tr>
  <tr class="altr" onclick="getotherpage('2555000','13')">
    <td>2026-04-18 09:15:00</td>
    <td>
      <span style="font-style: italic; font-size: 80%;">Высшая математика (2 сем.) № 2514746</span>
      <br>
      Расчётная работа
      <div style="font-style: italic;">Статус: <span style="color: red;">Отклонена</span> (<i>Петрова А. С.</i>)</div>
      <div style="font-style: italic;">Комментарий: Переделать второй пункт (<i>Петрова А. С.</i>)</div>
    </td>
  </tr>
  <tr class="altr" onclick="getotherpage('2555001','14')">
    <td>19.04.2026</td>
    <td>
      <span style="font-style: italic; font-size: 80%;">Информатика (1 сем.) № 2514747</span>
      <br>
      Реферат
    </td>
  </tr>
</table>''';

void main() {
  test('parseOtherWorks разбирает дату, шапку, название и статус', () {
    final works = parseOtherWorks(html_parser.parse(_otherWorksHtml));
    expect(works, hasLength(3));

    final first = works[0];
    expect(first.fileId, '2554999');
    expect(first.fnpp, '12');
    expect(first.date, DateTime(2026, 4, 17));
    expect(first.discipline, 'Физика');
    expect(first.semester, 3);
    expect(first.workNumber, '2514745');
    expect(first.title, 'Лабораторная работа №3');
    expect(first.status, ReportWorkStatus.accepted);
    expect(first.teacher, 'Иванов И. И.');
    expect(first.comment, isNull);
  });

  test('parseOtherWorks: отклонённая работа с комментарием', () {
    final works = parseOtherWorks(html_parser.parse(_otherWorksHtml));
    final second = works[1];
    expect(second.date, DateTime(2026, 4, 18, 9, 15));
    expect(second.status, ReportWorkStatus.rejected);
    expect(second.comment, 'Переделать второй пункт');
    expect(second.teacher, 'Петрова А. С.');
  });

  test('parseOtherWorks: без блока статуса работа считается на проверке', () {
    final works = parseOtherWorks(html_parser.parse(_otherWorksHtml));
    final third = works[2];
    expect(third.status, ReportWorkStatus.pending);
    expect(third.teacher, '');
    expect(third.title, 'Реферат');
  });

  test('parseOtherWorks: таблица без нужных строк — пустой список', () {
    final doc = html_parser.parse(
        '<table><tr class="altr"><td>17.04.2026</td><td>Без onclick</td></tr></table>');
    expect(parseOtherWorks(doc), isEmpty);
  });
}
