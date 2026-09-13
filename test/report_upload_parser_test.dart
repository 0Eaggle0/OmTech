import 'package:campus2_0/services/lk/lk_report_work_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  test('parseUploadDisciplines разбирает seldisc и пропускает дубли', () {
    const html = '''
<div id="disbox" data-dis="" onclick="showdisccont();">Дисциплина: <span id="disccont"></span></div>
<div id="disclistcont">
  <div class="discline" onclick="seldisc('8000000A1B2C', 'Основы российской государственности', 'ИСТ-241', '1');">Основы российской государственности (гр. ИСТ-241, сем. 1)</div>
  <div class="discline" onclick="seldisc('8000000A1B2D','Иностранный язык, часть 2','ИСТ-241','2')">Иностранный язык, часть 2 (гр. ИСТ-241, сем. 2)</div>
  <div class="discline" onclick="seldisc('8000000A1B2C','Дубль','ИСТ-241','1')">Дубль</div>
  <div class="discline" onclick="seldisc('8000000A1B2E','','ИСТ-241','3')">Физика (гр. ИСТ-241, сем. 3)</div>
</div>''';
    final list = parseUploadDisciplines(html_parser.parse(html));
    expect(list.map((d) => d.hexnrec),
        ['8000000A1B2C', '8000000A1B2D', '8000000A1B2E']);
    expect(list[0].name, 'Основы российской государственности');
    expect(list[1].name, 'Иностранный язык, часть 2');
    expect(list[1].group, 'ИСТ-241');
    expect(list[1].semester, '2');
    expect(list[2].name, 'Физика');
  });

  test('parseOtherDeleteId берёт id у кнопки, а не у определения функции', () {
    const withButton = r'''
<script>function otherdel(id) { $.ajax({data: {'del': id}}); }</script>
<div><a href="javascript:void(0)" onclick="otherdel('2554999');">Удалить</a></div>''';
    const withoutButton =
        '<script>function otherdel(id) { if (confirm("?")) {} }</script><div>Принята</div>';
    expect(parseOtherDeleteId(html_parser.parse(withButton)), '2554999');
    expect(parseOtherDeleteId(html_parser.parse(withoutButton)), isNull);
  });

  test('пустой список в форме — пустой результат', () {
    final doc = html_parser.parse(
        '<div id="disclistcont"></div><input class="otherf" name="file" type="file">');
    expect(parseUploadDisciplines(doc), isEmpty);
  });
}
